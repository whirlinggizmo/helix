package helix.adapters.graphics.sokol.internal;

import helix.adapters.internal.SokolNativeBuild;

@:include("graphics.h")
extern class GraphicsBridge extends SokolNativeBuild {
	@:native("helix_setup") static function setup():Void;
	@:native("helix_shutdown") static function shutdown():Void;
	@:native("helix_texture") static function texture(w:Int, h:Int, data:cpp.RawPointer<cpp.UInt8>, bytes:Int, levels:Int, format:Int):Int;
	@:native("helix_cube_texture") static function cubeTexture(size:Int, data:cpp.RawPointer<cpp.UInt8>, bytes:Int, levels:Int, format:Int):Int;
	@:native("helix_data_texture") static function dataTexture(w:Int, h:Int):Int;
	@:native("helix_update_data") static function updateData(texture:Int, data:cpp.RawPointer<cpp.UInt8>, bytes:Int):Int;
	@:native("helix_can_sample") static function canSample(format:Int):Int;
	@:native("helix_buffer") static function buffer(capacity:Int):Int;
	@:native("helix_static_buffer") static function staticBuffer(data:cpp.RawPointer<cpp.UInt8>, bytes:Int, index:Int):Int;
	@:native("helix_pipeline") static function pipeline(desc:cpp.RawPointer<Int>, count:Int):Int;
	@:native("helix_shader") static function shader(vs:cpp.ConstCharStar, fs:cpp.ConstCharStar, layout:cpp.ConstCharStar):Int;
	@:native("helix_update") static function update(buffer:Int, data:cpp.RawPointer<cpp.UInt8>, bytes:Int):Int;
	@:native("helix_target") static function target(w:Int, h:Int):Int;
	@:native("helix_begin_target") static function beginTarget(target:Int, color:Int):Int;
	@:native("helix_end_target") static function endTarget():Int;
	@:native("helix_shadow_map") static function shadowMap(size:Int, layers:Int):Int;
	@:native("helix_begin_shadow") static function beginShadow(map:Int, layer:Int):Int;
	@:native("helix_begin") static function begin(width:Int, height:Int, color:Int):Int;
	@:native("helix_viewport") static function viewport(x:Int, y:Int, w:Int, h:Int):Int;
	@:native("helix_draw") static function draw(pipeline:Int, buffers:cpp.RawPointer<cpp.UInt32>, bufferCount:Int, indices:Int, first:Int, count:Int,
		firstInstance:Int, instanceCount:Int, textures:cpp.RawPointer<cpp.UInt32>, samplings:cpp.RawPointer<Int>, textureCount:Int,
		uniforms:cpp.RawPointer<cpp.UInt8>, uniformBytes:Int):Int;
	@:native("helix_end") static function end():Void;
	@:native("helix_destroy") static function destroy(kind:Int, handle:Int):Int;
	@:native("helix_read_width") static function readWidth(target:cpp.UInt32):Int;
	@:native("helix_read_height") static function readHeight(target:cpp.UInt32):Int;
	@:native("helix_read_pixels") static function readPixels(target:cpp.UInt32, out:cpp.RawPointer<cpp.UInt8>):Int;
	@:native("helix_scissor") static function scissor(x:Int, y:Int, w:Int, h:Int, on:Int):Int;
}
