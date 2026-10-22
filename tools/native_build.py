"""Native builds without CMake: hxcpp compiles the adapters' C with each app (the build XML on each adapter's extern bridge), and the
C-only test tools are one compiler call each."""
import os
from pathlib import Path
import platform
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
ADAPTERS=ROOT/'src/helix/adapter'
INCLUDES=[ROOT/'vendor',ROOT/'vendor/sokol_utils']+[ADAPTERS/d for d in ('graphics/sokol/internal','host/sokol/internal','shared','audiodecoder/libsndfile/internal')]
TOOLS=ROOT/'build/native-tools'
# hxcpp's define for this machine's 64-bit architecture: ARM64 on Apple silicon (else macOS builds x86_64, run under Rosetta) and arm64 Linux.
ARCH='HXCPP_ARM64' if platform.machine().lower() in ('arm64','aarch64') else 'HXCPP_M64'

def sndfile_windows():
    """libsndfile's pinned official Windows release (dependencies.json, sndfileSDK.windows), fetched once into the user's cache and checked."""
    import hashlib,json,urllib.request,zipfile
    pin=json.loads((ROOT/'dependencies.json').read_text(encoding='utf-8'))['sndfileSDK']['windows']
    cache=Path(os.environ.get('LOCALAPPDATA') or Path.home()/'.cache')/'helix'/'tools'
    directory=cache/pin['directory']
    if not (directory/'lib/sndfile.lib').is_file():
        cache.mkdir(parents=True,exist_ok=True);archive=cache/(pin['directory']+'.zip')
        urllib.request.urlretrieve(pin['url'],archive)
        if hashlib.sha256(archive.read_bytes()).hexdigest()!=pin['sha256']:archive.unlink();raise RuntimeError('libsndfile download differs from its pin: '+pin['url'])
        with zipfile.ZipFile(archive) as z:z.extractall(cache)
        archive.unlink()
    return directory

def codec_library():
    """The libsndfile to link: on Linux the system's runtime library by path (its development symlink may be absent); on Windows the pinned
    release's import library; on macOS Homebrew's."""
    if sys.platform=='win32':return str(sndfile_windows()/'lib/sndfile.lib')
    if sys.platform=='darwin':
        prefix=subprocess.check_output(['brew','--prefix','libsndfile'],text=True, encoding='utf-8').strip()
        return prefix+'/lib/libsndfile.dylib'
    for line in subprocess.check_output(['ldconfig','-p'],text=True, encoding='utf-8').splitlines():
        if 'libsndfile.so.1 ' in line and 'x86-64' in line:return line.split('=>')[1].strip()
    raise RuntimeError('libsndfile.so.1 not found by ldconfig')

def codec_runtime():
    """The libsndfile a program needs beside it to run, or None where the system provides it (Linux, macOS)."""
    return sndfile_windows()/'bin/sndfile.dll' if sys.platform=='win32' else None

def place_runtimes(directory,sdl3=None):
    """Copies what a program built into directory loads from beside it: on Windows libsndfile's DLL and SDL3's, on macOS SDL3's framework;
    nothing where the system provides them."""
    import shutil
    for runtime in [codec_runtime()]+(sdl3.runtime if sdl3 else []):
        if runtime is None:continue
        runtime=Path(runtime)
        if runtime.is_dir():shutil.copytree(runtime,Path(directory)/runtime.name,symlinks=True,dirs_exist_ok=True)
        else:shutil.copy2(runtime,directory)

def env(sdl3=None):
    """The environment hxcpp's build reads: HeliX's root, the codec, a shared compile cache, and for an SDL3 backend the library sdl3 names
    (tools/sdl3.py's find)."""
    config=ROOT/'build/hxcpp_config.xml';config.parent.mkdir(parents=True,exist_ok=True)
    config.write_text('<xml><set name="HXCPP_COMPILE_CACHE" value="'+(ROOT/'build/hxcpp-cache').as_posix()+'"/></xml>\n', encoding='utf-8')
    extra={'HELIX_SDL3_LIBRARY':sdl3.library} if sdl3 else {}
    return dict(os.environ,HELIX_ROOT=ROOT.as_posix(),HELIX_CODEC_LIBRARY=codec_library(),HXCPP_CONFIG=str(config),**extra)

def tool(name):
    """Build one C-only test tool into build/native-tools and return its path."""
    TOOLS.mkdir(parents=True,exist_ok=True)
    flags=['cc','-std=c11','-O3','-D_POSIX_C_SOURCE=200809L']+[f'-I{d}' for d in INCLUDES]
    services=[ADAPTERS/'shared/input.c',ADAPTERS/'inputsource/sokol/internal/input_sokol.c',ADAPTERS/'inputsource/evdev/internal/gamepad_linux.c',ADAPTERS/'shared/mixer.c',ADAPTERS/'audio/sokol/internal/output_sokol.c']
    if name=='native-services-test':
        command=flags+['-UNDEBUG','-DHELIX_SERVICES_TEST','-DSOKOL_DUMMY_BACKEND',ROOT/'tests/native/native_services.c']+services+['-lm','-lpthread']
    elif name=='native-sdl3-input-test':
        import sdl3
        found=sdl3.find()
        command=flags+['-UNDEBUG',f'-I{ROOT/"vendor/sdl3"}',ROOT/'tests/native/native_sdl3_input.c',ADAPTERS/'shared/input.c',
                       ADAPTERS/'inputsource/sdl3/internal/input_sdl3.c',found.library,'-lm','-lpthread','-ldl']
    elif name=='native-audio-probe':
        command=flags+['-DNDEBUG',ROOT/'tests/native/native_audio_probe.c',ADAPTERS/'shared/mixer.c',ADAPTERS/'audio/sokol/internal/output_sokol.c','-lasound','-lm','-lpthread']
    else:raise ValueError(name)
    output=TOOLS/name
    subprocess.run(list(map(str,command))+['-o',str(output)],cwd=ROOT,check=True)
    return output
