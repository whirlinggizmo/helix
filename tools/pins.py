"""Fail early when the active hxcpp differs from the pinned revision."""
import json,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def check_hxcpp():
    pinned=json.loads((ROOT/'dependencies.json').read_text())['hxcpp']
    try:path=subprocess.check_output(['haxelib','path','hxcpp'],text=True).splitlines()[0].strip()
    except (OSError,subprocess.CalledProcessError,IndexError):raise RuntimeError('hxcpp is not installed; native builds require hxcpp '+pinned)
    try:active=subprocess.check_output(['git','-C',path,'rev-parse','HEAD'],text=True,stderr=subprocess.DEVNULL).strip()
    except (OSError,subprocess.CalledProcessError):raise RuntimeError(f'hxcpp at {path} is not a git checkout; native builds require hxcpp {pinned} (https://github.com/robknopf/hxcpp)')
    if active!=pinned:raise RuntimeError(f'hxcpp at {path} is {active}; native builds require {pinned} (https://github.com/robknopf/hxcpp)')
