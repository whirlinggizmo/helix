package helix.platform.adapters.shared.sdl3;

/** Provides SDL3's events, drained from SDL's one queue at each poll and read one record at a time, for the events adapter and the
	device adapters built over it: which devices are wanted, and the gamepads' state.

	hxcpp builds the C with the program. */
@:buildXml("<set name='HELIX_PLATFORM' value='${haxelib:helix-platform}' unless='HELIX_PLATFORM'/>
<files id='helix-platform-events-sdl3' dir='${HELIX_PLATFORM}/src/helix/platform/adapters'>
 <compilerflag value='-I${HELIX_PLATFORM}/vendor/sdl3'/><compilerflag value='-I${HELIX_PLATFORM}/src/helix/platform/adapters/shared/sdl3'/>
 <compilerflag value='-DNDEBUG' unless='debug'/><compilerflag value='-O2' if='windows' unless='debug'/><compilerflag value='-O3' unless='windows||debug'/><compilerflag value='-D_POSIX_C_SOURCE=200809L' if='linux'/>
 <depend name='${HELIX_PLATFORM}/vendor/sdl3/SDL3/SDL.h'/><depend name='${HELIX_PLATFORM}/src/helix/platform/adapters/shared/sdl3/sdl3.h'/><depend name='${HELIX_PLATFORM}/src/helix/platform/adapters/shared/sdl3/events_sdl3.h'/>
 <file name='shared/sdl3/events_sdl3.c'/>
</files>
<files id='haxe'><compilerflag value='-I${HELIX_PLATFORM}/src/helix/platform/adapters/shared/sdl3'/></files>
<target id='haxe'>
 <files id='helix-platform-events-sdl3'/>
</target>")
@:include("events_sdl3.h")
@:noCompletion
extern class Sdl3EventsBridge {
	/** The devices `want` takes, as events_sdl3.h numbers them. */
	static inline final KEYBOARD = 1;

	static inline final MOUSE = 2;
	static inline final TOUCH = 4;
	static inline final GAMEPADS = 8;

	@:native("helix_events_setup") static function setup():Void;
	@:native("helix_events_dispose") static function dispose():Void;
	@:native("helix_events_poll") static function poll():Void;
	@:native("helix_events_wait") static function wait(milliseconds:Int):Void;
	@:native("helix_events_set_text") static function setText(on:Int):Void;
	@:native("helix_events_want") static function want(device:Int, on:Int):Void;
	@:native("helix_events_next") static function next():Int;
	@:native("helix_events_kind") static function kind():Int;
	@:native("helix_events_code") static function code():Int;
	@:native("helix_events_value") static function value():Int;
	@:native("helix_events_x") static function x():cpp.Float32;
	@:native("helix_events_y") static function y():cpp.Float32;
	@:native("helix_pad_connected") static function padConnected(slot:Int):Int;
	@:native("helix_pad_name") static function padName(slot:Int):cpp.ConstCharStar;
	@:native("helix_pad_button") static function padButton(slot:Int, button:Int):Int;
	@:native("helix_pad_axis") static function padAxis(slot:Int, axis:Int):cpp.Float32;
}
