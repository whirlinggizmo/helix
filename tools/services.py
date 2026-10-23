"""Build/run identical Haxe async service tests against an isolated local HTTP server: in the browser, and with --native BUILD natively too.

BUILD is a native build's `<config>-<backend>` or whole name (docs/CONVENTIONS.md, Build), release-sokol-gl when --native is given alone;
its backend's profile chooses the services under test: sokol-gl sokol_audio's output, sdl3-gl SDL3's (its dummy driver), the SDL3
profile's under either of its backends. The program is built in build/<build>/services."""
import argparse
import ctypes
from collections import Counter
import functools
import hashlib
import http.server
import json
import os
from pathlib import Path
import subprocess
import sys
import threading
import time
import uuid
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'build/results/services'
# The body /bytes and /concurrent send, sent slowly in 4 KiB pieces: tests/services/ServiceTests.hx's BODY_BYTES.
BODY_BYTES=128*1024

def run(args,env=None):subprocess.run(list(map(str,args)),cwd=ROOT,env=env,check=True)
def main():
 p=argparse.ArgumentParser(description=__doc__,formatter_class=argparse.RawDescriptionHelpFormatter);p.add_argument('--browser',required=True)
 p.add_argument('--native',nargs='?',const='release-sokol-gl',metavar='BUILD',help='also natively: release-sokol-gl when not given, or release-sdl3-gl, either in debug');a=p.parse_args()
 native=None
 if a.native:
  from variants import parse
  try:native=parse(a.native)
  except ValueError as error:p.error(str(error))
  if native.backend not in ('sokol-gl','sdl3-gl'):p.error(f'--native {a.native}: the services are sokol-gl\'s or sdl3-gl\'s (SDL3\'s, the same under sdl3-gpu)')
 build_dir=None
 from gen_fixtures import generate as fixtures_generate
 fixtures=fixtures_generate()
 build=ROOT/'build';run(['haxe','-cp','src','-cp','tests/services','-cp','tests/services/web','-cp','generated/shaders','-cp','generated/fonts','-main','ServiceTests','-js',build/'service-tests.js','-dce','full'])
 if native:
  from pins import check_hxcpp
  from native_build import ARCH,env as native_env,place_runtimes
  import gen_code
  sdl3=None;defines=[]
  if native.backend=='sdl3-gl':
   import sdl3 as finder
   sdl3=finder.find();defines=['-D','helix_sdl3']
  check_hxcpp();gen_code.generate(sdl_gpu=False);env=native_env(sdl3)
  build_dir=native.scratch/'services'
  config=['-debug','-D','HXCPP_CHECK_POINTER'] if native.debug else ['-dce','full','-D','analyzer-optimize']
  run(['haxe','-cp','src','-cp','tests/services','-cp','tests/services/native','-cp','generated/shaders','-cp','generated/fonts','-main','ServiceTests','-cpp',build_dir,*config,'-D',ARCH,'-D','HXCPP_COMPILE_THREADS=4',*defines],env)
  place_runtimes(build_dir,sdl3)
 counts=Counter();unchanged=Counter();lock=threading.Lock();active=0;peak=0;wav=(fixtures/'tone.wav').read_bytes();vorbis=(fixtures/'tone.ogg').read_bytes();opus=(fixtures/'tone.opus').read_bytes();stereo=(fixtures/'tone-stereo.wav').read_bytes();token=uuid.uuid4().hex
 class Handler(http.server.BaseHTTPRequestHandler):
  protocol_version='HTTP/1.1'
  def log_message(self,*args):pass
  def do_GET(self):
   nonlocal active,peak
   path=self.path.split('?')[0]
   with lock:counts[path]+=1
   status=200;slow=False;tracked=False;cache=[]
   if path=='/':body=b'<script src="/service-tests.js"></script>'
   elif path=='/service-tests.js':body=(build/'service-tests.js').read_bytes()
   elif path in ('/bytes','/concurrent'):
    body=b'x'*BODY_BYTES;slow=True
    if path=='/concurrent':
     tracked=True
     with lock:active+=1;peak=max(peak,active)
   elif path=='/stall':time.sleep(.5);body=b'stalled'
   # The fixtures are fresh for an hour, as a host marks files that rarely change: a second visit asks nothing.
   elif path in ('/assets/fixture.wav','/assets/uncached.wav'):body=wav;cache=[('Cache-Control','max-age=3600'),('ETag','"fixture"')]
   # Revalidated each visit, as a host that says no-cache: its ETag answered with 304 once the client has it.
   elif path=='/assets/revalidated.wav':
    body=wav;cache=[('Cache-Control','no-cache'),('ETag','"revalidated-1"')]
    if self.headers.get('If-None-Match')=='"revalidated-1"':
     status=304;body=b''
     with lock:unchanged[path]+=1
   elif path in ('/assets/fixture.ogg','/assets/uncached.ogg'):body=vorbis;cache=[('Cache-Control','max-age=3600')]
   elif path in ('/assets/fixture.opus','/assets/uncached.opus'):body=opus;cache=[('Cache-Control','max-age=3600')]
   elif path in ('/assets/fixture.stereo.wav','/assets/uncached.stereo.wav'):body=stereo;cache=[('Cache-Control','max-age=3600')]
   elif path=='/assets/broken.ogg':body=b'OggS'+b'broken'*20
   else:status=404;body=b'missing'
   try:
    self.send_response(status);self.send_header('Content-Length',str(len(body)));self.send_header('Content-Type','audio/wav' if path.endswith('.wav') else 'audio/ogg' if path.endswith(('.ogg','.opus')) else 'application/javascript' if path.endswith('.js') else 'text/html' if path=='/' else 'application/octet-stream');self.send_header('Connection','close')
    for name,value in cache:self.send_header(name,value)
    self.end_headers()
    if slow:
     for at in range(0,len(body),4096):
      # The client can start its next request as soon as the last bytes arrive.
      # Count incomplete bodies rather than handlers lingering after completion.
      if tracked and at+4096>=len(body):
       with lock:active-=1
       tracked=False
      self.wfile.write(body[at:at+4096]);self.wfile.flush()
      if at+4096<len(body):time.sleep(.005)
    else:self.wfile.write(body)
   except (BrokenPipeError,ConnectionResetError):pass
   finally:
    if tracked:
     with lock:active-=1
 server=http.server.ThreadingHTTPServer(('127.0.0.1',0),Handler);thread=threading.Thread(target=server.serve_forever,daemon=True);thread.start();base=f'http://127.0.0.1:{server.server_port}'
 try:
  result=json.loads(subprocess.check_output(['node',str(ROOT/'tools/service_browser.cjs'),a.browser,base+'/?db=helix-services-'+token],cwd=ROOT,text=True, encoding='utf-8'))
  assert result['runs'][0]['persisted'] is False and result['runs'][1]['persisted'] is True
  assert counts['/assets/fixture.wav']==1,dict(counts)
  assert counts['/assets/fixture.ogg']==counts['/assets/fixture.opus']==counts['/assets/fixture.stereo.wav']==1,dict(counts)
  # Downloaded on the first visit, revalidated (304, the copy kept) on the second.
  assert counts['/assets/revalidated.wav']==2 and unchanged['/assets/revalidated.wav']==1,(dict(counts),dict(unchanged))
  assert peak<=2,peak
  result['peakConcurrentTransfers']=peak
  result['requests']=dict(counts);result['singleDownloadStoredAudio']=True
  report={'browser':result}
  if native:
   counts.clear();unchanged.clear();peak=0;runs=[]
   for _ in range(2):
    child=dict(os.environ,SDL_AUDIO_DRIVER='dummy') if native.backend=='sdl3-gl' else None
    program=build_dir/(('ServiceTests-debug' if native.debug else 'ServiceTests')+('.exe' if os.name=='nt' else ''))
    ran=subprocess.run([str(program),base,str(build/'services-cache'/token)],cwd=ROOT,text=True, encoding='utf-8',capture_output=True,env=child)
    if ran.returncode!=0:
     sys.stderr.write(ran.stdout+ran.stderr);raise SystemExit(f"native ServiceTests ({native}) exited {ran.returncode}")
    output=ran.stdout
    value=json.loads(output.strip().splitlines()[-1]);assert value['passed'];runs.append(value)
   assert not runs[0]['persisted'] and runs[1]['persisted']
   assert counts['/assets/fixture.wav']==1,dict(counts)
   assert counts['/assets/fixture.ogg']==counts['/assets/fixture.opus']==counts['/assets/fixture.stereo.wav']==1,dict(counts)
   assert counts['/assets/revalidated.wav']==2 and unchanged['/assets/revalidated.wav']==1,(dict(counts),dict(unchanged))
   assert peak<=2,peak
   from native_build import codec_library,codec_runtime
   # The library the program loaded: on Windows the DLL (codec_library is the import library linked), elsewhere the one linked.
   library=ctypes.CDLL(str(codec_runtime() or codec_library()));library.sf_version_string.restype=ctypes.c_char_p
   report['native']={'build':native.name,'decoder':library.sf_version_string().decode(),'peakConcurrentTransfers':peak,'passed':True,'runs':runs,'requests':dict(counts),'singleDownloadStoredAudio':True}
  report['sources']={str(file.relative_to(ROOT)):hashlib.sha256(file.read_bytes()).hexdigest() for group in ['src','tests'] for file in sorted((ROOT/group).rglob('*.hx'))}
  for source in ('src/helix/adapter/shared/mixer.c','src/helix/adapter/audio/sokol/internal/output_sokol.c'):report['sources'][source]=hashlib.sha256((ROOT/source).read_bytes()).hexdigest()
  report['sources']['src/helix/adapter/audiodecoder/libsndfile/internal/codec.c']=hashlib.sha256((ROOT/'src/helix/adapter/audiodecoder/libsndfile/internal/codec.c').read_bytes()).hexdigest()
  report['sources']['vendor/sndfile/sndfile.h']=hashlib.sha256((ROOT/'vendor/sndfile/sndfile.h').read_bytes()).hexdigest()
  report['audioFormats']=['PCM16 mono WAV','PCM8 stereo 22.05 kHz WAV','Ogg/Vorbis','Ogg/Opus'];report['encoder']=json.loads((fixtures/'encoder.json').read_text(encoding='utf-8'))
  OUT.mkdir(parents=True,exist_ok=True);(OUT/'service-checks.json').write_text(json.dumps(report,indent=2)+'\n', encoding='utf-8');print(json.dumps({target:report[target]['runs'] for target in ['browser','native'] if target in report}))
 finally:server.shutdown();server.server_close();thread.join()
if __name__=='__main__':main()
