#!/usr/bin/env python3
"""Deterministic, app-only webOS IPK writer. Python standard library only."""
import argparse
import gzip
import hashlib
import io
import json
import pathlib
import struct
import tarfile

EPOCH = 1767225600  # Fixed archive metadata; never source filesystem mtimes.


def checked_files(root):
    root = pathlib.Path(root)
    files = []
    for p in sorted(root.rglob('*')):
        if p.is_symlink():
            raise ValueError('Symlinks are not package assets: ' + str(p))
        if p.is_file():
            if p.name.startswith('.') or p.suffix in ('.pem', '.key'):
                raise ValueError('Hidden files or credentials cannot be packaged: ' + str(p))
            files.append((p.relative_to(root).as_posix(), p.read_bytes(), 0o755 if p.name == 'minimal-home' else 0o644))
        elif not p.is_dir():
            raise ValueError('Unsupported filesystem entry: ' + str(p))
    return files


def tar_gz(files):
    raw = io.BytesIO()
    with tarfile.open(fileobj=raw, mode='w', format=tarfile.USTAR_FORMAT) as archive:
        for name, content, mode in sorted(files):
            path = pathlib.PurePosixPath(name)
            if path.is_absolute() or '..' in path.parts:
                raise ValueError('Unsafe archive path: ' + name)
            info = tarfile.TarInfo(name)
            info.size = len(content)
            info.mode = mode
            info.mtime = EPOCH
            info.uid = info.gid = 0
            info.uname = info.gname = 'root'
            archive.addfile(info, io.BytesIO(content))
    output = io.BytesIO()
    with gzip.GzipFile(filename='', fileobj=output, mode='wb', mtime=EPOCH, compresslevel=9) as stream:
        stream.write(raw.getvalue())
    return output.getvalue()


def ar(members):
    output = bytearray(b'!<arch>\n')
    for name, data in members:
        header = f'{name + "/":<16}{EPOCH:<12}{0:<6}{0:<6}{100644:<8}{len(data):<10}`\n'.encode('ascii')
        if len(header) != 60:
            raise ValueError('Invalid ar header')
        output.extend(header)
        output.extend(data)
        if len(data) % 2:
            output.extend(b'\n')
    return bytes(output)


def elf_arm_static(data):
    if len(data) < 52 or data[:7] != b'\x7fELF\x01\x01\x01' or struct.unpack_from('<H', data, 18)[0] != 40:
        raise ValueError('Launcher must be a little-endian 32-bit ARM ELF')
    offset = struct.unpack_from('<I', data, 28)[0]
    size, count = struct.unpack_from('<HH', data, 42)
    if size < 32 or offset + size * count > len(data):
        raise ValueError('Invalid ELF program headers')
    for i in range(count):
        if struct.unpack_from('<I', data, offset+i*size)[0] in (2, 3):
            raise ValueError('Launcher must be static: dynamic interpreter/libraries found')
    return True


def package(stage, output):
    stage, output = pathlib.Path(stage), pathlib.Path(output)
    app = json.loads((stage / 'appinfo.json').read_text())
    appid, version = app['id'], app['version']
    if appid != 'uk.local.minimalhome.native' or not all(c.isdigit() or c == '.' for c in version):
        raise ValueError('Unexpected package identity/version')
    for key in ('icon', 'largeIcon', 'main'):
        if not (stage / app[key]).is_file():
            raise ValueError('Missing manifest file: ' + app[key])
    elf_arm_static((stage / app['main']).read_bytes())
    files = checked_files(stage)
    payload = [('usr/palm/applications/' + appid + '/' + n, data, mode) for n, data, mode in files]
    packageinfo = json.dumps({'id': appid, 'version': version, 'app': appid}, indent=2).encode() + b'\n'
    payload.append(('usr/palm/packages/' + appid + '/packageinfo.json', packageinfo, 0o644))
    # LG webos-tools/cli writes the sum of stat.size bytes here, not Debian KiB.
    control = (f'Package: {appid}\nVersion: {version}\nSection: misc\nPriority: optional\nArchitecture: arm\n'
               f'Installed-Size: {sum(len(d) for _, d, _ in payload)}\nMaintainer: Firewatch Home contributors <nobody@example.com>\n'
               'Description: Firewatch Home standalone developer preview\nwebOS-Package-Format-Version: 2\nwebOS-Packager-Version: 1.0.0\n')
    blob = ar([('debian-binary', b'2.0\n'), ('control.tar.gz', tar_gz([('control', control.encode(), 0o644)])), ('data.tar.gz', tar_gz(payload))])
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(blob)
    digest = hashlib.sha256(blob).hexdigest()
    output.with_suffix('.ipk.sha256').write_text(digest + '  ' + output.name + '\n')
    manifest = {'id': appid, 'version': version, 'architecture': 'arm', 'package': output.name, 'sha256': digest,
                'bytes': len(blob), 'runtimeVerifiedOnTV': False, 'systemIntegrationIncluded': False,
                'files': [{'path': n, 'sha256': hashlib.sha256(d).hexdigest(), 'bytes': len(d), 'mode': oct(m)} for n,d,m in payload]}
    output.with_suffix('.manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    return manifest


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('stage')
    parser.add_argument('output')
    args = parser.parse_args()
    result = package(args.stage, args.output)
    print(json.dumps({k: result[k] for k in ('package', 'sha256', 'bytes', 'runtimeVerifiedOnTV')}, indent=2))
