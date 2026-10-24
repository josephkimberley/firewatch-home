import contextlib
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import struct
import subprocess
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('install_app', ROOT/'tools/install_app.py')
installer = importlib.util.module_from_spec(spec); spec.loader.exec_module(installer)

from package_ipk import package, ar, tar_gz
from verify_ipk import ar_members, verify_blob

def candidate(directory):
    root=Path(directory);stage=root/'stage';stage.mkdir()
    app={'id':installer.APP_ID,'version':'3.1.0','type':'native','main':'minimal-home','icon':'icon.png','largeIcon':'large-icon.png'}
    (stage/'appinfo.json').write_text(json.dumps(app))
    for name in ['main.qml','icon.png','large-icon.png']:(stage/name).write_bytes(b'fixture')
    data=bytearray(84);data[:7]=b'\x7fELF\x01\x01\x01';struct.pack_into('<H',data,18,40)
    struct.pack_into('<I',data,28,52);struct.pack_into('<HH',data,42,32,1);struct.pack_into('<I',data,52,1)
    (stage/'minimal-home').write_bytes(data)
    p=root/'candidate.ipk';package(stage,p)
    return p,p.with_suffix('.ipk.sha256')

class InstallerTests(unittest.TestCase):
    def test_target_rejects_shell_options_and_usernames(self):
        for name in ['-oProxyCommand=x','root@tv','tv;reboot','$(id)','tv\nwhoami','[::1]']:
            with self.assertRaises(ValueError): installer.validate_target(name)
        self.assertEqual(installer.validate_target('lg-tv.local'),'lg-tv.local')

    def test_mock_has_no_network_side_effect(self):
        with patch.object(installer.subprocess,'run',side_effect=AssertionError('network')), contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(installer.main(['--mock',str(ROOT/'tests/fixtures/tv-runtime-supported.txt')]),0)
            self.assertEqual(installer.main(['--mock',str(ROOT/'tests/fixtures/tv-runtime-unsupported.txt')]),1)

    def test_missing_runtime_never_passes_preflight(self):
        fixture=(ROOT/'tests/fixtures/tv-runtime-supported.txt').read_text()
        self.assertEqual(installer.compatibility(fixture),[])
        for value in ['uid=0','arch=armv7l','present=/usr/bin/qml-runner','present=/usr/bin/luna-send','homebrew=yes']:
            self.assertTrue(installer.compatibility(fixture.replace(value,'')))

    def test_package_checksum_and_dry_run(self):
        with tempfile.TemporaryDirectory() as d:
            p,checksum=candidate(d)
            with patch.object(installer.subprocess,'run',side_effect=AssertionError('network')), contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(installer.main(['--tv','tv.local','--package',str(p),'--checksum',str(checksum)]),0)
            p.write_bytes(p.read_bytes()+b'corrupt')
            with self.assertRaises(ValueError):installer.verify_package(p,checksum)

    def test_existing_app_refused_before_upload(self):
        with tempfile.TemporaryDirectory() as d:
            p,checksum=candidate(d)
            responses=[(ROOT/'tests/fixtures/tv-runtime-supported.txt').read_text(),json.dumps({'returnValue':True,'exist':True})]
            with patch.object(installer,'run',side_effect=responses),patch.object(installer.subprocess,'run',side_effect=AssertionError('upload')),contextlib.redirect_stdout(io.StringIO()):
                with self.assertRaisesRegex(RuntimeError,'already exists'):
                    installer.main(['--tv','tv.local','--package',str(p),'--checksum',str(checksum),'--apply'])

    def test_unknown_app_status_never_becomes_absence(self):
        for status in [{'returnValue':False,'errorCode':-1,'errorText':'app not found'}, {'returnValue':True}, {'returnValue':True,'exist':0}, {'returnValue':True,'exist':'false'}]:
            with tempfile.TemporaryDirectory() as d:
                p,checksum=candidate(d)
                responses=[(ROOT/'tests/fixtures/tv-runtime-supported.txt').read_text(),json.dumps(status)]
                with patch.object(installer,'run',side_effect=responses),patch.object(installer.subprocess,'run',side_effect=AssertionError('upload')),contextlib.redirect_stdout(io.StringIO()):
                    with self.assertRaisesRegex(RuntimeError,'unknown state'):
                        installer.main(['--tv','tv.local','--package',str(p),'--checksum',str(checksum),'--apply'])

    def test_rejects_other_package_and_install_hooks(self):
        with tempfile.TemporaryDirectory() as d:
            p,checksum=candidate(d)
            archive=ar_members(p.read_bytes())
            archive['control.tar.gz']=tar_gz([('control',b'Package: another.app\nVersion: 1.0.0\nArchitecture: arm\n',0o644)])
            with self.assertRaisesRegex(ValueError,'identity'):verify_blob(ar(list(archive.items())))
            archive['control.tar.gz']=tar_gz([('control',b'Package: '+installer.APP_ID.encode()+b'\nVersion: 3.1.0\nArchitecture: arm\n',0o644),('postinst',b'reboot',0o755)])
            with self.assertRaisesRegex(ValueError,'hooks'):verify_blob(ar(list(archive.items())))

    def test_apply_waits_for_registration_and_cleans_isolated_directory(self):
        with tempfile.TemporaryDirectory() as d:
            p,checksum=candidate(d);digest=hashlib.sha256(p.read_bytes()).hexdigest()
            absent=json.dumps({'returnValue':True,'exist':False})
            responses=[(ROOT/'tests/fixtures/tv-runtime-supported.txt').read_text(),absent,'/tmp/firewatch-home.A1B2C3D4',digest+'  candidate.ipk',json.dumps({'returnValue':True}),absent,json.dumps({'returnValue':True,'appInfo':{'id':installer.APP_ID,'version':'3.1.0'}}),'']
            with patch.object(installer,'run',side_effect=responses) as remote,patch.object(installer.subprocess,'run',return_value=subprocess.CompletedProcess([],0,stderr=b'')) as transfer,patch.object(installer.time,'sleep') as wait,contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(installer.main(['--tv','tv.local','--package',str(p),'--checksum',str(checksum),'--apply']),0)
                self.assertIn('cat > /tmp/firewatch-home.A1B2C3D4/candidate.ipk',transfer.call_args.args[0][-1])
                self.assertEqual(wait.call_count,1)
                self.assertIn('rmdir /tmp/firewatch-home.A1B2C3D4',remote.call_args.args[0][-1])

    def test_checksum_mismatch_after_upload_still_cleans(self):
        with tempfile.TemporaryDirectory() as d:
            p,checksum=candidate(d)
            absent=json.dumps({'returnValue':True,'exist':False})
            responses=[(ROOT/'tests/fixtures/tv-runtime-supported.txt').read_text(),absent,'/tmp/firewatch-home.A1B2C3D4','wronghash','']
            with patch.object(installer,'run',side_effect=responses) as remote,patch.object(installer.subprocess,'run',return_value=subprocess.CompletedProcess([],0,stderr=b'')),contextlib.redirect_stdout(io.StringIO()):
                with self.assertRaisesRegex(RuntimeError,'TV-side checksum'):installer.main(['--tv','tv.local','--package',str(p),'--checksum',str(checksum),'--apply'])
                self.assertIn('rmdir /tmp/firewatch-home.A1B2C3D4',remote.call_args.args[0][-1])

    def test_ssh_preserves_host_verification(self):
        args=installer.ssh_args('tv.local');self.assertIn('StrictHostKeyChecking=yes',args);self.assertIn('BatchMode=yes',args)
        self.assertNotIn('StrictHostKeyChecking=no',args)

    def test_malformed_response_not_success(self):
        for value in ['garbage','[]','null']:
            with self.assertRaises(RuntimeError):installer.parse_response(value)

if __name__=='__main__':unittest.main()
