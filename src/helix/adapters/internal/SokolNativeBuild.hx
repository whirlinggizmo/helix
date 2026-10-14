package helix.adapters.internal;

/** Internal Linux Sokol build integration shared by the subsystem externs: hxcpp compiles the adapters' C with the app,
	and links the system libraries. */
@:buildXml('<files id="helix-adapters" dir="${HELIX_ROOT}/src/helix/adapters">
 <compilerflag value="-I${HELIX_ROOT}/vendor"/><compilerflag value="-I${HELIX_ROOT}/vendor/sokol_utils"/><compilerflag value="-I${HELIX_ROOT}/vendor/stb"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/images/stb/internal"/>
 <compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/graphics/sokol/internal"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/host/sokol/internal"/>
 <compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/input/sokol/internal"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/input/evdev/internal"/>
 <compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/audio/sokol/internal"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/audio/libsndfile/internal"/>
 <compilerflag value="-D_POSIX_C_SOURCE=200809L"/><compilerflag value="-DNDEBUG"/><compilerflag value="-O3"/>
 <!-- hxcpp rebuilds an object when its source changes; these make a changed header (vendored or internal) rebuild them too. -->
 <depend name="${HELIX_ROOT}/vendor/sokol_app.h"/><depend name="${HELIX_ROOT}/vendor/sokol_gfx.h"/><depend name="${HELIX_ROOT}/vendor/sokol_glue.h"/><depend name="${HELIX_ROOT}/vendor/sokol_log.h"/><depend name="${HELIX_ROOT}/vendor/sokol_audio.h"/><depend name="${HELIX_ROOT}/vendor/sokol_utils/sokol_app_utils.h"/><depend name="${HELIX_ROOT}/vendor/stb/stb_image.h"/><depend name="${HELIX_ROOT}/src/helix/adapters/images/stb/internal/images.h"/><depend name="${HELIX_ROOT}/src/helix/adapters/host/sokol/internal/host.h"/><depend name="${HELIX_ROOT}/src/helix/adapters/graphics/sokol/internal/graphics.h"/><depend name="${HELIX_ROOT}/src/helix/adapters/input/sokol/internal/input.h"/><depend name="${HELIX_ROOT}/src/helix/adapters/input/evdev/internal/gamepad.h"/><depend name="${HELIX_ROOT}/src/helix/adapters/audio/sokol/internal/audio.h"/><depend name="${HELIX_ROOT}/src/helix/adapters/audio/libsndfile/internal/codec.h"/>
 <file name="host/sokol/internal/host.c"/><file name="graphics/sokol/internal/graphics.c"/><file name="audio/libsndfile/internal/codec.c"/>
 <file name="input/sokol/internal/input.c"/><file name="input/evdev/internal/gamepad_linux.c"/><file name="audio/sokol/internal/audio.c"/><file name="images/stb/internal/images.c"/>
</files>
<files id="haxe"><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/images/stb/internal"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/graphics/sokol/internal"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/host/sokol/internal"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/input/sokol/internal"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/audio/sokol/internal"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/audio/libsndfile/internal"/></files>
<target id="haxe"><files id="helix-adapters"/><lib name="${HELIX_CODEC_LIBRARY}"/><lib name="-lX11"/><lib name="-lXrandr"/><lib name="-lXi"/><lib name="-lXcursor"/><lib name="-lGL"/><lib name="-lasound"/><lib name="-ldl"/><lib name="-lpthread"/></target>')
extern class SokolNativeBuild {}
