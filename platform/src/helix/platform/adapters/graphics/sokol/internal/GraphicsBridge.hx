package helix.platform.adapters.graphics.sokol.internal;

/** Provides sokol_gfx's own calls: setup, dispose, and programs from GLSL 410.

	hxcpp builds the C with the program: sokol_gfx on GL 4.1 core in the window's GL context (its size from surface.h), and sokol_log. It
	implements the shared graphics calls (graphics.h, `GraphicsDeviceBridge`). */
@:buildXml("<set name='HELIX_PLATFORM' value='${haxelib:helix-platform}' unless='HELIX_PLATFORM'/>
<files id='helix-graphics-sokol' dir='${HELIX_PLATFORM}/src/helix/platform/adapters'>
 <compilerflag value='-I${HELIX_PLATFORM}/vendor'/><compilerflag value='-I${HELIX_PLATFORM}/src/helix/platform/adapters/shared'/><compilerflag value='-I${HELIX_PLATFORM}/src/helix/platform/adapters/graphics/sokol/internal'/>
 <compilerflag value='-DNDEBUG' unless='debug'/><compilerflag value='-O2' if='windows' unless='debug'/><compilerflag value='-O3' unless='windows||debug'/><compilerflag value='-D_POSIX_C_SOURCE=200809L' if='linux'/>
 <!-- hxcpp rebuilds an object when its source changes; these make a changed header rebuild it too. -->
 <depend name='${HELIX_PLATFORM}/vendor/sokol_gfx.h'/><depend name='${HELIX_PLATFORM}/vendor/sokol_log.h'/><depend name='${HELIX_PLATFORM}/src/helix/platform/adapters/shared/surface.h'/><depend name='${HELIX_PLATFORM}/src/helix/platform/adapters/shared/graphics.h'/><depend name='${HELIX_PLATFORM}/src/helix/platform/adapters/graphics/sokol/internal/graphics_sokol.h'/>
 <file name='graphics/sokol/internal/graphics_sokol.c'/>
</files>
<files id='haxe'><compilerflag value='-I${HELIX_PLATFORM}/vendor'/><compilerflag value='-I${HELIX_PLATFORM}/src/helix/platform/adapters/shared'/><compilerflag value='-I${HELIX_PLATFORM}/src/helix/platform/adapters/graphics/sokol/internal'/></files>
<target id='haxe'>
 <files id='helix-graphics-sokol'/>
 <section if='linux'><lib name='-lGL'/></section>
 <section if='windows'><lib name='opengl32.lib'/></section>
 <section if='macos'><vflag name='-framework' value='OpenGL'/></section>
</target>")
@:include("graphics_sokol.h")
@:noCompletion
extern class GraphicsBridge {
	@:native("helix_setup") static function setup():Void;
	@:native("helix_dispose") static function dispose():Void;
	@:native("helix_shader") static function shader(vs:cpp.ConstCharStar, fs:cpp.ConstCharStar, layout:cpp.ConstCharStar):Int;
}
