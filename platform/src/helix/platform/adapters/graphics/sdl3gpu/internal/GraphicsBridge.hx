package helix.platform.adapters.graphics.sdl3gpu.internal;

/** Provides SDL_GPU's own calls: setup, dispose, and programs in the device's dialect.

	hxcpp builds the C with the program. It presents to the SDL3 window (surface.h), implements the shared graphics calls (graphics.h,
	`GraphicsDeviceBridge`) and links the SDL3 library that HELIX_SDL3_LIBRARY names. */
@:buildXml("<set name='HELIX_PLATFORM' value='${haxelib:helix-platform}' unless='HELIX_PLATFORM'/>
<files id='helix-graphics-sdl3gpu' dir='${HELIX_PLATFORM}/src/helix/platform/adapters'>
 <compilerflag value='-I${HELIX_PLATFORM}/vendor/sdl3'/><compilerflag value='-I${HELIX_PLATFORM}/src/helix/platform/adapters/shared'/><compilerflag value='-I${HELIX_PLATFORM}/src/helix/platform/adapters/graphics/sdl3gpu/internal'/>
 <compilerflag value='-DNDEBUG' unless='debug'/><compilerflag value='-O2' if='windows' unless='debug'/><compilerflag value='-O3' unless='windows||debug'/><compilerflag value='-D_POSIX_C_SOURCE=200809L' if='linux'/>
 <!-- hxcpp rebuilds an object when its source changes; these make a changed header rebuild it too. -->
 <depend name='${HELIX_PLATFORM}/vendor/sdl3/SDL3/SDL_gpu.h'/><depend name='${HELIX_PLATFORM}/src/helix/platform/adapters/shared/surface.h'/><depend name='${HELIX_PLATFORM}/src/helix/platform/adapters/shared/graphics.h'/><depend name='${HELIX_PLATFORM}/src/helix/platform/adapters/graphics/sdl3gpu/internal/graphics_sdl3gpu.h'/>
 <file name='graphics/sdl3gpu/internal/graphics_sdl3gpu.c'/>
</files>
<files id='haxe'><compilerflag value='-I${HELIX_PLATFORM}/src/helix/platform/adapters/shared'/><compilerflag value='-I${HELIX_PLATFORM}/src/helix/platform/adapters/graphics/sdl3gpu/internal'/></files>
<target id='haxe'>
 <files id='helix-graphics-sdl3gpu'/>
 <lib name='${HELIX_SDL3_LIBRARY}'/>
</target>")
@:include("graphics_sdl3gpu.h")
@:noCompletion
extern class GraphicsBridge {
	@:native("helix_sdl3gpu_setup") static function setup():Int;
	@:native("helix_sdl3gpu_dispose") static function dispose():Void;
	@:native("helix_sdl3gpu_shader_format") static function shaderFormat():Int;
	@:native("helix_sdl3gpu_shader") static function shader(vs:cpp.RawPointer<cpp.UInt8>, vsBytes:Int, fs:cpp.RawPointer<cpp.UInt8>, fsBytes:Int,
		layout:cpp.ConstCharStar):Int;
}
