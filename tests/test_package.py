import importlib.util
import io
import json
import pathlib
import struct
import tarfile
import tempfile
import unittest

MODULE = pathlib.Path(__file__).resolve().parents[1] / 'tools/package_ipk.py'
spec = importlib.util.spec_from_file_location('ipk', MODULE)
ipk = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ipk)


def arm_elf():
    # Minimal fixture with no dynamic linker; actual compiler output checked by build.
    data=bytearray(84);data[:7]=b'\x7fELF\x01\x01\x01';struct.pack_into('<H',data,18,40)
    struct.pack_into('<I',data,28,52);struct.pack_into('<HH',data,42,32,1)
    struct.pack_into('<I',data,52,1)
    return bytes(data)


def members(data):
    if not data.startswith(b'!<arch>\n'): raise ValueError('Not ar')
    offset=8;result={}
    while offset < len(data):
        header=data[offset:offset+60]
        assert header[58:60]==b'`\n'
        size=int(header[48:58]);name=header[:16].decode().strip().rstrip('/')
        result[name]=data[offset+60:offset+60+size];offset+=60+size+size%2
    return result


class PackageTests(unittest.TestCase):
    def stage(self, root):
        stage=root/'stage';stage.mkdir()
        (stage/'appinfo.json').write_text(json.dumps({'id':'uk.local.minimalhome.native','version':'3.1.0','main':'minimal-home','icon':'icon.png','largeIcon':'large-icon.png'}))
        for name in ['main.qml','icon.png','large-icon.png']:(stage/name).write_bytes(b'fixture')
        (stage/'minimal-home').write_bytes(arm_elf())
        return stage

    def test_deterministic_safe_archive_and_integrity_manifest(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=pathlib.Path(tmp);stage=self.stage(root)
            first=ipk.package(stage,root/'one.ipk');second=ipk.package(stage,root/'two.ipk')
            self.assertEqual(first['sha256'],second['sha256'])
            contents=members((root/'one.ipk').read_bytes())
            self.assertEqual(list(contents),['debian-binary','control.tar.gz','data.tar.gz'])
            with tarfile.open(fileobj=io.BytesIO(contents['control.tar.gz'])) as t:
                self.assertEqual(t.getnames(),['control']) # No install/remove scripts.
                fields=dict(line.split(': ',1) for line in t.extractfile('control').read().decode().splitlines())
                self.assertEqual(int(fields['Installed-Size']),sum(f['bytes'] for f in first['files']))
                self.assertEqual(fields['webOS-Packager-Version'],'1.0.0')
            with tarfile.open(fileobj=io.BytesIO(contents['data.tar.gz'])) as t:
                for f in t:
                    self.assertTrue(f.name.startswith(('usr/palm/applications/','usr/palm/packages/')))
                    self.assertFalse(f.issym())
                binary=t.getmember('usr/palm/applications/uk.local.minimalhome.native/minimal-home')
                self.assertEqual(binary.mode,0o755)
            self.assertFalse(first['runtimeVerifiedOnTV'])
            self.assertFalse(first['systemIntegrationIncluded'])

    def test_reject_symlinks_and_credentials(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=pathlib.Path(tmp);stage=self.stage(root)
            link=stage/'link';link.symlink_to(stage/'main.qml')
            with self.assertRaisesRegex(ValueError,'Symlinks'):ipk.package(stage,root/'test.ipk')
            link.unlink();(stage/'private.key').write_text('fixture')
            with self.assertRaisesRegex(ValueError,'credentials'):ipk.package(stage,root/'test.ipk')

    def test_reject_wrong_architecture_and_dynamic_binary(self):
        with self.assertRaises(ValueError):ipk.elf_arm_static(b'not ELF')
        data=bytearray(arm_elf());struct.pack_into('<H',data,18,62)
        with self.assertRaisesRegex(ValueError,'ARM'):ipk.elf_arm_static(data)
        data=bytearray(arm_elf());struct.pack_into('<I',data,52,3)
        with self.assertRaisesRegex(ValueError,'static'):ipk.elf_arm_static(data)

    def test_reject_path_traversal(self):
        for name in ('/etc/test','../test','safe/../../test'):
            with self.assertRaisesRegex(ValueError,'Unsafe'):ipk.tar_gz([(name,b'payload',0o644)])

    def test_reject_missing_icon(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=pathlib.Path(tmp);stage=self.stage(root);(stage/'icon.png').unlink()
            with self.assertRaisesRegex(ValueError,'Missing manifest'):ipk.package(stage,root/'test.ipk')


if __name__=='__main__':unittest.main()
