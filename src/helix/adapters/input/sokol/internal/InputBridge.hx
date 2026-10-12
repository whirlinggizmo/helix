package helix.adapters.input.sokol.internal;
import helix.adapters.internal.SokolNativeBuild;
@:include("input.h")
extern class InputBridge extends SokolNativeBuild {
 @:native("hy_key") static function key(code:Int):Int;
 @:native("hy_input_setup") static function inputSetup():Void;
 @:native("hy_input_shutdown") static function inputShutdown():Void;
 @:native("hy_input_poll") static function inputPoll():Void;
 @:native("hy_input_consume") static function inputConsume():Void;
 @:native("hy_key_pressed") static function keyPressed(code:Int):Int;
 @:native("hy_key_released") static function keyReleased(code:Int):Int;
 @:native("hy_focused") static function focused():Int;
 @:native("hy_pointer_x") static function pointerX():cpp.Float32;
 @:native("hy_pointer_y") static function pointerY():cpp.Float32;
 @:native("hy_pointer_down") static function pointerDown():Int;
 @:native("hy_pointer_pressed") static function pointerPressed():Int;
 @:native("hy_pointer_released") static function pointerReleased():Int;
 @:native("hy_pad_button") static function padButton(button:Int):Int;
 @:native("hy_pad_axis") static function padAxis(axis:Int):cpp.Float32;
}
