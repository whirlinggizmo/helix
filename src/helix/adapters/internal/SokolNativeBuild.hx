package helix.adapters.internal;
/** Internal Linux Sokol build integration shared by the subsystem externs: hxcpp compiles the adapters' C with the app,
    against the app's own generated shader (HELIX_SHADER_DIR), and links the system libraries. */
@:buildXml('<files id="helix-adapters" dir="${HELIX_ROOT}/src/helix/adapters">
 <compilerflag value="-I${HELIX_ROOT}/vendor"/><compilerflag value="-I${HELIX_ROOT}/vendor/sokol_utils"/><compilerflag value="-I${HELIX_SHADER_DIR}"/>
 <compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/graphics/sokol/internal"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/host/sokol/internal"/>
 <compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/input/sokol/internal"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/input/evdev/internal"/>
 <compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/audio/sokol/internal"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/audio/libsndfile/internal"/>
 <compilerflag value="-D_POSIX_C_SOURCE=200809L"/><compilerflag value="-DNDEBUG"/><compilerflag value="-O3"/>
 <file name="host/sokol/internal/host.c"/><file name="graphics/sokol/internal/graphics.c"/><file name="audio/libsndfile/internal/codec.c"/>
 <file name="input/sokol/internal/input.c"/><file name="input/evdev/internal/gamepad_linux.c"/><file name="audio/sokol/internal/audio.c"/>
</files>
<files id="haxe"><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/graphics/sokol/internal"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/host/sokol/internal"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/input/sokol/internal"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/audio/sokol/internal"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/audio/libsndfile/internal"/></files>
<target id="haxe"><files id="helix-adapters"/><lib name="${HELIX_CODEC_LIBRARY}"/><lib name="-lX11"/><lib name="-lXrandr"/><lib name="-lXi"/><lib name="-lXcursor"/><lib name="-lGL"/><lib name="-lasound"/><lib name="-ldl"/><lib name="-lpthread"/></target>')
extern class SokolNativeBuild {}
