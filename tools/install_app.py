#!/usr/bin/env python3
"""Install the standalone app on an explicitly selected rooted TV. Dry run by default.
No root exploit, boot hook, remote mapping, firmware edit, or service restart.
"""
import argparse
import hashlib
import json
import re
import shlex
import subprocess
import sys
import time
from pathlib import Path

APP_ID = 'uk.local.minimalhome.native'
sys.path.insert(0, str(Path(__file__).resolve().parent))
from verify_ipk import verify_blob
PROBE = r'''set -eu
printf 'uid=%s\n' "$(id -u)"
printf 'arch=%s\n' "$(uname -m)"
for item in /usr/bin/qml-runner /usr/bin/luna-send; do
  if [ -x "$item" ]; then printf 'present=%s\n' "$item"; fi
done
if [ -d /var/lib/webosbrew/init.d ]; then printf 'homebrew=yes\n'; fi
'''


def validate_target(target):
    # No usernames, flags, shell syntax, brackets or proxy specifications.
    if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9.-]{0,252}', target or ''):
        raise ValueError('Use a TV IPv4 address or hostname only (no root@ prefix).')
    return target


def verify_package(package, checksum):
    package = Path(package).resolve()
    if package.suffix != '.ipk' or not package.is_file():
        raise ValueError('Choose a built .ipk file.')
    text = Path(checksum).read_text(encoding='utf-8').strip()
    expected = text.split()[0] if text else ''
    if not re.fullmatch(r'[a-fA-F0-9]{64}', expected):
        raise ValueError('Checksum file must start with a SHA-256 digest.')
    if package.stat().st_size > 200 * 1024 * 1024:
        raise ValueError('Package exceeds the supported size limit.')
    blob = package.read_bytes()
    actual = hashlib.sha256(blob).hexdigest()
    if actual != expected.lower():
        raise ValueError('Package checksum mismatch; nothing will be installed.')
    verify_blob(blob)
    return package, actual


def compatibility(output):
    lines = set(output.splitlines())
    errors = []
    if 'uid=0' not in lines: errors.append('Root SSH access is required for this native app candidate.')
    if not any(x in lines for x in ['arch=armv7l', 'arch=armv8l']):
        errors.append('This package targets 32-bit ARM; this CPU/runtime is unverified.')
    for path in ['/usr/bin/qml-runner', '/usr/bin/luna-send']:
        if 'present=' + path not in lines: errors.append('Required runtime missing: ' + path)
    if 'homebrew=yes' not in lines: errors.append('Homebrew Channel persistence directory was not found.')
    return errors


def ssh_args(target):
    return ['ssh', '-o', 'BatchMode=yes', '-o', 'StrictHostKeyChecking=yes',
            '-o', 'ConnectTimeout=8', 'root@' + validate_target(target)]


def run(args, **kwargs):
    result = subprocess.run(args, text=True, capture_output=True, timeout=45, **kwargs)
    if result.returncode: raise RuntimeError(result.stderr.strip() or result.stdout.strip() or 'Command failed')
    return result.stdout


def luna_command(method, payload):
    return '/usr/bin/luna-send -n 1 -w 30000 ' + shlex.quote('luna://' + method) + ' ' + shlex.quote(json.dumps(payload, separators=(',', ':')))


