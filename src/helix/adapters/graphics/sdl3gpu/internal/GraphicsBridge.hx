package helix.adapters.graphics.sdl3gpu.internal;

/** Built with the app by hxcpp: SDL_GPU (Vulkan, Direct3D 12 or Metal, as SDL picks) presenting to the SDL3 host's window (adapters/shared/
	surface.h), linked with the SDL3 the host links (HELIX_SDL3_LIBRARY); the shared graphics calls (shared/graphics.h, GraphicsDeviceBridge)
	and its own: setup, shutdown, and programs in the device's dialect. */
@:buildXml('<files id="helix-graphics-sdl3gpu" dir="${HELIX_ROOT}/src/helix/adapters">
 <compilerflag value="-I${HELIX_ROOT}/vendor/sdl3"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/shared"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/graphics/sdl3gpu/internal"/>
 <compilerflag value="-DNDEBUG"/><compilerflag value="-O2" if="windows"/><compilerflag value="-O3" unless="windows"/><compilerflag value="-D_POSIX_C_SOURCE=200809L" if="linux"/>
 <!-- hxcpp rebuilds an object when its source changes; these make a changed header rebuild it too. -->
 <depend name="${HELIX_ROOT}/vendor/sdl3/SDL3/SDL_gpu.h"/><depend name="${HELIX_ROOT}/src/helix/adapters/shared/surface.h"/><depend name="${HELIX_ROOT}/src/helix/adapters/shared/graphics.h"/><depend name="${HELIX_ROOT}/src/helix/adapters/graphics/sdl3gpu/internal/graphics_sdl3gpu.h"/>
 <file name="graphics/sdl3gpu/internal/graphics_sdl3gpu.c"/>
</files>
<files id="haxe"><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/shared"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/graphics/sdl3gpu/internal"/></files>
<target id="haxe">
 <files id="helix-graphics-sdl3gpu"/>
 <lib name="${HELIX_SDL3_LIBRARY}"/>
</target>')
@:include("graphics_sdl3gpu.h")
extern class GraphicsBridge {
	@:native("helix_sdl3gpu_setup") static function setup():Int;
	@:native("helix_sdl3gpu_shutdown") static function shutdown():Void;
	@:native("helix_sdl3gpu_shader_format") static function shaderFormat():Int;
	@:native("helix_sdl3gpu_driver") static function driver():cpp.ConstCharStar;
	@:native("helix_sdl3gpu_shader") static function shader(vs:cpp.RawPointer<cpp.UInt8>, vsBytes:Int, fs:cpp.RawPointer<cpp.UInt8>, fsBytes:Int,
		layout:cpp.ConstCharStar):Int;
}
