package helix.adapters.internal;

/** The native adapters' C, compiled by hxcpp with the app, and the system libraries each desktop links: no other build system. On Linux, X11,
	GL, ALSA and the system libsndfile, with evdev gamepads; on Windows (MSVC, hxcpp's compiler there), the Win32 and GL libraries and
	libsndfile's pinned release, with XInput gamepads; on macOS, Cocoa, OpenGL and AudioToolbox and Homebrew's libsndfile, without gamepads, the host compiled as Objective-C (host_macos.m:
	hxcpp picks a file's language by its extension).
	HELIX_CODEC_LIBRARY is the libsndfile to link, as tools/native_build.py finds it. */
@:buildXml('<files id="helix-adapters" dir="${HELIX_ROOT}/src/helix/adapters">
 <compilerflag value="-I${HELIX_ROOT}/vendor"/><compilerflag value="-I${HELIX_ROOT}/vendor/sokol_utils"/><compilerflag value="-I${HELIX_ROOT}/vendor/stb"/>
 <compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/internal"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/imagedecoder/stb/internal"/>
 <compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/graphics/sokol/internal"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/host/sokol/internal"/>
 <compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/inputsource/sokol/internal"/>
 <compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/audio/sokol/internal"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/audiodecoder/libsndfile/internal"/>
 <compilerflag value="-DNDEBUG"/>
 <compilerflag value="-O2" if="windows"/><compilerflag value="-O3" unless="windows"/>
 <compilerflag value="-D_POSIX_C_SOURCE=200809L" if="linux"/>
 <!-- hxcpp rebuilds an object when its source changes; these make a changed header (vendored or internal) rebuild them too. -->
 <depend name="${HELIX_ROOT}/vendor/sokol_app.h"/><depend name="${HELIX_ROOT}/vendor/sokol_gfx.h"/><depend name="${HELIX_ROOT}/vendor/sokol_glue.h"/>
 <depend name="${HELIX_ROOT}/vendor/sokol_log.h"/><depend name="${HELIX_ROOT}/vendor/sokol_audio.h"/><depend name="${HELIX_ROOT}/vendor/sokol_utils/sokol_app_utils.h"/>
 <depend name="${HELIX_ROOT}/vendor/stb/stb_image.h"/><depend name="${HELIX_ROOT}/src/helix/adapters/internal/lock.h"/>
 <depend name="${HELIX_ROOT}/src/helix/adapters/imagedecoder/stb/internal/images.h"/><depend name="${HELIX_ROOT}/src/helix/adapters/host/sokol/internal/host.h"/><depend name="${HELIX_ROOT}/src/helix/adapters/host/sokol/internal/host.c"/>
 <depend name="${HELIX_ROOT}/src/helix/adapters/graphics/sokol/internal/graphics.h"/><depend name="${HELIX_ROOT}/src/helix/adapters/inputsource/sokol/internal/input.h"/>
 <depend name="${HELIX_ROOT}/src/helix/adapters/inputsource/sokol/internal/gamepad.h"/><depend name="${HELIX_ROOT}/src/helix/adapters/audio/sokol/internal/audio.h"/>
 <depend name="${HELIX_ROOT}/src/helix/adapters/audiodecoder/libsndfile/internal/codec.h"/>
 <file name="host/sokol/internal/host.c" unless="macos"/><file name="host/sokol/internal/host_macos.m" if="macos"/><file name="graphics/sokol/internal/graphics.c"/><file name="audiodecoder/libsndfile/internal/codec.c"/>
 <file name="inputsource/sokol/internal/input.c"/><file name="audio/sokol/internal/audio.c"/><file name="imagedecoder/stb/internal/images.c"/>
 <file name="inputsource/evdev/internal/gamepad_linux.c" if="linux"/>
 <file name="inputsource/xinput/internal/gamepad_windows.c" if="windows"/>
 <file name="inputsource/sokol/internal/gamepad_none.c" if="macos"/>
</files>
<files id="haxe"><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/internal"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/imagedecoder/stb/internal"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/graphics/sokol/internal"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/host/sokol/internal"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/inputsource/sokol/internal"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/audio/sokol/internal"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/audiodecoder/libsndfile/internal"/></files>
<target id="haxe">
 <files id="helix-adapters"/>
 <lib name="${HELIX_CODEC_LIBRARY}"/>
 <section if="linux"><lib name="-lX11"/><lib name="-lXrandr"/><lib name="-lXi"/><lib name="-lXcursor"/><lib name="-lGL"/><lib name="-lasound"/><lib name="-ldl"/><lib name="-lpthread"/></section>
 <section if="windows"><lib name="opengl32.lib"/><lib name="gdi32.lib"/><lib name="user32.lib"/><lib name="kernel32.lib"/><lib name="shell32.lib"/><lib name="ole32.lib"/></section>
 <section if="macos"><vflag name="-framework" value="Cocoa"/><vflag name="-framework" value="QuartzCore"/><vflag name="-framework" value="OpenGL"/><vflag name="-framework" value="AudioToolbox"/></section>
</target>')
extern class SokolNativeBuild {}
