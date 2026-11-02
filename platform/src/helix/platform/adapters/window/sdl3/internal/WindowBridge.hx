package helix.platform.adapters.window.sdl3.internal;

/** Provides the SDL3 window's own calls: title, size, position, fullscreen, visibility and the displays, each request returning SDL's
	answer, and the window's events counted by kind as SDL queues them.

	hxcpp builds the C with the program; on Linux it links Xlib too, to ask whether X is XWayland. The window itself is
	`helix.platform.adapters.shared.sdl3.Sdl3Bridge`'s. */
@:buildXml("<set name='HELIX_PLATFORM' value='${haxelib:helix-platform}' unless='HELIX_PLATFORM'/>
<files id='helix-platform-window-sdl3' dir='${HELIX_PLATFORM}/src/helix/platform/adapters'>
 <compilerflag value='-I${HELIX_PLATFORM}/vendor/sdl3'/><compilerflag value='-I${HELIX_PLATFORM}/src/helix/platform/adapters/shared/sdl3'/><compilerflag value='-I${HELIX_PLATFORM}/src/helix/platform/adapters/window/sdl3/internal'/>
 <compilerflag value='-DNDEBUG' unless='debug'/><compilerflag value='-O2' if='windows' unless='debug'/><compilerflag value='-O3' unless='windows||debug'/><compilerflag value='-D_POSIX_C_SOURCE=200809L' if='linux'/>
 <depend name='${HELIX_PLATFORM}/vendor/sdl3/SDL3/SDL.h'/><depend name='${HELIX_PLATFORM}/src/helix/platform/adapters/shared/sdl3/sdl3.h'/><depend name='${HELIX_PLATFORM}/src/helix/platform/adapters/window/sdl3/internal/window_sdl3.h'/>
 <file name='window/sdl3/internal/window_sdl3.c'/>
</files>
<files id='haxe'><compilerflag value='-I${HELIX_PLATFORM}/src/helix/platform/adapters/window/sdl3/internal'/></files>
<target id='haxe'>
 <files id='helix-platform-window-sdl3'/>
 <section if='linux'><lib name='-lX11'/></section>
</target>")
@:include("window_sdl3.h")
@:noCompletion
extern class WindowBridge {
	/** The window's events counted, as window_sdl3.h numbers their kinds. */
	static inline final SHOWN = 0;

	static inline final HIDDEN = 1;
	static inline final MOVED = 2;
	static inline final RESIZED = 3;
	static inline final MINIMIZED = 4;
	static inline final MAXIMIZED = 5;
	static inline final RESTORED = 6;
	static inline final FOCUS_GAINED = 7;
	static inline final DISPLAY_CHANGED = 8;
	static inline final ENTER_FULLSCREEN = 9;
	static inline final LEAVE_FULLSCREEN = 10;

	@:native("helix_window_watch") static function watch(on:Int):Void;
	@:native("helix_window_event_count") static function eventCount(kind:Int):Int;
	@:native("helix_window_error") static function error():cpp.ConstCharStar;
	@:native("helix_window_pixel_ratio") static function pixelRatio():cpp.Float32;
	@:native("helix_window_set_title") static function setTitle(title:cpp.ConstCharStar):Void;
	@:native("helix_window_width") static function width():Int;
	@:native("helix_window_height") static function height():Int;
	@:native("helix_window_set_size") static function setSize(width:Int, height:Int):Int;
	@:native("helix_window_can_move") static function canMove():Int;
	@:native("helix_window_x") static function x():Int;
	@:native("helix_window_y") static function y():Int;
	@:native("helix_window_set_position") static function setPosition(x:Int, y:Int):Int;
	@:native("helix_window_fullscreen") static function fullscreen():Int;
	@:native("helix_window_set_fullscreen") static function setFullscreen(on:Int):Int;
	@:native("helix_window_maximized") static function maximized():Int;
	@:native("helix_window_minimized") static function minimized():Int;
	@:native("helix_window_set_maximized") static function setMaximized(on:Int):Int;
	@:native("helix_window_set_minimized") static function setMinimized(on:Int):Int;
	@:native("helix_window_raise") static function raise():Int;
	@:native("helix_window_has_focus") static function hasFocus():Int;
	@:native("helix_window_set_icon") static function setIcon(width:Int, height:Int, rgba:cpp.RawConstPointer<cpp.Void>):Void;
	@:native("helix_window_opacity") static function opacity():cpp.Float32;
	@:native("helix_window_set_opacity") static function setOpacity(opacity:cpp.Float32):Int;
	@:native("helix_window_set_minimum_size") static function setMinimumSize(width:Int, height:Int):Int;
	@:native("helix_window_set_maximum_size") static function setMaximumSize(width:Int, height:Int):Int;
	@:native("helix_display_refresh_rate") static function displayRefreshRate(index:Int):cpp.Float32;
	@:native("helix_window_visible") static function visible():Int;
	@:native("helix_window_set_visible") static function setVisible(on:Int):Int;
	@:native("helix_display_count") static function displayCount():Int;
	@:native("helix_display_current") static function displayCurrent():Int;
	@:native("helix_display_set") static function setDisplay(index:Int):Int;
	@:native("helix_display_x") static function displayX(index:Int):Int;
	@:native("helix_display_y") static function displayY(index:Int):Int;
	@:native("helix_display_width") static function displayWidth(index:Int):Int;
	@:native("helix_display_height") static function displayHeight(index:Int):Int;
	@:native("helix_display_name") static function displayName(index:Int):cpp.ConstCharStar;
}
