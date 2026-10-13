"""Use an experiment-local haxelib holding the pinned hxcpp release, as libwgf's CI does."""
import json,os,subprocess,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
HAXELIB=ROOT/'build/haxelib'
def active(version):
    try:path=Path(subprocess.check_output(['haxelib','path','hxcpp'],text=True,stderr=subprocess.DEVNULL).splitlines()[0].strip()).resolve()
    except (subprocess.CalledProcessError,IndexError):return None
    if not path.is_relative_to(HAXELIB.resolve()) or not (path/'haxelib.json').is_file():return None
    return path if json.loads((path/'haxelib.json').read_text())['version']==version else None
def check_hxcpp():
    # Haxe runs `haxelib run hxcpp` without a version, so only the resolved current release is reliable.
    version=json.loads((ROOT/'dependencies.json').read_text())['hxcpp'];HAXELIB.mkdir(parents=True,exist_ok=True);os.environ['HAXELIB_PATH']=str(HAXELIB)
    if active(version):return
    for attempt in range(3):
        if subprocess.run(['haxelib','--always','install','hxcpp',version]).returncode==0:break
        time.sleep(10*(attempt+1))
    subprocess.run(['haxelib','--always','set','hxcpp',version],check=True)
    if not active(version):raise RuntimeError(f'Could not install hxcpp {version} into {HAXELIB}')

def check_sokol(root):
    """The vendored Sokol headers and sokol_app_utils.h match their pins in dependencies.json."""
    import hashlib,json
    sokol=json.loads((root/'dependencies.json').read_text())['sokol']
    for name,identity in sokol['headers'].items():
        if hashlib.sha256((root/'vendor'/name).read_bytes()).hexdigest()!=identity:raise RuntimeError('Pinned Sokol header changed: '+name)
    for part in ('audio','appUtils'):
        pin=sokol[part]
        if hashlib.sha256((root/pin['source']).read_bytes()).hexdigest()!=pin['sha256']:raise RuntimeError('Pinned Sokol header changed: '+pin['source'])
