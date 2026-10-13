package helix.adapters.graphics.sokol.internal;

import helix.adapters.internal.SokolNativeBuild;

@:include("graphics.h")
extern class GraphicsBridge extends SokolNativeBuild {
	@:native("helix_setup") static function setup():Void;
	@:native("helix_shutdown") static function shutdown():Void;
	@:native("helix_renderer") static function renderer():cpp.ConstCharStar;
	@:native("helix_texture") static function texture(w:Int, h:Int, data:cpp.RawPointer<cpp.UInt8>, bytes:Int, levels:Int, linear:Int):Int;
	@:native("helix_buffer") static function buffer(capacity:Int):Int;
	@:native("helix_static_buffer") static function staticBuffer(data:cpp.RawPointer<cpp.UInt8>, bytes:Int, index:Int):Int;
	@:native("helix_pipeline") static function pipeline(kind:Int, alpha:Int):Int;
	@:native("helix_update") static function update(buffer:Int, data:cpp.RawPointer<cpp.UInt8>, bytes:Int):Int;
	@:native("helix_begin") static function begin(width:Int, height:Int, color:Int):Int;
	@:native("helix_viewport") static function viewport(x:Int, y:Int, w:Int, h:Int):Int;
	@:native("helix_draw") static function draw(pipeline:Int, buffer:Int, texture:Int, vertices:Int, firstVertex:Int, uniforms:cpp.RawPointer<cpp.UInt8>,
		uniformBytes:Int):Int;
	@:native("helix_draw_mesh") static function drawMesh(pipeline:Int, vertices:Int, indices:Int, indexCount:Int, instances:Int, firstInstance:Int,
		instanceCount:Int, texture:Int, normal:Int, vs:cpp.RawPointer<cpp.UInt8>, vsBytes:Int, fs:cpp.RawPointer<cpp.UInt8>, fsBytes:Int):Int;
	@:native("helix_end") static function end():Void;
	@:native("helix_destroy") static function destroy(kind:Int, handle:Int):Int;
	@:native("helix_peak_rss") static function peakRss():Float;
	@:native("helix_vertex_reserved") static function vertexReserved():Int;
	@:native("helix_graphics_audit") static function audit():cpp.ConstCharStar;
	@:native("helix_capture") static function capture(path:cpp.ConstCharStar):Void;
}
