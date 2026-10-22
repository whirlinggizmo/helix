package helix.adapter.graphics.sokol.internal;

/** Built with the app by hxcpp: sokol_gfx on GL 4.1 core, in whichever native host's GL context (its size from adapter/shared/surface.h), and
	sokol_log; the shared graphics calls (shared/graphics.h, GraphicsDeviceBridge) and its own: setup, shutdown and programs from GLSL 410. */
@:buildXml('<set name="HELIX_ROOT" value="${haxelib:helix}" unless="HELIX_ROOT"/>
<files id="helix-graphics-sokol" dir="${HELIX_ROOT}/src/helix/adapter">
 <compilerflag value="-I${HELIX_ROOT}/vendor"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapter/shared"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapter/graphics/sokol/internal"/>
 <compilerflag value="-DNDEBUG" unless="debug"/><compilerflag value="-O2" if="windows" unless="debug"/><compilerflag value="-O3" unless="windows||debug"/><compilerflag value="-D_POSIX_C_SOURCE=200809L" if="linux"/>
 <!-- hxcpp rebuilds an object when its source changes; these make a changed header rebuild it too. -->
 <depend name="${HELIX_ROOT}/vendor/sokol_gfx.h"/><depend name="${HELIX_ROOT}/vendor/sokol_log.h"/><depend name="${HELIX_ROOT}/src/helix/adapter/shared/surface.h"/><depend name="${HELIX_ROOT}/src/helix/adapter/shared/graphics.h"/><depend name="${HELIX_ROOT}/src/helix/adapter/graphics/sokol/internal/graphics_sokol.h"/>
 <file name="graphics/sokol/internal/graphics_sokol.c"/>
</files>
<files id="haxe"><compilerflag value="-I${HELIX_ROOT}/vendor"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapter/shared"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapter/graphics/sokol/internal"/></files>
<target id="haxe">
 <files id="helix-graphics-sokol"/>
 <section if="linux"><lib name="-lGL"/></section>
 <section if="windows"><lib name="opengl32.lib"/></section>
 <section if="macos"><vflag name="-framework" value="OpenGL"/></section>
</target>')
@:include("graphics_sokol.h")
@:noCompletion
extern class GraphicsBridge {
	@:native("helix_setup") static function setup():Void;
	@:native("helix_shutdown") static function shutdown():Void;
	@:native("helix_shader") static function shader(vs:cpp.ConstCharStar, fs:cpp.ConstCharStar, layout:cpp.ConstCharStar):Int;
}
