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
BROWSER_ONLY=['helix.adapters.host.dom','helix.adapters.graphics.webgl2','helix.adapters.input.dom','helix.adapters.audio.webaudio','helix.adapters.fetch.fetchapi','helix.adapters.storage.indexeddb','helix.profiles.BrowserWebGL2Profile']
NATIVE_ONLY=['helix.adapters.host.sokol','helix.adapters.graphics.sokol','helix.adapters.input.sokol','helix.adapters.audio.sokol','helix.adapters.audiodecoder.libsndfile','helix.adapters.fetch.haxehttp','helix.adapters.storage.filesystem','helix.adapters.internal','helix.profiles.NativeSokolGLProfile']

def describe(target,ignore):
    """Haxe's XML description of package helix for one target, leaving out the other target's adapters."""
    output=OUT/'xml'/f'{target}.xml';output.parent.mkdir(parents=True,exist_ok=True)
    macro="include('helix',true,["+",".join(f"'{p}'" for p in ignore)+"])"
    args=['haxe','-cp','src','-cp','build/generated/shaders','-cp','build/generated/fonts','--macro',macro,'-xml',str(output),'-D','doc-gen','--no-output']
    args+=['-js',str(OUT/'unused.js')] if target=='js' else ['-cpp',str(OUT/'unused-cpp')]
    subprocess.run(args,cwd=ROOT,check=True)

def main():
    if not (ROOT/'build/generated/shaders/shader-contract.json').is_file():sys.exit('Generate the shaders first: python3 tools/example.py app-hello build web')
    version=json.loads((ROOT/'dependencies.json').read_text())['dox']
    env=dict(os.environ,HAXELIB_PATH=str(ROOT/'build/haxelib'))
    if not (ROOT/'build/haxelib/dox'/version.replace('.',',')).is_dir():subprocess.run(['haxelib','--always','install','dox',version],env=env,check=True,stdout=subprocess.DEVNULL)
    import fontbake
    fontbake.generate()
    if OUT.exists():shutil.rmtree(OUT)
    describe('js',NATIVE_ONLY);describe('cpp',BROWSER_ONLY)
    # No source links yet: dox could link each type to its source on GitHub.
    subprocess.run(['haxelib','run','dox','-i',str(OUT/'xml'),'-o',str(OUT),'-in','^helix','--title','HeliX API',
        '-D','description','HeliX: a Haxe game framework over thin per-platform adapters.'],cwd=ROOT,env=env,check=True)
    print('API reference:',OUT/'index.html')

if __name__=='__main__':main()
