"""Native builds: hxcpp compiles the adapters' C with each program (the build XML on each adapter's extern bridge), and the platform's
C-only tests (libs/platform/tests/native) are built by CMake from their CMakeLists.txt, with GCC or Clang, or MSVC on Windows."""
import os
from pathlib import Path
import platform
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
PLATFORM_ADAPTERS=ROOT/'libs/platform/src/helix/platform/adapters'
TESTS=ROOT/'build/native-tests'
# hxcpp's define for this machine's 64-bit architecture: ARM64 on Apple silicon (else macOS builds x86_64, run under Rosetta) and arm64 Linux.
ARCH='HXCPP_ARM64' if platform.machine().lower() in ('arm64','aarch64') else 'HXCPP_M64'

def place_runtimes(directory,sdl3=None):
    """Copies what a program built into directory loads from beside it: on Windows SDL3's DLL, on macOS its framework; nothing on Linux,
    where SDL3 is linked statically or is the system's."""
    import shutil
    for runtime in (sdl3.runtime if sdl3 else []):
        runtime=Path(runtime)
        if runtime.is_dir():shutil.copytree(runtime,Path(directory)/runtime.name,symlinks=True,dirs_exist_ok=True)
        else:shutil.copy2(runtime,directory)

def env(sdl3=None):
    """The environment hxcpp's build reads: the platform's root, a shared compile cache, and for an SDL3 backend the library sdl3 names
    (tools/sdl3.py's find)."""
    config=ROOT/'build/hxcpp_config.xml';config.parent.mkdir(parents=True,exist_ok=True)
    config.write_text('<xml><set name="HXCPP_COMPILE_CACHE" value="'+(ROOT/'build/hxcpp-cache').as_posix()+'"/></xml>\n', encoding='utf-8')
    extra={'HELIX_SDL3_LIBRARY':sdl3.library} if sdl3 else {}
    return dict(os.environ,HELIX_PLATFORM=(ROOT/'libs/platform').as_posix(),HXCPP_CONFIG=str(config),**extra)

def tool(name):
    """Build one of the platform's C-only tests with CMake (configured once into build/native-tests, against the SDL3 tools/sdl3.py finds)
    and return its path."""
    import sdl3
    found=sdl3.find()
    subprocess.run(['cmake','-S',str(ROOT/'libs/platform/tests/native'),'-B',str(TESTS),f'-DHELIX_ROOT={ROOT.as_posix()}',
                    f'-DSDL3_LIBRARY={Path(found.library).as_posix()}','-DSDL3_RUNTIME='+';'.join(Path(r).as_posix() for r in found.runtime)],
                   cwd=ROOT,check=True,stdout=subprocess.DEVNULL)
    subprocess.run(['cmake','--build',str(TESTS),'--config','Release','--target',name],cwd=ROOT,check=True,stdout=subprocess.DEVNULL)
    return TESTS/'bin'/(name+'.exe' if sys.platform=='win32' else name)

if __name__ == '__main__':
    import cli
    cli.module(__doc__)
