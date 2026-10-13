"""Native builds without CMake: hxcpp compiles the adapters' C with each app (SokolNativeBuild.hx), and the
C-only test tools are one compiler call each."""
import os
from pathlib import Path
import subprocess

ROOT=Path(__file__).resolve().parents[1]
ADAPTERS=ROOT/'src/helix/adapters'
INCLUDES=[ROOT/'vendor',ROOT/'vendor/sokol_utils']+[ADAPTERS/d for d in ('graphics/sokol/internal','host/sokol/internal','input/sokol/internal','input/evdev/internal','audio/sokol/internal','audio/libsndfile/internal')]
TOOLS=ROOT/'build/native-tools'

def codec_library():
    """The system libsndfile's runtime library: its development symlink may be absent, so link the .so.1 by path."""
    for line in subprocess.check_output(['ldconfig','-p'],text=True).splitlines():
        if 'libsndfile.so.1 ' in line and 'x86-64' in line:return line.split('=>')[1].strip()
    raise RuntimeError('libsndfile.so.1 not found by ldconfig')

def env(shader_dir):
    """The environment hxcpp's build reads: HeliX's root, the app's generated shader, the codec, and a shared compile cache."""
    config=ROOT/'build/hxcpp_config.xml';config.parent.mkdir(parents=True,exist_ok=True)
    config.write_text('<xml><set name="HXCPP_COMPILE_CACHE" value="'+(ROOT/'build/hxcpp-cache').as_posix()+'"/></xml>\n')
    return dict(os.environ,HELIX_ROOT=ROOT.as_posix(),HELIX_SHADER_DIR=Path(shader_dir).resolve().as_posix(),HELIX_CODEC_LIBRARY=codec_library(),HXCPP_CONFIG=str(config))

def tool(name):
    """Build one C-only test tool into build/native-tools and return its path."""
    TOOLS.mkdir(parents=True,exist_ok=True)
    flags=['cc','-std=c11','-O3','-D_POSIX_C_SOURCE=200809L']+[f'-I{d}' for d in INCLUDES]
    services=[ADAPTERS/'input/sokol/internal/input.c',ADAPTERS/'input/evdev/internal/gamepad_linux.c',ADAPTERS/'audio/sokol/internal/audio.c']
    if name=='native-services-test':
        command=flags+['-UNDEBUG','-DHELIX_SERVICES_TEST','-DSOKOL_DUMMY_BACKEND',ROOT/'tests/native/native_services.c']+services+['-lm','-lpthread']
    elif name=='native-audio-probe':
        command=flags+['-DNDEBUG',ROOT/'tests/native/native_audio_probe.c',ADAPTERS/'audio/sokol/internal/audio.c','-lasound','-lm','-lpthread']
    elif name=='native-graphics-call-audit':
        # Test-only GL call interposer; excluded from native/browser delivery and all timing.
        command=flags+['-DNDEBUG','-shared','-fPIC',ROOT/'tests/native/graphics_calls.c','-ldl'];name='libnative-graphics-call-audit.so'
    else:raise ValueError(name)
    output=TOOLS/name
    subprocess.run(list(map(str,command))+['-o',str(output)],cwd=ROOT,check=True)
    return output