def parse_response(text):
    try: response = json.loads(text)
    except ValueError: raise RuntimeError('TV returned an unreadable response; no success assumed.')
    if not isinstance(response, dict): raise RuntimeError('Unexpected TV response.')
    return response


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--tv', help='TV IPv4 address or hostname; SSH host key must already be trusted')
    parser.add_argument('--package', type=Path, help='Local build output .ipk')
    parser.add_argument('--checksum', type=Path, help='Its .sha256 file')
    parser.add_argument('--apply', action='store_true', help='Actually upload/install this app only; otherwise print a plan without connecting')
    parser.add_argument('--doctor', action='store_true', help='Read-only runtime probe; does not upload/install')
    parser.add_argument('--mock', type=Path, help='Evaluate a local probe fixture, with no network access')
    args = parser.parse_args(argv)
    if args.mock:
        if args.apply or args.doctor or args.tv or args.package: parser.error('--mock cannot be combined with TV/install arguments')
        errors = compatibility(args.mock.read_text())
        print(json.dumps({'compatiblePrerequisites': not errors, 'errors': errors, 'tvRuntimeVerified': False}, indent=2))
        return 1 if errors else 0
    if not args.tv: parser.error('--tv is required, or use --mock')
    validate_target(args.tv)
    if args.doctor and args.apply: parser.error('Choose --doctor or --apply')
    package, digest = None, None
    if not args.doctor:
        if not args.package or not args.checksum: parser.error('--package and --checksum are required')
        package, digest = verify_package(args.package, args.checksum)
    if not args.apply and not args.doctor:
        print('DRY RUN — no connection made.')
        print('Target: root@' + args.tv)
        print('Package: ' + str(package) + '\nSHA-256: ' + digest)
        print('Will check root/ARM/runtime, refuse an existing installation, upload, check the TV-side hash, install, and verify registration.')
        print('Does not launch the app, replace Home, change startup, grant system permissions, or alter TV settings.')
        print('Run with --doctor for read-only checks; add --apply only when the owner is ready.')
        return 0
    remote = ssh_args(args.tv)
    errors = compatibility(run(remote + [PROBE]))
    if errors: raise RuntimeError('\n'.join(errors))
    print('Prerequisites found. LG QML imports, service permissions and performance still require validation on this TV.')
    if args.doctor: return 0
    # LG documents this success+boolean contract; error codes are not absence.
    existing = parse_response(run(remote + [luna_command('com.webos.applicationManager/getAppLoadStatus', {'appId':APP_ID})]))
    if existing.get('returnValue') is not True or type(existing.get('exist')) is not bool:
        raise RuntimeError('Could not establish whether the app exists; refusing to overwrite an unknown state.')
    if existing['exist']:
        raise RuntimeError('This app ID already exists. Stopping to preserve its installation. Back it up and use the documented update process.')
    expected_version = verify_blob(package.read_bytes())['version']
    # An isolated root-owned directory avoids following a pre-created /tmp symlink.
    remote_dir = run(remote + ['umask 077; mktemp -d /tmp/firewatch-home.XXXXXXXX']).strip()
    if not re.fullmatch(r'/tmp/firewatch-home\.[A-Za-z0-9]{8}', remote_dir):
        raise RuntimeError('Unexpected temporary-directory response; not uploading.')
    remote_package = remote_dir + '/candidate.ipk'
    try:
        with package.open('rb') as source:
            transfer = subprocess.run(remote + ['umask 077; cat > ' + shlex.quote(remote_package)], stdin=source, capture_output=True, timeout=120)
        if transfer.returncode: raise RuntimeError('Upload failed: ' + transfer.stderr.decode(errors='replace'))
        actual = run(remote + ['sha256sum ' + shlex.quote(remote_package)]).split()[0]
        if actual != digest: raise RuntimeError('TV-side checksum mismatch; not installing.')
        response = parse_response(run(remote + [luna_command('com.webos.appInstallService/dev/install', {'id':APP_ID,'ipkUrl':remote_package,'subscribe':False})]))
        if response.get('returnValue') is not True: raise RuntimeError('App installer refused: ' + json.dumps(response))
        # Acceptance may precede app registration. Never treat returnValue alone as success.
        for attempt in range(11):
            registered = parse_response(run(remote + [luna_command('com.webos.applicationManager/getAppInfo', {'id':APP_ID})]))
            info = registered.get('appInfo', {})
            if registered.get('returnValue') is True and isinstance(info, dict) and info.get('id') == APP_ID and info.get('version') == expected_version:
                print('App registration and version confirmed. Open Firewatch Home from LG Home when ready. Runtime is still unverified.')
                break
            if attempt < 10: time.sleep(2)
        else:
            raise RuntimeError('Install was accepted but the expected app/version was not registered after repeated checks. Inspect LG app list before retrying.')
    finally:
        try: run(remote + ['rm -f ' + shlex.quote(remote_package) + ' && rmdir ' + shlex.quote(remote_dir)])
        except Exception: print('Temporary package cleanup failed: ' + remote_dir, file=sys.stderr)
    return 0

if __name__ == '__main__':
    try: sys.exit(main())
    except (ValueError, RuntimeError, OSError, subprocess.TimeoutExpired) as error:
        print('Stopped: ' + str(error), file=sys.stderr); sys.exit(1)
