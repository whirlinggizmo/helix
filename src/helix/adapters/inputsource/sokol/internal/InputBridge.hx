package helix.adapters.inputsource.sokol.internal;

/** Built with the app by hxcpp: The sokol host's events queued for the input adapter, and gamepads: evdev on Linux, XInput on Windows (loaded at run time), none on macOS. */
@:buildXml('<files id="helix-input-sokol" dir="${HELIX_ROOT}/src/helix/adapters">
 <compilerflag value="-I${HELIX_ROOT}/vendor"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/internal"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/inputsource/sokol/internal"/>
 <compilerflag value="-DNDEBUG"/><compilerflag value="-O2" if="windows"/><compilerflag value="-O3" unless="windows"/><compilerflag value="-D_POSIX_C_SOURCE=200809L" if="linux"/>
 <!-- hxcpp rebuilds an object when its source changes; these make a changed header rebuild it too. -->
 <depend name="${HELIX_ROOT}/vendor/sokol_app.h"/><depend name="${HELIX_ROOT}/src/helix/adapters/internal/lock.h"/><depend name="${HELIX_ROOT}/src/helix/adapters/inputsource/sokol/internal/input.h"/><depend name="${HELIX_ROOT}/src/helix/adapters/inputsource/sokol/internal/gamepad.h"/>
 <file name="inputsource/sokol/internal/input.c"/>
 <file name="inputsource/evdev/internal/gamepad_linux.c" if="linux"/>
 <file name="inputsource/xinput/internal/gamepad_windows.c" if="windows"/>
 <file name="inputsource/sokol/internal/gamepad_none.c" if="macos"/>
</files>
<files id="haxe"><compilerflag value="-I${HELIX_ROOT}/vendor"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/internal"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/inputsource/sokol/internal"/></files>
<target id="haxe">
 <files id="helix-input-sokol"/>
</target>')
@:include("input.h")
extern class InputBridge {
	@:native("helix_input_setup") static function inputSetup():Void;
	@:native("helix_input_shutdown") static function inputShutdown():Void;
	@:native("helix_input_poll") static function inputPoll():Void;
	@:native("helix_input_next") static function next():Int;
	@:native("helix_event_type") static function eventType():Int;
	@:native("helix_event_code") static function eventCode():Int;
	@:native("helix_event_value") static function eventValue():Int;
	@:native("helix_event_x") static function eventX():cpp.Float32;
	@:native("helix_event_y") static function eventY():cpp.Float32;
	@:native("helix_pad_slots") static function padSlots():Int;
	@:native("helix_pad_connected") static function padConnected(pad:Int):Int;
	@:native("helix_pad_name") static function padName(pad:Int):cpp.ConstCharStar;
	@:native("helix_pad_button") static function padButton(pad:Int, button:Int):Int;
	@:native("helix_pad_axis") static function padAxis(pad:Int, axis:Int):cpp.Float32;
}
