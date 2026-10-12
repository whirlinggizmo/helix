package helix.adapters.host.sokol.internal;
import helix.adapters.internal.SokolNativeBuild;
@:include("host.h")
extern class HostBridge extends SokolNativeBuild {
 @:native("hy_run") static function run(init:cpp.Callable<Void->Void>,frame:cpp.Callable<cpp.Float32->Void>,cleanup:cpp.Callable<Void->Void>):Void;
 @:native("hy_quit") static function quit():Void;
 @:native("hy_width") static function width():Int;
 @:native("hy_height") static function height():Int;
 @:native("hy_pixel_ratio") static function pixelRatio():cpp.Float32;
}
