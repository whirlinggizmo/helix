package helix.adapters.graphics.sokol.internal;
import helix.adapters.internal.SokolNativeBuild;
@:include("graphics.h")
extern class GraphicsBridge extends SokolNativeBuild {
 @:native("hy_setup") static function setup():Void;
 @:native("hy_shutdown") static function shutdown():Void;
 @:native("hy_renderer") static function renderer():cpp.ConstCharStar;
 @:native("hy_texture") static function texture(w:Int,h:Int,data:cpp.RawPointer<cpp.UInt8>,bytes:Int,linear:Int):Int;
 @:native("hy_clear_color") static function clearColor(color:Int):Void;
 @:native("hy_buffer") static function buffer(capacity:Int):Int;
 @:native("hy_pipeline") static function pipeline(alpha:Int):Int;
 @:native("hy_update") static function update(buffer:Int,data:cpp.RawPointer<cpp.UInt8>,bytes:Int):Int;
 @:native("hy_begin") static function begin(width:Int,height:Int,x:Int,y:Int,w:Int,h:Int):Int;
 @:native("hy_draw") static function draw(pipeline:Int,buffer:Int,texture:Int,vertices:Int,firstVertex:Int):Int;
 @:native("hy_end") static function end():Void;
 @:native("hy_destroy") static function destroy(kind:Int,handle:Int):Int;
 @:native("hy_peak_rss") static function peakRss():Float;
 @:native("hy_vertex_reserved") static function vertexReserved():Int;
 @:native("hy_graphics_audit") static function audit():cpp.ConstCharStar;
 @:native("hy_capture") static function capture(path:cpp.ConstCharStar):Void;
}
