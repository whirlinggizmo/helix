package helix.adapter.shared;

/** The shared input queue's C (input.h), built by whichever input adapter the program links (its own InputBridge): the events queued since
	the last poll, and the gamepads. */
@:include("input.h")
extern class InputQueueBridge {
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
