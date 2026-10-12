"""Snapshot reference public functions through Clang JSON AST, without source scraping.

This inventories declarations, not semantic equivalence or benchmark coverage.
Reference repositories are read-only inputs; temporary compilation stays here.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

ROOT=Path(__file__).resolve().parents[1]

def identities(root,paths):
    return {p.relative_to(root).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(paths)}

def inventory(root,kind,clang):
    headers=sorted((root/'include').glob('wgr*.h')) if kind=='wgrender-c' else sorted((root/'libwgf').glob('*/include/wgf*.h'))+[root/'include/wgf_api.h']
    docs=[p for p in [root/'README.md',root/'ARCHITECTURE.md',root/'docs/ARCHITECTURE.md',root/'docs/ROADMAP.md'] if p.is_file()]
    before=identities(root,headers+docs)
    prefix='wgr_' if kind=='wgrender-c' else 'wgf_'
    def git(*args):return subprocess.check_output(['git','-C',str(root),*args],text=True).strip()
    head=git('rev-parse','HEAD');status=git('status','--porcelain')
    work=ROOT/'build/feature-inventory';work.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory(dir=work) as directory:
        source=Path(directory)/'public.c';astfile=Path(directory)/'ast.json'
        source.write_text(''.join('#include '+json.dumps(p.as_posix())+'\n' for p in headers))
        command=[clang,'-fsyntax-only','-Xclang','-ast-dump=json',*[arg for path in sorted({p.parent for p in headers}) for arg in ['-I',str(path)]],str(source)]
        with astfile.open('w') as out:subprocess.run(command,stdout=out,check=True)
        ast=json.loads(astfile.read_text())
    functions={}
    def visit(node):
        name=node.get('name','')
        if node.get('kind')=='FunctionDecl' and name.startswith(prefix) and not node.get('isImplicit',False):
            signature=node['type']['qualType']
            old=functions.get(name)
            if old and old['signature']!=signature:raise RuntimeError('Conflicting declaration: '+name)
            functions[name]={'name':name,'signature':signature,'area':name.split('_')[1],
                             'inline':bool(node.get('inline',False)),
                             'equivalence':'Not individually verified; see FEATURE_PARITY.md capability/probe matrix'}
        for child in node.get('inner',[]):visit(child)
    visit(ast)
    if before!=identities(root,headers+docs) or head!=git('rev-parse','HEAD') or status!=git('status','--porcelain'):
        raise RuntimeError('Reference changed during inventory; rerun for a coherent snapshot')
    return {'repository':str(root),'head':head,'workingTreeStatus':status.splitlines(),
            'inputs':before,'publicHeaderCount':len(headers),'publicFunctionCount':len(functions),
            'functions':sorted(functions.values(),key=lambda f:f['name']),
            'scope':'Public prefixed function declarations, including inline math. Types, enums, macros, generated Haxe bindings and undocumented internals are not counted. No implementation/performance equivalence inferred.'}

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--clang',required=True);parser.add_argument('--wgrender',type=Path,required=True);parser.add_argument('--libwgf',type=Path,required=True)
    args=parser.parse_args()
    result={'schema':1,'capturedAt':datetime.now(timezone.utc).isoformat(),'compiler':subprocess.check_output([args.clang,'--version'],text=True).strip(),
            'configuration':'Default C preprocessing; no application defines. This is a declaration inventory, not an ABI/type-size comparison.',
            'method':'Clang -fsyntax-only -Xclang -ast-dump=json; no regex/text extraction of declarations',
            'references':{kind:inventory(path.resolve(),kind,args.clang) for kind,path in [('wgrender-c',args.wgrender),('libwgf',args.libwgf)]}}
    (ROOT.parent/'results/reference-features.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps({kind:{k:v[k] for k in ['head','publicHeaderCount','publicFunctionCount']} for kind,v in result['references'].items()}))

if __name__=='__main__':main()
