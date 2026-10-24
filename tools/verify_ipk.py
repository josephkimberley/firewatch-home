"""Validate the identity and app-only contents of a Firewatch Home candidate IPK."""
import io
import json
import re
import tarfile

APP_ID='uk.local.minimalhome.native'
MAX_PACKAGE=200*1024*1024
MAX_EXPANDED=256*1024*1024


def ar_members(blob):
    if len(blob)>MAX_PACKAGE or not blob.startswith(b'!<arch>\n'):
        raise ValueError('Not a bounded IPK/ar package.')
    offset=8;result={}
    while offset<len(blob):
        header=blob[offset:offset+60]
        if len(header)!=60 or header[58:]!=b'`\n':raise ValueError('Malformed IPK/ar header.')
        try:
            name=header[:16].decode('ascii').strip().rstrip('/')
            size=int(header[48:58].decode('ascii').strip())
        except (ValueError,UnicodeError):raise ValueError('Invalid IPK/ar member.')
        if name in result or name not in ('debian-binary','control.tar.gz','data.tar.gz') or size<0 or offset+60+size>len(blob):
            raise ValueError('Unexpected, duplicated or truncated IPK member.')
        result[name]=blob[offset+60:offset+60+size];offset+=60+size
        if size%2:
            if blob[offset:offset+1]!=b'\n':raise ValueError('Malformed IPK member padding.')
            offset+=1
    if set(result)!=set(('debian-binary','control.tar.gz','data.tar.gz')) or result['debian-binary']!=b'2.0\n':
        raise ValueError('Incomplete IPK package.')
    return result


def tar_metadata(blob, control=False):
    seen=set();selected={};total=0
    app_root='usr/palm/applications/'+APP_ID+'/'
    package_path='usr/palm/packages/'+APP_ID+'/packageinfo.json'
    selected_paths={'control'} if control else {app_root+'appinfo.json',app_root+'minimal-home',package_path}
    with tarfile.open(fileobj=io.BytesIO(blob),mode='r|gz') as archive:
        for member in archive:
            name=member.name
            if name.startswith('./'):name=name[2:]
            if name.startswith('/') or '..' in name.split('/') or name in seen or len(seen)>1000:
                raise ValueError('Unsafe or duplicated archive path.')
            seen.add(name)
            # We generate flat regular entries; no links, device nodes or executable hooks.
            if not member.isfile() or member.mode & 0o7000:
                raise ValueError('Only regular, non-privileged package assets are accepted.')
            if control and name!='control':raise ValueError('Install/remove hooks are not allowed.')
            if not control and not (name.startswith(app_root) or name==package_path):
                raise ValueError('Package includes files outside the Firewatch Home app.')
            total+=member.size
            if member.size<0 or member.size>64*1024*1024 or total>MAX_EXPANDED:
                raise ValueError('Package exceeds asset size bounds.')
            if name in selected_paths:
                if member.size>1024*1024:raise ValueError('Package metadata/launcher is too large.')
                selected[name]=archive.extractfile(member).read()
    if not selected_paths.issubset(selected):raise ValueError('Required package metadata or launcher missing.')
    return selected,seen


def _verify_blob(blob):
    from package_ipk import elf_arm_static
    members=ar_members(blob)
    control,_=tar_metadata(members['control.tar.gz'],True)
    fields={}
    for line in control['control'].decode('utf8').splitlines():
        if ':' not in line:raise ValueError('Malformed control metadata.')
        key,value=line.split(':',1)
        if key in fields:raise ValueError('Duplicated control field.')
        fields[key]=value.strip()
    if fields.get('Package')!=APP_ID or fields.get('Architecture')!='arm':raise ValueError('Wrong application identity or architecture.')
    version=fields.get('Version','')
    if not re.fullmatch(r'\d+\.\d+\.\d+',version):raise ValueError('Invalid application version.')
    data,names=tar_metadata(members['data.tar.gz'])
    prefix='usr/palm/applications/'+APP_ID+'/'
    app=json.loads(data[prefix+'appinfo.json'])
    package=json.loads(data['usr/palm/packages/'+APP_ID+'/packageinfo.json'])
    if not isinstance(app,dict) or not isinstance(package,dict):raise ValueError('Invalid application metadata.')
    if app.get('id')!=APP_ID or app.get('version')!=version or app.get('type')!='native' or app.get('main')!='minimal-home':
        raise ValueError('Manifest identity/version/type mismatch.')
    if package!={'id':APP_ID,'version':version,'app':APP_ID}:raise ValueError('Package identity/version mismatch.')
    if any(key in app for key in ('requiredPermissions','trustLevel','services')):raise ValueError('Package requests unsupported privileges.')
    for key in ('icon','largeIcon'):
        value=app.get(key,'')
        if not value or prefix+value not in names:raise ValueError('Manifest icon is missing.')
    if prefix+'main.qml' not in names:raise ValueError('Application QML missing.')
    elf_arm_static(data[prefix+'minimal-home'])
    return {'id':APP_ID,'version':version,'architecture':'arm','fileCount':len(names)}


def verify_blob(blob):
    try:
        return _verify_blob(blob)
    except (tarfile.TarError, EOFError) as error:
        raise ValueError('Malformed compressed package archive.') from error
