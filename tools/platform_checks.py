#!/usr/bin/env python3
"""Checks helix-platform on the GPU, its audio and its window with the library alone: its examples (libs/platform/examples/<name>), its graphics
tests (libs/platform/tests/graphics), its audio tests (libs/platform/tests/audio, natively on SDL3's dummy audio driver, which mixes in time, and in a
page Chromium lets start audio without a gesture, muted), its window tests (libs/platform/tests/window, each request's answer listed: the window's, the mouse's lock, the clipboard's) and its HTTP tests (libs/platform/tests/http, against a server started here that ends bodies early). Each is built from its own hxml files, as a reader builds it, and run natively on a private display (Linux),
each native build it has (GL, and SDL_GPU where it has build-native-gpu.hxml), and in Chromium, headless by default. An example runs 60 frames and
the page's screenshot is checked against what it says it draws (its check.json: points and the colors expected there, each within a
tolerance per channel); the graphics and audio tests check their own results, and say how it went. Exits 1 on any failure.

    python3 tools/platform_checks.py --browser BROWSER [--native | --page] [--headless | --headed] [NAME ...]

BROWSER is a Chromium to run (Edge on Windows), or "" for Playwright's own. The names are examples', "graphics", "audio", "window" and "http"; they default
to all of them. --native or --page runs that kind alone (both by default). --headed runs them on this machine's own display, the native
programs' windows and the browser's, instead of a private display and headless Chromium, for a machine kept for checks (Windows over
tools/remote_windows.py --headed): never on a display someone is using. --headless, the default, says so."""
import json
import os
import struct
import subprocess
import sys
import zlib
from contextlib import nullcontext
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXAMPLES = ROOT / 'libs/platform/examples'
GRAPHICS = ROOT / 'libs/platform/tests/graphics'
AUDIO = ROOT / 'libs/platform/tests/audio'
WINDOW = ROOT / 'libs/platform/tests/window'
HTTP = ROOT / 'libs/platform/tests/http'
FRAMES = 60
# Run on this machine's own display rather than a private display and headless Chromium (--headed): for a machine kept for checks, such
# as Windows over tools/remote_windows.py --headed. A real display paces its frames, so a native run lasts at most PACED_FRAMES.
HEADED = False

# The kinds of program run (--native, --page): both by default.
NATIVE = True
PAGE = True
PACED_FRAMES = 600
sys.path.insert(0, str(ROOT / 'tools'))


