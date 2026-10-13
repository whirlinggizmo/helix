package helix.adapters.images.stb.internal;

import helix.adapters.internal.SokolNativeBuild;

@:include("images.h")
extern class ImageBridge extends SokolNativeBuild {
	@:native("helix_image_decode") static function decode(data:cpp.RawConstPointer<cpp.Void>, size:Int):cpp.RawPointer<cpp.Void>;
	@:native("helix_image_width") static function width(image:cpp.RawConstPointer<cpp.Void>):Int;
	@:native("helix_image_height") static function height(image:cpp.RawConstPointer<cpp.Void>):Int;
	@:native("helix_image_copy") static function copy(image:cpp.RawConstPointer<cpp.Void>, dest:cpp.RawPointer<cpp.Void>):Void;
	@:native("helix_image_free") static function free(image:cpp.RawPointer<cpp.Void>):Void;
	@:native("helix_image_error") static function error():cpp.ConstCharStar;
}
