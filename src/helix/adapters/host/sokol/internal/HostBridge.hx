package helix.adapters.host.sokol.internal;

import helix.adapters.internal.SokolNativeBuild;

@:include("host.h")
extern class HostBridge extends SokolNativeBuild {
	@:native("helix_run") static function run(init:cpp.Callable<Void->Void>, frame:cpp.Callable<Void->Void>, cleanup:cpp.Callable<Void->Void>):Void;
	@:native("helix_quit") static function quit():Void;
	@:native("helix_width") static function width():Int;
	@:native("helix_height") static function height():Int;
	@:native("helix_pixel_ratio") static function pixelRatio():cpp.Float32;
	@:native("helix_window_set_title") static function setTitle(title:cpp.ConstCharStar):Void;
	@:native("helix_window_width") static function windowWidth():Int;
	@:native("helix_window_height") static function windowHeight():Int;
	@:native("helix_window_set_size") static function setSize(width:Int, height:Int):Void;
	@:native("helix_window_can_move") static function canMove():Int;
	@:native("helix_window_x") static function windowX():Int;
	@:native("helix_window_y") static function windowY():Int;
	@:native("helix_window_set_position") static function setPosition(x:Int, y:Int):Void;
	@:native("helix_window_focused") static function focused():Int;
	@:native("helix_window_fullscreen") static function fullscreen():Int;
	@:native("helix_window_set_fullscreen") static function requestFullscreen(on:Int):Void;
	@:native("helix_window_visible") static function visible():Int;
	@:native("helix_window_set_visible") static function setVisible(on:Int):Void;
	@:native("helix_display_count") static function displayCount():Int;
	@:native("helix_display_current") static function displayCurrent():Int;
	@:native("helix_display_set") static function setDisplay(index:Int):Void;
	@:native("helix_display_x") static function displayX(index:Int):Int;
	@:native("helix_display_y") static function displayY(index:Int):Int;
	@:native("helix_display_width") static function displayWidth(index:Int):Int;
	@:native("helix_display_height") static function displayHeight(index:Int):Int;
	@:native("helix_display_name") static function displayName(index:Int):cpp.ConstCharStar;
}
