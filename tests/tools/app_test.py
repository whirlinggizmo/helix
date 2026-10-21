"""helix.App's build (src/helix/macro/AppBuild.hx): tests/app/AppTests.hx built for the browser with its backend named and run on Node
(the springboards the build writes into a game class, the backend table, AppOptions' defaults; the interpreter can't build a profile, whose
adapters are a target's), and the builds it must refuse: one naming no backend, one naming a name not in the list, and an sdl3-gpu build
without the programs' SDL_GPU dialects (-D helix_sdl3_gpu); each refusal names what to add.

    python3 tests/tools/app_test.py"""
import json
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]

def haxe(*args):
    """A build of tests/app over the library's class paths, as the unit tests build."""
    return subprocess.run(['haxe','-cp','src','-cp','generated/shaders','-cp','generated/fonts','-cp','tests/app','-main','AppTests',*args],cwd=ROOT,capture_output=True,text=True,encoding='utf-8')

def main():
    (ROOT/'build/tests').mkdir(parents=True,exist_ok=True)
    result=haxe('-D','helix-backend=webgl2','-js','build/tests/app-tests.js','-dce','full')
    assert result.returncode==0,result.stderr
    result=subprocess.run(['node','build/tests/app-tests.js'],cwd=ROOT,capture_output=True,text=True,encoding='utf-8')
    assert result.returncode==0,result.stderr
    value=json.loads(result.stdout[result.stdout.index('{'):])
    assert value['passed']
    print(f'AppTests: {value["checks"]} checks',flush=True)
    for label,args,expected in (
        ('no backend',[],'-D helix-backend=webgl2, sokol-gl, sdl3-gl or sdl3-gpu'),
        ('unknown backend',['-D','helix-backend=gl'],'"gl" is not a backend'),
        ('sdl3-gpu without its dialects',['-D','helix-backend=sdl3-gpu'],'helix_sdl3_gpu')):
        result=haxe(*args,'-js','build/tests/app-refused.js','--no-output')
        assert result.returncode!=0,f'{label}: built'
        assert expected in result.stderr,f'{label}: refused without saying why:\n{result.stderr}'
        print(f'refused: {label}',flush=True)

if __name__=='__main__':main()
