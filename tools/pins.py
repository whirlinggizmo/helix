"""The repository's haxelib (build/haxelib): the libraries as dev links to this checkout, and the pinned hxcpp release."""
import json,os,subprocess,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
HAXELIB=ROOT/'build/haxelib'
def active(version):
    try:path=Path(subprocess.check_output(['haxelib','path','hxcpp'],text=True, encoding='utf-8',stderr=subprocess.DEVNULL).splitlines()[0].strip()).resolve()
    except (subprocess.CalledProcessError,IndexError):return None
    if not path.is_relative_to(HAXELIB.resolve()) or not (path/'haxelib.json').is_file():return None
    return path if json.loads((path/'haxelib.json').read_text(encoding='utf-8'))['version']==version else None
def check_hxcpp():
    # Haxe runs `haxelib run hxcpp` without a version, so only the resolved current release is reliable.
    version=json.loads((ROOT/'dependencies.json').read_text(encoding='utf-8'))['hxcpp'];HAXELIB.mkdir(parents=True,exist_ok=True);os.environ['HAXELIB_PATH']=str(HAXELIB)
    if active(version):return
    for attempt in range(3):
        if subprocess.run(['haxelib','--always','install','hxcpp',version]).returncode==0:break
        time.sleep(10*(attempt+1))
    subprocess.run(['haxelib','--always','set','hxcpp',version],check=True)
    if not active(version):raise RuntimeError(f'Could not install hxcpp {version} into {HAXELIB}')

# The libraries, each a dev link in the repository's haxelib to this checkout's directory holding its haxelib.json.
LIBRARIES={'helix-platform':ROOT/'platform','helix-log':ROOT/'log','helix-math':ROOT/'math','helix-services':ROOT/'services','helix-ray':ROOT/'ray'}

def link(name,path):
    """name in the repository's haxelib as a dev link to path (where its haxelib.json is)."""
    (HAXELIB/name).mkdir(parents=True,exist_ok=True);(HAXELIB/name/'.dev').write_text(str(path)+'\n',encoding='utf-8')

def use_haxelib():
    """Makes this process and what it starts build with the repository's haxelib (build/haxelib): each library a dev link to this
    checkout's (a worktree builds its own), as a program's -lib finds them. Returns the environment."""
    HAXELIB.mkdir(parents=True,exist_ok=True)
    for name,path in LIBRARIES.items():link(name,path)
    os.environ['HAXELIB_PATH']=str(HAXELIB)
    return os.environ

def check_sokol(root):
    """The vendored Sokol headers (platform/vendor) match their pins in dependencies.json."""
    import hashlib,json
    sokol=json.loads((root/'dependencies.json').read_text(encoding='utf-8'))['sokol']
    for name,identity in sokol['headers'].items():
        if hashlib.sha256((root/name).read_bytes()).hexdigest()!=identity:raise RuntimeError('Pinned Sokol header changed: '+name)


if __name__ == '__main__':
    import cli
    cli.module(__doc__)
