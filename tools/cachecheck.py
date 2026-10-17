"""The browser asset cache across visits, as a returning visitor meets it (docs/DECISIONS.md 111): sprite2d served from a copy of the site by
a host that answers as GitHub Pages does (an ETag, Cache-Control: max-age=600, 304 to a matching If-None-Match), visited by one browser
profile, its requests counted:

1. the first visit downloads its assets;
2. the second asks for the root manifest alone;
3. after its two logos swap (the manifests written again): only they and the manifests on their way are fetched, and the picture changes;
4. offline: no asset arrives, and the picture is the third's, from the cache;
5. after one logo is removed: it's asked about, the host says 404, and the page says its load failed.

With --native, the same visits by sprite2d's native build (the sokol profile), downloading from the host (HELIX_ASSET_HOST, its manifest
HELIX_ASSET_MANIFEST) into a cache directory of its own, on a private display: the requests are the same, offline is a host that doesn't
answer, and the program's output says whether a load failed.

  python3 tools/cachecheck.py --browser /path/to/chromium [--native]   (after tools/example.py sprite2d build web [and native])"""
import argparse
import collections
import email.utils
import functools
import hashlib
import http.server
import json
import shutil
import subprocess
import sys
import threading
import time
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
import gen_manifest

EXAMPLE='sprite2d'
LOGOS=('sprites/logo/wg-logo-bw-alpha.png','sprites/logo/wg-logo-white-alpha.png')

def serve(site,counts):
    """A host for site answering as Pages does; counts each asset request by path, and its 304s as '<path> 304'."""
    class Host(http.server.SimpleHTTPRequestHandler):
        def __init__(self,*args,**kwargs):super().__init__(*args,directory=str(site),**kwargs)
        def log_message(self,*args):pass
        def end_headers(self):
            self.send_header('Cache-Control','max-age=600')
            super().end_headers()
        def send_head(self):
            path=self.path.split('?')[0]
            if path.startswith('/assets/'):counts[path]+=1
            file=Path(self.translate_path(path))
            if file.is_file():
                tag='"'+hashlib.sha256(file.read_bytes()).hexdigest()[:16]+'"'
                if self.headers.get('If-None-Match')==tag:
                    counts[path+' 304']+=1
                    self.send_response(304);self.send_header('ETag',tag);self.end_headers();return None
                self.tag=tag
            return super().send_head()
        def send_header(self,name,value):
            super().send_header(name,value)
            if name=='Content-Type' and getattr(self,'tag',None):super().send_header('ETag',self.tag);self.tag=None
    server=http.server.ThreadingHTTPServer(('127.0.0.1',0),Host)
    threading.Thread(target=server.serve_forever,daemon=True).start()
    return server

