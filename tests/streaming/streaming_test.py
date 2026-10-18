"""Native network streaming (StreamingTests.hx): builds the test with hxcpp over the SDL3 audio output, serves its files from a local server
slowly (32 KiB each 100 ms, the Ogg 4 KiB, so it starts well before its end on a slow machine too), and runs it under SDL3's dummy audio driver, so nothing is heard. It checks the program's own results, that each
stream started before the server sent its last byte, and the requests: one for each file kept, two for the one dropped (nothing kept).

    python3 tests/streaming/streaming_test.py    # helix.py test --native runs it"""
import array
import http.server
import io
import json
import math
import os
from pathlib import Path
import shutil
import subprocess
import sys
import threading
import time
import wave

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
PART = 32 * 1024


def tone(seconds):
    """seconds of a 440 Hz tone as a 16-bit mono 44,100 Hz WAV."""
    rate = 44100
    data = array.array('h', (round(math.sin(2 * math.pi * 440 * i / rate) * .3 * 32767) for i in range(round(rate * seconds))))
    if sys.byteorder != 'little':
        data.byteswap()
    out = io.BytesIO()
    with wave.open(out, 'wb') as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(rate)
        wav.writeframes(data.tobytes())
    return out.getvalue()


def main():
    from gen_fixtures import generate
    from native_build import ARCH, env as native_env, place_runtimes
    from pins import check_hxcpp
    import sdl3 as finder
    fixtures = generate()
    check_hxcpp()
    sdl3 = finder.find()
    build = ROOT / 'build/tests/streaming'
    subprocess.run(['haxe', '-cp', 'src', '-cp', 'tests/streaming', '-main', 'StreamingTests', '-cpp', str(build), '-dce', 'full', '-D', 'analyzer-optimize',
                    '-D', ARCH, '-D', 'HXCPP_COMPILE_THREADS=4'], cwd=ROOT, env={**native_env(sdl3), 'HAXELIB_PATH': str(ROOT / 'build/haxelib')}, check=True,
                   stdout=subprocess.DEVNULL)
    place_runtimes(build, sdl3)
    wav = tone(3)
    files = {'/assets/slow.wav': wav, '/assets/slow.ogg': (fixtures / 'stream.ogg').read_bytes(), '/assets/whole.wav': tone(.5), '/assets/dropped.wav': wav}
    counts = {}
    last = {}
    lock = threading.Lock()

    class Handler(http.server.BaseHTTPRequestHandler):
        protocol_version = 'HTTP/1.1'

        def log_message(self, *args):
            pass

        def do_GET(self):
            path = self.path.split('?')[0]
            body = files.get(path)
            with lock:
                counts[path] = counts.get(path, 0) + 1
            if body is None:
                self.send_response(404)
                self.send_header('Content-Length', '0')
                self.end_headers()
                return
            self.send_response(200)
            # whole.wav comes without a Content-Length, its end the connection's close.
            if path != '/assets/whole.wav':
                self.send_header('Content-Length', str(len(body)))
            self.send_header('Content-Type', 'audio/wav' if path.endswith('.wav') else 'audio/ogg')
            self.send_header('Cache-Control', 'max-age=3600')
            self.send_header('Connection', 'close')
            self.end_headers()
            # dropped.wav stops after three parts, its connection closed.
            end = 3 * PART if path == '/assets/dropped.wav' else len(body)
            part = 4 * 1024 if path == '/assets/slow.ogg' else PART
            try:
                for at in range(0, end, part):
                    self.wfile.write(body[at:min(at + part, end)])
                    self.wfile.flush()
                    if at + part < end:
                        time.sleep(.1)
                with lock:
                    last[path] = time.time()
            except (BrokenPipeError, ConnectionResetError):
                pass
            self.close_connection = True

    server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), Handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    cache = ROOT / 'build/tests/streaming-cache'
    shutil.rmtree(cache, ignore_errors=True)
    try:
        program = build / ('StreamingTests.exe' if os.name == 'nt' else 'StreamingTests')
        run = subprocess.run([str(program), f'http://127.0.0.1:{server.server_port}', str(cache)], cwd=ROOT, text=True, encoding='utf-8',
                             capture_output=True, env=dict(os.environ, SDL_AUDIO_DRIVER='dummy', HELIX_AUDIO='0'), timeout=120)
    finally:
        server.shutdown()
        server.server_close()
        thread.join()
    lines = run.stdout.strip().splitlines()
    result = json.loads(lines[-1]) if lines else {'passed': False, 'error': run.stderr}
    if run.returncode != 0 or not result.get('passed'):
        sys.exit(f'StreamingTests failed: {json.dumps(result)}\n{run.stderr}')
    # Each stream sounded before the server had sent its last byte.
    for name, path in (('wav', '/assets/slow.wav'), ('ogg', '/assets/slow.ogg')):
        ahead = last[path] - result[name]['startedAt']
        assert ahead > 0, f'{path} started {-ahead:.3f} s after its last byte was sent'
        result[name]['aheadOfLastByte'] = round(ahead, 3)
    assert counts == {'/assets/slow.wav': 1, '/assets/slow.ogg': 1, '/assets/whole.wav': 1, '/assets/dropped.wav': 2}, counts
    wav_result, ogg = result['wav'], result['ogg']
    print(f'StreamingTests: {result["checks"]} checks; slow.wav sounding at {wav_result["receivedAtStart"]} of {wav_result["total"]} bytes, '
          f'{wav_result["aheadOfLastByte"]} s before the server sent its last byte, played {wav_result["played"]:.2f} s of 3; slow.ogg sounding '
          f'{ogg["aheadOfLastByte"]} s before its last byte, played {ogg["played"]:.2f} s of 5 (pitch 2); dropped.wav ended at '
          f'{result["dropped"]["received"]} of {result["dropped"]["total"]} bytes ({result["dropped"]["failure"]}); requests {counts}', flush=True)


if __name__ == '__main__':
    main()
