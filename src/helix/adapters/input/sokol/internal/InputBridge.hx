package helix.adapters.input.sokol.internal;

import helix.adapters.internal.SokolNativeBuild;

@:include("input.h")
extern class InputBridge extends SokolNativeBuild {
	@:native("hy_input_setup") static function inputSetup():Void;
	@:native("hy_input_shutdown") static function inputShutdown():Void;
	@:native("hy_input_poll") static function inputPoll():Void;
	@:native("hy_input_next") static function next():Int;
	@:native("hy_event_type") static function eventType():Int;
	@:native("hy_event_code") static function eventCode():Int;
	@:native("hy_event_value") static function eventValue():Int;
	@:native("hy_event_x") static function eventX():cpp.Float32;
	@:native("hy_event_y") static function eventY():cpp.Float32;
	@:native("hy_focused") static function focused():Int;
	@:native("hy_pad_connected") static function padConnected(pad:Int):Int;
	@:native("hy_pad_name") static function padName(pad:Int):cpp.ConstCharStar;
	@:native("hy_pad_button") static function padButton(pad:Int, button:Int):Int;
	@:native("hy_pad_axis") static function padAxis(pad:Int, axis:Int):cpp.Float32;
}