def png_pixels(path):
    """(width, height, pixel) for an 8-bit RGB or RGBA non-interlaced PNG: pixel(x, y) is (r, g, b)."""
    data = path.read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n', f'{path} is not a PNG'
    at, idat, header = 8, b'', None
    while at < len(data):
        length, kind = struct.unpack('>I4s', data[at:at + 8])
        body = data[at + 8:at + 8 + length]
        if kind == b'IHDR':
            header = struct.unpack('>IIBBBBB', body)
        elif kind == b'IDAT':
            idat += body
        at += 12 + length
    width, height, depth, color, _, _, interlace = header
    assert depth == 8 and color in (2, 6) and interlace == 0, f'{path}: only 8-bit RGB/RGBA non-interlaced PNGs are read'
    channels = 3 if color == 2 else 4
    stride = width * channels
    raw = zlib.decompress(idat)
    rows, previous = [], bytearray(stride)
    for y in range(height):
        start = y * (stride + 1)
        kind, line = raw[start], bytearray(raw[start + 1:start + 1 + stride])
        for i in range(stride):
            a = line[i - channels] if i >= channels else 0
            b = previous[i]
            c = previous[i - channels] if i >= channels else 0
            if kind == 1:
                line[i] = (line[i] + a) & 255
            elif kind == 2:
                line[i] = (line[i] + b) & 255
            elif kind == 3:
                line[i] = (line[i] + (a + b) // 2) & 255
            elif kind == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                line[i] = (line[i] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        rows.append(line)
        previous = line
    return width, height, lambda x, y: tuple(rows[y][x * channels:x * channels + 3])


def check_pixels(screenshot, expectations):
    """The problems with screenshot (a PNG) against expectations ({points: [{x, y, color: [r, g, b], tolerance}]})."""
    _, _, pixel = png_pixels(screenshot)
    problems = []
    for point in expectations['points']:
        found = pixel(point['x'], point['y'])
        tolerance = point.get('tolerance', 3)
        if any(abs(f - e) > tolerance for f, e in zip(found, point['color'])):
            problems.append(f'at {point["x"]},{point["y"]}: {list(found)}, expected {point["color"]} within {tolerance}')
    return problems


def build(directory, hxml, env):
    subprocess.run(['haxe', hxml], cwd=directory, env=env, check=True)


def run(name, directory, main, browser, native_run, page_run, native_frames=FRAMES, native_extra=None, query='', expected_errors=(), site=None,
        native_args=None, page_quits=True):
    """Builds and runs one program both ways, in directory with its main class main, the page in browser: native_run(label, completed) and
    page_run(printed, screenshot) say what's wrong with each run, as a list of problems. native_frames is how many frames a native run
    lasts, which a private display doesn't pace; native_extra what a native run's environment adds; native_args(label) the arguments a
    native run adds; query what the page's query adds
    (tools/page_check.cjs reads safeArea from it); expected_errors the console errors the page is meant to cause (each named by a part of it);
    site the URL the page is opened at, or None to have tools/page_check.cjs serve its web directory; page_quits whether the page is
    given quit_after_frame, which a program clearing its canvas as it quits (helix-raylib's CloseWindow) isn't, as the screenshot is
    taken after a second of frames. The problems found."""
    import pins
    from native_build import env as native_env
    env = pins.use_haxelib()
    build(directory, 'build-web.hxml', env)
    problems = []
    if not NATIVE:
        pass
    elif sys.platform.startswith('linux') or HEADED:
        import sdl3 as finder
        from native_build import place_runtimes
        from private_display import private_display
        pins.check_hxcpp()
        found = finder.find()
        native = native_env(found)
        env.update({k: native[k] for k in ('HELIX_PLATFORM', 'HXCPP_CONFIG', 'HELIX_SDL3_LIBRARY')})
        frames = min(native_frames, PACED_FRAMES) if HEADED else native_frames
        for hxml, output, label in (('build-native.hxml', 'native', 'GL'), ('build-native-gpu.hxml', 'native-gpu', 'SDL_GPU')):
            if not (directory / hxml).is_file():
                continue
            build(directory, hxml, env)
            place_runtimes(directory / output, found)
            program = directory / output / (main + '.exe' if sys.platform == 'win32' else main)
            with (nullcontext(dict(os.environ)) if HEADED else private_display()) as display:
                ran = subprocess.run([str(program), f'--quit_after_frame={frames}'] + (native_args(label) if native_args else []), cwd=directory, env=dict(display, **(native_extra or {}), SDL_AUDIO_DRIVER='dummy'), capture_output=True, text=True, encoding='utf-8', timeout=300)
            problems += [f'native {label}: {p}' for p in native_run(label, ran)]
    else:
        print(f'{name}: native runs skipped here (a private display needs Linux; --headed runs them on this machine\'s own)', flush=True)
    if not PAGE:
        return problems
    out = ROOT / 'build/results/platform' / name
    out.mkdir(parents=True, exist_ok=True)
    screenshot = out / 'web.png'
    browser_env = {k: v for k, v in os.environ.items() if k not in ('VK_DRIVER_FILES', 'VK_ICD_FILENAMES')}
    ran = subprocess.run(['node', ROOT / 'tools/page_check.cjs', '--headed' if HEADED else '--headless', browser, site or str(directory / 'web'), f'?quit_after_frame={FRAMES}{query}' if page_quits else '?' + query.lstrip('&'), str(screenshot)], cwd=ROOT, env=browser_env, capture_output=True, text=True, encoding='utf-8')
    if ran.returncode:
        problems.append(f'browser run failed\n{ran.stdout}{ran.stderr}')
    else:
        printed = json.loads(ran.stdout)
        printed['errors'] = [e for e in printed['errors'] if not any(part in e for part in expected_errors)]
        if printed['errors']:
            problems.append(f'page errors: {printed["errors"]}')
        else:
            problems += [f'page: {p}' for p in page_run(printed, screenshot)]
    return problems


def example(name, browser):
    """Builds and runs one example both ways; the problems found."""
    directory = EXAMPLES / name
    expected = json.loads((directory / 'check.json').read_text(encoding='utf-8'))

    def native_run(label, ran):
        if ran.returncode:
            return [f'exited {ran.returncode}\n{ran.stdout}{ran.stderr}']
        print(f'{name}: native {label} ran {FRAMES} frames', flush=True)
        return []

    def page_run(printed, screenshot):
        found = check_pixels(screenshot, expected)
        if not found:
            print(f'{name}: the page ran {FRAMES} frames, {len(expected["points"])} points checked', flush=True)
        return found

    return run(name, directory, 'Main', browser, native_run, page_run)


def tests(name, directory, main, page, browser, backends=True, native_extra=None, query='', expected_errors=(), site=None):
    """Builds and runs a test program both ways (one that ends with {passed, checks, failures}), the page's run on page, natively on
    each graphics backend it builds for (backends) or none, native_extra, query, expected_errors and site as run's; the problems found."""

    def outcome(where, result):
        if result is None:
            return ['no result']
        for answer in result.get('answers', []):
            print(f'{name}: {where}: {answer}', flush=True)
        if not result['passed']:
            return result['failures']
        print(f'{name}: {result["checks"]} checks passed {where}', flush=True)
        return []

    def native_run(label, ran):
        lines = [l for l in ran.stdout.splitlines() if l.startswith('{')]
        if not lines:
            return [f'exited {ran.returncode} with no result\n{ran.stdout}{ran.stderr}']
        found = outcome(f'natively on {label}' if backends else 'natively', json.loads(lines[-1]))
        return found or ([f'exited {ran.returncode}\n{ran.stderr}'] if ran.returncode else [])

    return run(name, directory, main, browser, native_run, lambda printed, _: outcome(f'in the page ({page})', printed['result']),
               native_extra=native_extra, query=query, expected_errors=expected_errors, site=site)


def graphics(browser):
    """Builds and runs the graphics tests both ways; the problems found."""
    return tests('graphics', GRAPHICS, 'GraphicsTests', 'WebGL2', browser)


def audio(browser):
    """Builds and runs the audio tests both ways; the problems found."""
    return tests('audio', AUDIO, 'AudioTests', 'Web Audio', browser, backends=False)


def window(browser):
    """Builds and runs the window tests both ways, the page's safe area emulated as a phone's with a notch; the problems found."""
    return tests('window', WINDOW, 'WindowTests', 'the page', browser, backends=False, query='&safeArea=47,0,34,0')


class ShortBodies:
    """A test server on 127.0.0.1, at ports the OS picks, on threads of its own: /whole and /chunked send a 1000-byte body whole, as its
    Content-Length says and in chunks, and /trickle in ten parts 0.3 seconds apart; /short closes after 100 bytes of the 1000 its
    Content-Length promises, /gzip-short halfway through a gzip body its Content-Length gives, and /cut-chunk after 100 bytes of a
    1000-byte chunk. /closed closes with no bytes, /cut-status partway through the status line, and /cut-head partway through the
    headers. /stall sends its head and 100 bytes, then nothing; /silent never answers. A path ending -timed adds Timing-Allow-Origin.

    It serves the HTTP tests' page from url (/ and /app.js), and the same answers from a second port, other, another origin to the page.
    unaccepted is a URL whose connection is never taken: its port listens, its queue filled, and nothing accepts. Any page may read it
    (Access-Control-Allow-Origin). Stopped by close(), never by a search for it, which also ends each answer still waiting."""

    def __init__(self):
        import gzip
        import http.server
        import socket
        import threading
        body = bytes(i * 7 & 255 for i in range(1000))
        packed = gzip.compress(body)
        page = {'/': ('text/html', HTTP / 'web/index.html'), '/app.js': ('text/javascript', HTTP / 'web/app.js')}
        self.stopping = stopping = threading.Event()

        class Handler(http.server.BaseHTTPRequestHandler):
            protocol_version = 'HTTP/1.1'

            def log_message(self, *args):
                pass

            def do_GET(self):
                path = self.path.split('?')[0]
                self.close_connection = True
                head = 'HTTP/1.1 200 OK\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\nCache-Control: no-store\r\n'
                if path.endswith('-timed'):
                    path = path[:-len('-timed')]
                    head += 'Timing-Allow-Origin: *\r\n'
                send = self.wfile.write
                if path in page:
                    kind, file = page[path]
                    data = file.read_bytes()
                    send(f'{head}Content-Type: {kind}\r\nContent-Length: {len(data)}\r\n\r\n'.encode() + data)
                elif path == '/whole':
                    send(f'{head}Content-Length: 1000\r\n\r\n'.encode() + body)
                elif path == '/trickle':
                    send(f'{head}Content-Length: 1000\r\n\r\n'.encode())
                    for at in range(0, 1000, 100):
                        self.wfile.flush()
                        if stopping.wait(0.3):
                            break
                        send(body[at:at + 100])
                elif path == '/short':
                    send(f'{head}Content-Length: 1000\r\n\r\n'.encode() + body[:100])
                elif path == '/gzip-short':
                    send(f'{head}Content-Encoding: gzip\r\nContent-Length: {len(packed)}\r\n\r\n'.encode() + packed[:len(packed) // 2])
                elif path == '/chunked':
                    send(f'{head}Transfer-Encoding: chunked\r\n\r\n'.encode() + b'1f4\r\n' + body[:500] + b'\r\n1f4\r\n' + body[500:] +
                         b'\r\n0\r\n\r\n')
                elif path == '/cut-chunk':
                    send(f'{head}Transfer-Encoding: chunked\r\n\r\n'.encode() + b'3e8\r\n' + body[:100])
                elif path == '/closed':
                    pass
                elif path == '/cut-status':
                    send(b'HTTP/1.1 20')
                elif path == '/cut-head':
                    send(f'{head}Content-Length: 1000\r\nX-Cu'.encode())
                elif path == '/stall':
                    send(f'{head}Content-Length: 1000\r\n\r\n'.encode() + body[:100])
                    self.wfile.flush()
                    stopping.wait(30)
                elif path == '/silent':
                    stopping.wait(30)
                else:
                    send(f'HTTP/1.1 404 Not Found\r\nAccess-Control-Allow-Origin: *\r\nContent-Length: 0\r\n\r\n'.encode())
                self.wfile.flush()

        class Server(http.server.ThreadingHTTPServer):
            # Python's queue of 5 drops a connection when the tests ask all at once, and its SYN is sent again a second later, as late
            # as a short idle timeout.
            request_queue_size = 64

        self.servers = [Server(('127.0.0.1', 0), Handler) for _ in range(2)]
        self.url, self.other = (f'http://127.0.0.1:{s.server_address[1]}/' for s in self.servers)
        for server in self.servers:
            threading.Thread(target=server.serve_forever, daemon=True).start()
        # A listening socket that never accepts: once its queue is full, the system drops each new connection's SYN.
        self.listener = socket.socket()
        self.listener.bind(('127.0.0.1', 0))
        self.listener.listen(0)
        self.unaccepted = f'http://127.0.0.1:{self.listener.getsockname()[1]}/'
        self.fillers = []
        for _ in range(3):
            filler = socket.socket()
            filler.setblocking(False)
            filler.connect_ex(self.listener.getsockname())
            self.fillers.append(filler)

    def close(self):
        self.stopping.set()
        for server in self.servers:
            server.shutdown()
            server.server_close()
        for s in self.fillers + [self.listener]:
            s.close()


def http(browser):
    """Builds and runs the HTTP tests both ways against a ShortBodies server, the page served from it; the problems found."""
    import urllib.parse
    server = ShortBodies()
    try:
        return tests('http', HTTP, 'HttpTests', 'fetch', browser, backends=False,
                     native_extra={'HELIX_SERVER': server.url, 'HELIX_UNACCEPTED': server.unaccepted},
                     query=''.join(f'&{k}=' + urllib.parse.quote(v, safe='') for k, v in
                                   (('server', server.url), ('other', server.other), ('unaccepted', server.unaccepted))),
                     site=server.url,
                     # The browser reports each body ended early in the console, as it should, and each head: one with no bytes as
                     # empty, and a cut status line as a response it can't read. On Windows the connection never taken is refused, the
                     # listener's queue full (the console's message doesn't name the URL, so it's expected of the whole check there).
                     expected_errors=('ERR_CONTENT_LENGTH_MISMATCH', 'ERR_INCOMPLETE_CHUNKED_ENCODING', 'ERR_EMPTY_RESPONSE',
                                      'net::ERR_FAILED') + (('net::ERR_CONNECTION_REFUSED',) if sys.platform == 'win32' else ()))
    finally:
        server.close()


def main():
    import cli
    parser = cli.parser(__doc__)
    parser.add_argument('--browser', required=True)
    cli.runs(parser)
    parser.add_argument('names', nargs='*')
    a = parser.parse_args()
    global HEADED, NATIVE, PAGE
    HEADED = a.headed
    NATIVE, PAGE = cli.targets(a)
    names = a.names or sorted(p.parent.name for p in EXAMPLES.glob('*/Main.hx')) + ['graphics', 'audio', 'window', 'http']
    failed = False
    for name in names:
        check = {'graphics': graphics, 'audio': audio, 'window': window, 'http': http}.get(name, lambda browser: example(name, browser))
        for problem in check(a.browser):
            failed = True
            print(f'{name}: {problem}', flush=True)
    print(f'platform checks: {"FAILED" if failed else "ok"} ({", ".join(names)})')
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
