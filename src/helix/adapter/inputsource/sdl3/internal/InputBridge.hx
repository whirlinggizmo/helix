package helix.adapter.inputsource.sdl3.internal;

/** Built with the app by hxcpp: the shared input queue (shared/input.c), which an SDL event watch fills with keys, the pointer, text, touch and focus, and SDL's gamepads (its controller database, hot-plugging); linked with the SDL3 the host links (HELIX_SDL3_LIBRARY). */
@:buildXml('<set name="HELIX_ROOT" value="${haxelib:helix}" unless="HELIX_ROOT"/>
<files id="helix-input-sdl3" dir="${HELIX_ROOT}/src/helix/adapter">
 <compilerflag value="-I${HELIX_ROOT}/vendor/sdl3"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapter/shared"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapter/inputsource/sdl3/internal"/>
 <compilerflag value="-DNDEBUG" unless="debug"/><compilerflag value="-O2" if="windows" unless="debug"/><compilerflag value="-O3" unless="windows||debug"/><compilerflag value="-D_POSIX_C_SOURCE=200809L" if="linux"/>
 <!-- hxcpp rebuilds an object when its source changes; these make a changed header rebuild it too. -->
 <depend name="${HELIX_ROOT}/vendor/sdl3/SDL3/SDL.h"/><depend name="${HELIX_ROOT}/src/helix/adapter/shared/lock.h"/><depend name="${HELIX_ROOT}/src/helix/adapter/shared/input.h"/><depend name="${HELIX_ROOT}/src/helix/adapter/shared/gamepad.h"/>
 <file name="shared/input.c"/>
 <file name="inputsource/sdl3/internal/input_sdl3.c"/>
</files>
<files id="haxe"><compilerflag value="-I${HELIX_ROOT}/vendor/sdl3"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapter/shared"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapter/inputsource/sdl3/internal"/></files>
<target id="haxe">
 <files id="helix-input-sdl3"/>
 <lib name="${HELIX_SDL3_LIBRARY}"/>
</target>')
@:include("input.h")
@:noCompletion
extern class InputBridge {
	@:native("helix_input_setup") static function setup():Void;
	@:native("helix_input_shutdown") static function shutdown():Void;
	@:native("helix_input_poll") static function poll():Void;
	@:native("helix_input_set_text") static function setText(on:Int):Void;
}
