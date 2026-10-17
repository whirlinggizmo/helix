"""Generate HeliX's API reference (HTML) from its doc comments with dox, pinned in dependencies.json.

Haxe describes the types once per target (XML), since each target has its own adapters: the browser's (DOM, WebGL2,
Web Audio, fetch, IndexedDB) and the native ones (Sokol, libsndfile, evdev, the filesystem). dox merges the two and marks
what only one target has. Output: build/api/index.html."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'build/api'
# The browser's adapters, by their API's name (the folder under each contract), and its profile; every other adapter and profile is native.
BROWSER_APIS={'dom','webgl2','webaudio','fetchapi','indexeddb','canvas','download'}

def targets():
    """The packages each target's description leaves out: (the browser's, the native ones), read from the adapters' folders so a new adapter is placed by its API's name."""
    browser=[];native=[]
    for contract in sorted((ROOT/'src/helix/adapters').iterdir()):
        if not contract.is_dir():continue
        if contract.name=='shared':native.append('helix.adapters.shared');continue
        for api in sorted(contract.iterdir()):
            if api.is_dir():(browser if api.name in BROWSER_APIS else native).append(f'helix.adapters.{contract.name}.{api.name}')
    for profile in sorted((ROOT/'src/helix/profiles').glob('*.hx')):
        (browser if profile.stem.startswith('Browser') else native).append(f'helix.profiles.{profile.stem}')
    return browser,native

def describe(target,ignore):
    """Haxe's XML description of package helix for one target, leaving out the other target's adapters."""
    output=OUT/'xml'/f'{target}.xml';output.parent.mkdir(parents=True,exist_ok=True)
    macro="include('helix',true,["+",".join(f"'{p}'" for p in ignore)+"])"
    args=['haxe','-cp','src','-cp','build/generated/shaders','-cp','build/generated/fonts','--macro',macro,'-xml',str(output),'-D','doc-gen','--no-output']
    args+=['-js',str(OUT/'unused.js')] if target=='js' else ['-cpp',str(OUT/'unused-cpp')]
    subprocess.run(args,cwd=ROOT,check=True)

def main():
    if not (ROOT/'build/generated/shaders/shader-contract.json').is_file():sys.exit('Generate the shaders first: python3 tools/example.py app-hello build web')
    version=json.loads((ROOT/'dependencies.json').read_text(encoding='utf-8'))['dox']
    env=dict(os.environ,HAXELIB_PATH=str(ROOT/'build/haxelib'))
    if not (ROOT/'build/haxelib/dox'/version.replace('.',',')).is_dir():subprocess.run(['haxelib','--always','install','dox',version],env=env,check=True,stdout=subprocess.DEVNULL)
    import bake_fonts
    bake_fonts.generate()
    if OUT.exists():shutil.rmtree(OUT)
    browser,native=targets()
    describe('js',native);describe('cpp',browser)
    # No source links yet: dox could link each type to its source on GitHub.
    subprocess.run(['haxelib','run','dox','-i',str(OUT/'xml'),'-o',str(OUT),'-in','^helix','--title','HeliX API',
        '-D','description','HeliX: a Haxe game framework over thin per-platform adapters.'],cwd=ROOT,env=env,check=True)
    print('API reference:',OUT/'index.html')

if __name__=='__main__':main()
