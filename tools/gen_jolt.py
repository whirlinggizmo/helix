"""helix-jolt's committed files made from Jolt Physics: its vendored sources, hxcpp's list of them, and the WebAssembly module a page loads.

- Sources: Jolt's C++ (its Jolt/ directory's .cpp, .h and .inl files, and its LICENSE) from the release archive dependencies.json pins
  (jolt), checked against its hash, into libs/jolt/vendor/jolt.
- hxcpp's list: libs/jolt/vendor/jolt/files.xml, the file group a native build compiles, every source but the GPU compute adapters
  (Compute/DX12, Compute/VK, Compute/MTL), with the defines and flags that keep Jolt deterministic across targets.
- The module: libs/jolt/wasm/jolt.wasm, Jolt and helix-jolt's C++ (libs/jolt/src/helix/jolt/internal) built by Emscripten as a standalone
  module (no JavaScript of Emscripten's), single threaded, with the same defines. Emscripten is found at HELIX_EMSDK, EMSDK or
  ~/toolchains/emsdk. Objects are kept in build/jolt-wasm between builds.

    python3 tools/gen_jolt.py            # vendors the sources when they're missing, writes files.xml, builds jolt.wasm
    python3 tools/gen_jolt.py --vendor   # vendors the sources again, from the archive
    python3 tools/gen_jolt.py --check    # fails when files.xml or the vendored tree isn't what the pin and this tool make

Standard library only."""
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tarfile
import tempfile
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import cli  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
LIBRARY = ROOT / 'libs' / 'jolt'
VENDOR = LIBRARY / 'vendor' / 'jolt'
INTERNAL = LIBRARY / 'src' / 'helix' / 'jolt' / 'internal'
WASM = LIBRARY / 'wasm' / 'jolt.wasm'
OBJECTS = ROOT / 'build' / 'jolt-wasm'
# The defines every translation unit of Jolt and helix-jolt shares, natively and in the module: a build that differs in one makes a
# different Jolt, and the same steps would no longer produce the same bits.
DEFINES = ['JPH_CROSS_PLATFORM_DETERMINISTIC', 'JPH_OBJECT_LAYER_BITS=32', 'NDEBUG']
SKIPPED = ('Compute/DX12/', 'Compute/VK/', 'Compute/MTL/')


def pin():
    """dependencies.json's jolt entry."""
    return json.loads((ROOT / 'dependencies.json').read_text(encoding='utf-8'))['jolt']


def vendor():
    """Replaces libs/jolt/vendor/jolt with the pinned release's sources, checked against the pin's hash."""
    jolt = pin()
    with tempfile.TemporaryDirectory() as scratch:
        archive = Path(scratch) / 'jolt.tar.gz'
        print(f'gen_jolt: downloading {jolt["url"]}')
        with urllib.request.urlopen(jolt['url']) as response:
            archive.write_bytes(response.read())
        digest = hashlib.sha256(archive.read_bytes()).hexdigest()
        if digest != jolt['sha256']:
            sys.exit(f'gen_jolt: {jolt["url"]} has sha256 {digest}, not the pinned {jolt["sha256"]}')
        with tarfile.open(archive) as tar:
            tar.extractall(scratch, filter='data')
        top = next(p for p in Path(scratch).iterdir() if p.is_dir())
        if VENDOR.exists():
            shutil.rmtree(VENDOR)
        for source in sorted((top / 'Jolt').rglob('*')):
            if source.is_file() and source.suffix in ('.cpp', '.h', '.inl'):
                target = VENDOR / 'Jolt' / source.relative_to(top / 'Jolt')
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(source, target)
        shutil.copyfile(top / 'LICENSE', VENDOR / 'LICENSE')
    print(f'gen_jolt: vendored Jolt {jolt["version"]} into {VENDOR.relative_to(ROOT)}')


def tree_hash():
    """A hash of the vendored tree: each file's path and bytes, in order."""
    digest = hashlib.sha256()
    for path in sorted(p for p in (VENDOR / 'Jolt').rglob('*') if p.is_file()):
        digest.update(path.relative_to(VENDOR).as_posix().encode() + b'\0' + path.read_bytes())
    return digest.hexdigest()


def sources():
    """The Jolt sources a build compiles, relative to the vendored Jolt directory."""
    found = sorted(p.relative_to(VENDOR / 'Jolt').as_posix() for p in (VENDOR / 'Jolt').rglob('*.cpp'))
    return [s for s in found if not s.startswith(SKIPPED)]