def main():
    p=argparse.ArgumentParser(description=__doc__,formatter_class=argparse.RawDescriptionHelpFormatter);p.add_argument('--browser',required=True)
    p.add_argument('--native',action='store_true',help="also sprite2d's native build, downloading from the host");a=p.parse_args()
    built=ROOT/'build/web'
    if not (built/EXAMPLE/'app.js').is_file():sys.exit(f'Build it first: python3 tools/example.py {EXAMPLE} build web')
    work=ROOT/'build/cachecheck'
    if work.exists():shutil.rmtree(work)
    site=work/'site';profile=work/'profile'
    shutil.copytree(built/EXAMPLE,site/EXAMPLE);shutil.copytree(built/'assets',site/'assets')
    counts=collections.Counter();server=serve(site,counts);url=f'http://127.0.0.1:{server.server_address[1]}/{EXAMPLE}/'
    native=ROOT/f'build/native/{EXAMPLE}'
    if a.native and not (native/'Main').is_file():sys.exit(f'Build it first: python3 tools/example.py {EXAMPLE} build native')
    def visit_native(n,network='online'):
        # A visit is a run of a few seconds; offline, the host is a port nothing answers on.
        counts.clear()
        port=server.server_address[1] if network=='online' else closed_port()
        child=dict(display,HELIX_ASSET_HOST=f'http://127.0.0.1:{port}/assets/',HELIX_ASSET_MANIFEST='manifest.json',HELIX_CACHE=str(work/'native-cache'),HELIX_AUDIO='0')
        program=subprocess.Popen([str(native/'Main')],cwd=native,env=child,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,encoding='utf-8')
        time.sleep(4);program.terminate()
        output=program.communicate(timeout=10)[0]
        return dict(counts),[line for line in output.splitlines() if 'rror' in line or 'HTTP' in line or 'ailed' in line],None
    def visit(n,network='online'):
        counts.clear()
        out=subprocess.run(['node',str(ROOT/'tools/cachecheck.cjs'),a.browser,url,str(profile),str(work/f'visit{n}.png'),network],cwd=ROOT,capture_output=True,text=True,encoding='utf-8')
        if out.returncode:sys.exit(out.stderr)
        report=json.loads(out.stdout.strip().splitlines()[-1])
        return dict(counts),report['errors'],(report['light'],report['dark'])
    failures=[]
    def expect(ok,what):
        print(('ok   ' if ok else 'FAIL ')+what,flush=True)
        if not ok:failures.append(what)
    try:
        run_visits(visit,site,expect)
        if a.native:
            from private_display import private_display
            shutil.rmtree(site/'assets');shutil.copytree(built/'assets',site/'assets')
            print('natively:',flush=True)
            with private_display() as environment:
                display.update(environment)
                run_visits(visit_native,site,expect)
    finally:
        server.shutdown();print(f'cachecheck: visits and screenshots in {work}',flush=True)
    if failures:sys.exit(f'cachecheck: {len(failures)} failed')
    print('cachecheck: ok',flush=True)

def closed_port():
    """A local port nothing listens on: bound, then let go."""
    import socket
    with socket.socket() as probe:
        probe.bind(('127.0.0.1',0));return probe.getsockname()[1]

display={}

def run_visits(visit,site,expect):
    """The five visits through visit (a browser's, or the native program's, whose pictures aren't compared)."""
    first,errors,_=visit(1)
    expect(all(f'/assets/{logo}' in first for logo in LOGOS) and not errors,f'1. the first visit downloads its assets: {first}')
    second,errors,picture=visit(2)
    expect(second=={'/assets/manifest.json':1} and not errors,f'2. the second asks for the root manifest alone: {second}')
    a_,b_=(site/'assets'/LOGOS[0]),(site/'assets'/LOGOS[1]);data=a_.read_bytes();a_.write_bytes(b_.read_bytes());b_.write_bytes(data)
    gen_manifest.write(site/'assets')
    third,errors,swapped=visit(3)
    wanted={'/assets/manifest.json','/assets/sprites/manifest.json','/assets/sprites/logo/manifest.json',*(f'/assets/{logo}' for logo in LOGOS)}
    # The swap turns the black logo white: many more light pixels, fewer dark.
    expect(set(third)==wanted and all(v==1 for v in third.values()) and (swapped is None or swapped[0]>picture[0]*2) and not errors,
           f'3. after the swap, only the logos and their manifests are fetched, and the picture changes: {third}')
    fourth,errors,offline=visit(4,'offline')
    near=lambda a,b:abs(a-b)<=max(a,b)*.25
    # Offline, the browser reports each request it couldn't make (the root manifest's): that's the network, not a failed load.
    errors=[e for e in errors if 'ERR_INTERNET_DISCONNECTED' not in e]
    expect(not fourth and not errors and (offline is None or near(offline[0],swapped[0]) and near(offline[1],swapped[1])),
           f'4. offline, no asset arrives, nothing fails, and the picture is the cached one: light/dark {offline} against {swapped}; {errors}')
    (site/'assets'/LOGOS[1]).unlink();gen_manifest.write(site/'assets')
    fifth,errors,_=visit(5)
    expect(fifth.get(f'/assets/{LOGOS[1]}')==1 and any('404' in e or LOGOS[1] in e for e in errors),
           f'5. a removed logo is asked about and fails: {fifth}; the page: {errors}')

if __name__=='__main__':main()
