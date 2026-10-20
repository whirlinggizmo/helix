package helix.adapters.inputsource.sokol.internal;

/** Built with the app by hxcpp: the shared input queue (shared/input.c), which the sokol host's events fill, and gamepads: evdev on Linux, XInput on Windows (loaded at run time), none on macOS. */
@:buildXml('<files id="helix-input-sokol" dir="${HELIX_ROOT}/src/helix/adapters">
 <compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/shared"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/inputsource/sokol/internal"/>
 <compilerflag value="-DNDEBUG" unless="debug"/><compilerflag value="-O2" if="windows" unless="debug"/><compilerflag value="-O3" unless="windows||debug"/><compilerflag value="-D_POSIX_C_SOURCE=200809L" if="linux"/>
 <!-- hxcpp rebuilds an object when its source changes; these make a changed header rebuild it too. -->
 <depend name="${HELIX_ROOT}/src/helix/adapters/shared/lock.h"/><depend name="${HELIX_ROOT}/src/helix/adapters/shared/input.h"/><depend name="${HELIX_ROOT}/src/helix/adapters/shared/gamepad.h"/>
 <file name="shared/input.c"/>
 <file name="inputsource/sokol/internal/input_sokol.c"/>
 <file name="inputsource/evdev/internal/gamepad_linux.c" if="linux"/>
 <file name="inputsource/xinput/internal/gamepad_windows.c" if="windows"/>
 <file name="inputsource/sokol/internal/gamepad_none.c" if="macos"/>
</files>
<files id="haxe"><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/shared"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/inputsource/sokol/internal"/></files>
<target id="haxe">
 <files id="helix-input-sokol"/>
</target>')
@:include("input.h")
extern class InputBridge {
	@:native("helix_input_setup") static function setup():Void;
	@:native("helix_input_shutdown") static function shutdown():Void;
	@:native("helix_input_poll") static function poll():Void;
}