def files_xml():
    """hxcpp's file group for Jolt and helix-jolt's C++, with the shared defines and the flags that keep floating point exact."""
    flags = [f"  <compilerflag value='-D{d}'/>" for d in DEFINES]
    lines = ['<xml>', '<!-- Written by tools/gen_jolt.py. -->', "<files id='helix-jolt' dir='${HELIX_JOLT}/vendor/jolt/Jolt'>",
             "  <compilerflag value='-I${HELIX_JOLT}/vendor/jolt'/>", "  <compilerflag value='-I${HELIX_JOLT}/src/helix/jolt/internal'/>",
             *flags, "  <compilerflag value='-std=c++17' unless='windows'/>", "  <compilerflag value='/std:c++17' if='windows'/>",
             "  <compilerflag value='-ffp-contract=off' unless='windows'/>", "  <compilerflag value='/fp:precise' if='windows'/>",
             "  <compilerflag value='-O2' unless='debug'/>"]
    lines += [f"  <file name='{s}'/>" for s in sources()]
    lines += [f"  <file name='../../../src/helix/jolt/internal/{p.name}'/>" for p in sorted(INTERNAL.glob('*.cpp'))]
    lines += ['</files>', '</xml>', '']
    return '\n'.join(lines)


def emsdk_env():
    """The environment Emscripten's emsdk_env.sh sets."""
    home = os.environ.get('HELIX_EMSDK') or os.environ.get('EMSDK') or str(Path.home() / 'toolchains/emsdk')
    script = Path(home) / 'emsdk_env.sh'
    if not script.exists():
        sys.exit(f'gen_jolt: no Emscripten at {home} (HELIX_EMSDK, EMSDK or ~/toolchains/emsdk)')
    out = subprocess.run(['bash', '-c', f'source "{script}" >/dev/null 2>&1 && env -0'], capture_output=True, check=True).stdout
    return dict(line.split('=', 1) for line in out.decode().split('\0') if '=' in line)


def build_wasm():
    """Builds jolt.wasm: each source compiled into build/jolt-wasm once and again only when it or a header changed, then linked."""
    env = emsdk_env()
    flags = ['-Oz', '-std=c++17', '-fno-exceptions', '-fno-rtti', '-ffp-contract=off', '-msimd128', '-msse4.2', f'-I{VENDOR}', f'-I{INTERNAL}'] + [f'-D{d}' for d in DEFINES]
    units = [VENDOR / 'Jolt' / s for s in sources()] + sorted(INTERNAL.glob('*.cpp'))
    headers = max(p.stat().st_mtime for p in list((VENDOR / 'Jolt').rglob('*.h')) + list(INTERNAL.glob('*.h')))
    OBJECTS.mkdir(parents=True, exist_ok=True)

    def compile_unit(unit):
        name = unit.relative_to(ROOT).as_posix().replace('/', '_') + '.o'
        target = OBJECTS / name
        if not target.exists() or target.stat().st_mtime < max(unit.stat().st_mtime, headers):
            subprocess.run(['emcc', *flags, '-c', str(unit), '-o', str(target)], env=env, check=True)
        return target

    with ThreadPoolExecutor(max(1, os.cpu_count() or 1)) as pool:
        objects = list(pool.map(compile_unit, units))
    WASM.parent.mkdir(parents=True, exist_ok=True)
    link = ['emcc', *flags, *map(str, objects), '-o', str(WASM), '--no-entry', '-sSTANDALONE_WASM', '-sFILESYSTEM=0',
            '-sALLOW_MEMORY_GROWTH=1', '-sINITIAL_MEMORY=16777216', '-sSTACK_SIZE=1048576', '-sERROR_ON_UNDEFINED_SYMBOLS=1', '-sSUPPORT_LONGJMP=0']
    subprocess.run(link, env=env, check=True)
    print(f'gen_jolt: {WASM.relative_to(ROOT)}, {WASM.stat().st_size:,} bytes')


def main():
    parser = cli.parser(__doc__)
    parser.add_argument('--vendor', action='store_true', help='vendor the sources again from the pinned archive')
    parser.add_argument('--check', action='store_true', help='fail when files.xml or the vendored tree is not current')
    args = parser.parse_args()
    if args.check:
        problems = []
        if tree_hash() != pin()['treeSha256']:
            problems.append(f'{VENDOR.relative_to(ROOT)} is not the pinned release\'s sources (python3 tools/gen_jolt.py --vendor)')
        if (VENDOR / 'files.xml').read_text(encoding='utf-8') != files_xml():
            problems.append(f'{(VENDOR / "files.xml").relative_to(ROOT)} is not current (python3 tools/gen_jolt.py)')
        for problem in problems:
            print(f'gen_jolt: {problem}')
        sys.exit(1 if problems else 0)
    if args.vendor or not (VENDOR / 'Jolt').exists():
        vendor()
        print(f'gen_jolt: tree sha256 {tree_hash()}')
    (VENDOR / 'files.xml').write_text(files_xml(), encoding='utf-8')
    build_wasm()


if __name__ == '__main__':
    main()
