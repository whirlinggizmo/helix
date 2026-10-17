"""List HeliX's public types and members that have no doc comment (docs/CONVENTIONS.md), and fail if there are any.

Covers src/helix. A member that implements an interface's is documented on the interface, and an override on what it
overrides; adapters' internal packages (C bridges) are left out."""
from pathlib import Path
import re
import sys

ROOT=Path(__file__).resolve().parents[1]
TYPE=re.compile(r'^\s*(?:@:[^\n]*\s)*(?:extern\s+|final\s+|private\s+)*(class|interface|typedef|enum abstract|enum|abstract)\s+(\w+)')
MEMBER=re.compile(r'^\s*(?:@:[\w.]+(?:\([^)]*\))?\s*)*((?:public\s+|static\s+|inline\s+|override\s+|final\s+|extern\s+|dynamic\s+)*)(function|var|final)\s+(\w+)')

def documented(lines,i):
    """Whether the declaration on line i follows a doc comment (metadata lines may sit between)."""
    j=i-1
    while j>=0 and (lines[j].strip()=='' or lines[j].strip().startswith('@:')):j-=1
    return j>=0 and lines[j].rstrip().endswith('*/') and any('/**' in lines[k] for k in range(max(0,j-40),j+1))

def interface_members():
    """Each interface's member names, by interface name."""
    found={}
    for path in (ROOT/'src/helix').rglob('*.hx'):
        text=path.read_text(encoding='utf-8')
        for m in re.finditer(r'\binterface\s+(\w+)[^{]*\{(.*?)\n\}',text,re.S):
            found[m.group(1)]=set(re.findall(r'\b(?:function|var)\s+(\w+)',m.group(2)))
    return found

def main():
    interfaces=interface_members();missing=[]
    for path in sorted((ROOT/'src/helix').rglob('*.hx')):
        if '/internal/' in path.as_posix():continue
        lines=path.read_text(encoding='utf-8').splitlines();kind=None;inherited=set();depth=0
        for i,line in enumerate(lines):
            t=TYPE.match(line)
            if t and depth==0:
                kind=t.group(1);inherited=set()
                for name in re.findall(r'\bimplements\s+([\w.]+)',line):inherited|=interfaces.get(name.split('.')[-1],set())
                if not documented(lines,i):missing.append(f'{path.relative_to(ROOT)}:{i+1}: {kind} {t.group(2)}')
            m=MEMBER.match(line) if depth==1 else None
            if m:
                modifiers,name=m.group(1),m.group(3)
                public=kind=='interface' or 'public' in modifiers
                if public and 'override' not in modifiers and name not in inherited and not documented(lines,i):
                    missing.append(f'{path.relative_to(ROOT)}:{i+1}: {name}')
            depth+=line.count('{')-line.count('}')
    for item in missing:print(item)
    print(f'{len(missing)} undocumented',file=sys.stderr)
    sys.exit(1 if missing else 0)

if __name__=='__main__':main()
