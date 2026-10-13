package helix.adapters.host.sokol.internal;
import helix.adapters.internal.SokolNativeBuild;
@:include("host.h")
extern class HostBridge extends SokolNativeBuild {
 @:native("hy_run") static function run(init:cpp.Callable<Void->Void>,frame:cpp.Callable<cpp.Float32->Void>,cleanup:cpp.Callable<Void->Void>):Void;
 @:native("hy_quit") static function quit():Void;
 @:native("hy_width") static function width():Int;
 @:native("hy_height") static function height():Int;
 @:native("hy_pixel_ratio") static function pixelRatio():cpp.Float32;
 @:native("hy_window_set_title") static function setTitle(title:cpp.ConstCharStar):Void;
 @:native("hy_window_width") static function windowWidth():Int;
 @:native("hy_window_height") static function windowHeight():Int;
 @:native("hy_window_set_size") static function setSize(width:Int,height:Int):Void;
 @:native("hy_window_can_move") static function canMove():Int;
 @:native("hy_window_x") static function windowX():Int;
 @:native("hy_window_y") static function windowY():Int;
 @:native("hy_window_set_position") static function setPosition(x:Int,y:Int):Void;
 @:native("hy_window_fullscreen") static function fullscreen():Int;
 @:native("hy_window_set_fullscreen") static function setFullscreen(on:Int):Void;
 @:native("hy_window_visible") static function visible():Int;
 @:native("hy_window_set_visible") static function setVisible(on:Int):Void;
 @:native("hy_display_count") static function displayCount():Int;
 @:native("hy_display_current") static function displayCurrent():Int;
 @:native("hy_display_set") static function setDisplay(index:Int):Void;
 @:native("hy_display_x") static function displayX(index:Int):Int;
 @:native("hy_display_y") static function displayY(index:Int):Int;
 @:native("hy_display_width") static function displayWidth(index:Int):Int;
 @:native("hy_display_height") static function displayHeight(index:Int):Int;
 @:native("hy_display_name") static function displayName(index:Int):cpp.ConstCharStar;
}
