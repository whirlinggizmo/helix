"""Lay out HeliX's Haxe source with haxe-formatter (docs/CONVENTIONS.md), or --check that it is laid out.

The formatter is pinned in dependencies.json and installed into the repository's own haxelib (build/haxelib), as hxcpp is.
hxformat.json holds only what differs from the pinned version's defaults: the files left alone (build output). Laying out runs the formatter
until its own check passes, as it lays some code out again on a second pass."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
HAXELIB=ROOT/'build/haxelib'
SOURCES=['src','examples','tests','Run.hx']

def formatter():
    """The pinned formatter in the repository's haxelib, installed on first use."""
    version=json.loads((ROOT/'dependencies.json').read_text(encoding='utf-8'))['formatter']
    env=dict(os.environ,HAXELIB_PATH=str(HAXELIB));HAXELIB.mkdir(parents=True,exist_ok=True)
    if not (HAXELIB/'formatter'/version.replace('.',',')).is_dir():
        subprocess.run(['haxelib','--always','install','formatter',version],env=env,check=True,stdout=subprocess.DEVNULL)
    return env

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--check',action='store_true',help="don't change files; fail if any isn't laid out");a=p.parse_args()
    env=formatter();args=['haxelib','run','formatter']+sum((['-s',s] for s in SOURCES),[])
    if a.check:
        result=subprocess.run(args+['--check'],cwd=ROOT,env=env,capture_output=True,text=True,encoding='utf-8')
        print((result.stdout+result.stderr).strip()[-3000:])
        sys.exit(result.returncode)
    # The formatter lays some code out again on a second pass (a comprehension's condition, say): it runs until its check passes, so what
    # it leaves is what --check, and CI, accepts.
    for _ in range(4):
        result=subprocess.run(args,cwd=ROOT,env=env,capture_output=True,text=True,encoding='utf-8')
        print((result.stdout+result.stderr).strip()[-3000:])
        if result.returncode:sys.exit(result.returncode)
        if subprocess.run(args+['--check'],cwd=ROOT,env=env,capture_output=True).returncode==0:return
    sys.exit('format: the layout still changes after four passes')

if __name__=='__main__':main()
