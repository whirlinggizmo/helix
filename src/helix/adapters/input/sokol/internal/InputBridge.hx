package helix.adapters.input.sokol.internal;

import helix.adapters.internal.SokolNativeBuild;

@:include("input.h")
extern class InputBridge extends SokolNativeBuild {
	@:native("helix_input_setup") static function inputSetup():Void;
	@:native("helix_input_shutdown") static function inputShutdown():Void;
	@:native("helix_input_poll") static function inputPoll():Void;
	@:native("helix_input_next") static function next():Int;
	@:native("helix_event_type") static function eventType():Int;
	@:native("helix_event_code") static function eventCode():Int;
	@:native("helix_event_value") static function eventValue():Int;
	@:native("helix_event_x") static function eventX():cpp.Float32;
	@:native("helix_event_y") static function eventY():cpp.Float32;
	@:native("helix_focused") static function focused():Int;
	@:native("helix_pad_connected") static function padConnected(pad:Int):Int;
	@:native("helix_pad_name") static function padName(pad:Int):cpp.ConstCharStar;
	@:native("helix_pad_button") static function padButton(pad:Int, button:Int):Int;
	@:native("helix_pad_axis") static function padAxis(pad:Int, axis:Int):cpp.Float32;
}
