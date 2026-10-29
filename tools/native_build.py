"""Native builds without CMake: hxcpp compiles the adapters' C with each program (the build XML on each adapter's extern bridge), and
the platform's C-only test tools (platform/tests/native) are one compiler call each."""
import os
from pathlib import Path
import platform
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
PLATFORM_ADAPTERS=ROOT/'platform/src/helix/platform/adapters'
INCLUDES=[ROOT/'platform/vendor']+[PLATFORM_ADAPTERS/d for d in ('graphics/sokol/internal','shared')]
# SDL3_mixer's sources and the decoders the platform builds it with (Sdl3MixerBridge's build XML says the same).
MIXER=ROOT/'platform/vendor/sdl3_mixer'
MIXER_DECODERS=['-DDECODER_WAV','-DDECODER_OGGVORBIS_STB','-DDECODER_MP3_DRMP3','-DDECODER_FLAC_DRFLAC']
TOOLS=ROOT/'build/native-tools'
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
    return dict(os.environ,HELIX_PLATFORM=(ROOT/'platform').as_posix(),HXCPP_CONFIG=str(config),**extra)

def tool(name):
    """Build one C-only test tool into build/native-tools and return its path."""
    TOOLS.mkdir(parents=True,exist_ok=True)
    flags=['cc','-std=c11','-O3','-D_POSIX_C_SOURCE=200809L']+[f'-I{d}' for d in INCLUDES]
    if name in ('native-sdl3-events-test','native-sdl3mixer-audio-test','native-sdl3mixer-device-probe'):
        import sdl3
        found=sdl3.find()
        sdl=[f'-I{ROOT/"platform/vendor/sdl3"}',found.library,'-lm','-lpthread','-ldl']
        if name=='native-sdl3-events-test':
            command=flags+['-UNDEBUG',f'-I{PLATFORM_ADAPTERS/"shared/sdl3"}',f'-I{PLATFORM_ADAPTERS/"events/sdl3/internal"}',
                           ROOT/'platform/tests/native/native_sdl3_events.c',PLATFORM_ADAPTERS/'events/sdl3/internal/events_sdl3.c',
                           PLATFORM_ADAPTERS/'shared/sdl3/sdl3.c']+sdl
        else:
            audio=PLATFORM_ADAPTERS/'audio/sdl3mixer/internal'
            test='native_sdl3mixer_audio.c' if name=='native-sdl3mixer-audio-test' else 'native_sdl3mixer_device.c'
            command=flags+['-UNDEBUG',*MIXER_DECODERS,f'-I{MIXER/"include"}',f'-I{MIXER/"src"}',f'-I{audio}',ROOT/'platform/tests/native'/test,
                           audio/'audio_sdl3mixer.c',*sorted((MIXER/'src').glob('*.c'))]+sdl
    else:raise ValueError(name)
    output=TOOLS/name
    subprocess.run(list(map(str,command))+['-o',str(output)],cwd=ROOT,check=True)
    return output


if __name__ == '__main__':
    import cli
    cli.module(__doc__)
