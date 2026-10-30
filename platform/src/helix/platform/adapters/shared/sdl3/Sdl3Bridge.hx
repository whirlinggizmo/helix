package helix.platform.adapters.shared.sdl3;

@:buildXml("<set name='HELIX_PLATFORM' value='${haxelib:helix-platform}' unless='HELIX_PLATFORM'/>
<files id='helix-platform-sdl3' dir='${HELIX_PLATFORM}/src/helix/platform/adapters'>
 <compilerflag value='-I${HELIX_PLATFORM}/vendor/sdl3'/><compilerflag value='-I${HELIX_PLATFORM}/src/helix/platform/adapters/shared'/><compilerflag value='-I${HELIX_PLATFORM}/src/helix/platform/adapters/shared/sdl3'/>
 <compilerflag value='-DNDEBUG' unless='debug'/><compilerflag value='-O2' if='windows' unless='debug'/><compilerflag value='-O3' unless='windows||debug'/><compilerflag value='-D_POSIX_C_SOURCE=200809L' if='linux'/>
 <!-- hxcpp rebuilds an object when its source changes; these make a changed header rebuild it too. -->
 <depend name='${HELIX_PLATFORM}/vendor/sdl3/SDL3/SDL.h'/><depend name='${HELIX_PLATFORM}/src/helix/platform/adapters/shared/surface.h'/><depend name='${HELIX_PLATFORM}/src/helix/platform/adapters/shared/sdl3/sdl3.h'/>
 <file name='shared/sdl3/sdl3.c'/>
</files>
<files id='haxe'><compilerflag value='-I${HELIX_PLATFORM}/vendor/sdl3'/><compilerflag value='-I${HELIX_PLATFORM}/src/helix/platform/adapters/shared'/><compilerflag value='-I${HELIX_PLATFORM}/src/helix/platform/adapters/shared/sdl3'/></files>
<target id='haxe'>
 <files id='helix-platform-sdl3'/>
 <lib name='${HELIX_SDL3_LIBRARY}'/>
 <section if='windows'><lib name='dwmapi.lib'/><lib name='shell32.lib'/></section>
 <section if='linux'><lib name='-lm'/><lib name='-ldl'/><lib name='-lpthread'/></section>
 <flag value='-Wl,-rpath,@executable_path' if='macos'/>
</target>")
/** Provides the C that SDL3's adapters share: the window and its GL context, the shared focus, the clock and the program's facts.

	hxcpp builds the C with the program, against the SDL3 headers in `vendor/`, and links the SDL3 library that HELIX_SDL3_LIBRARY names;
	on Windows, DWM too, to wait on the compositor, and the shell, for its folders. */
@:include("sdl3.h")
@:include("surface.h")
@:noCompletion
extern class Sdl3Bridge {
	@:native("helix_sdl3_open") static function open(sampleCount:Int, withGl:Int):Int;
	@:native("helix_sdl3_close") static function close():Void;
	@:native("helix_sdl3_is_open") static function isOpen():Int;
	@:native("helix_sdl3_focused") static function focused():Int;
	@:native("helix_sdl3_set_focused") static function setFocused(focused:Int):Void;
	@:native("helix_surface_width") static function framebufferWidth():Int;
	@:native("helix_surface_height") static function framebufferHeight():Int;
	@:native("helix_sdl3_platform") static function platform():cpp.ConstCharStar;
	@:native("helix_sdl3_getenv") static function getenv(name:cpp.ConstCharStar):cpp.ConstCharStar;
	@:native("helix_sdl3_base_path") static function basePath():cpp.ConstCharStar;
	@:native("helix_sdl3_time") static function time():Float;
	@:native("helix_sdl3_os_directory") static function osDirectory(which:Int):cpp.ConstCharStar;
	@:native("helix_sdl3_name_app") static function nameApp(name:cpp.ConstCharStar):Void;
}
