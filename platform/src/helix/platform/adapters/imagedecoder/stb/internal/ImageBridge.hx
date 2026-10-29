package helix.platform.adapters.imagedecoder.stb.internal;

/** Provides image decoding over stb_image (`images.c`), callable from any thread.

	hxcpp builds the C with the program, against `vendor/stb`. */
@:buildXml("<set name='HELIX_PLATFORM' value='${haxelib:helix-platform}' unless='HELIX_PLATFORM'/>
<files id='helix-platform-imagedecoder-stb' dir='${HELIX_PLATFORM}/src/helix/platform/adapters'>
 <compilerflag value='-I${HELIX_PLATFORM}/vendor/stb'/><compilerflag value='-I${HELIX_PLATFORM}/src/helix/platform/adapters/imagedecoder/stb/internal'/>
 <compilerflag value='-DNDEBUG' unless='debug'/><compilerflag value='-O2' if='windows' unless='debug'/><compilerflag value='-O3' unless='windows||debug'/><compilerflag value='-D_POSIX_C_SOURCE=200809L' if='linux'/>
 <depend name='${HELIX_PLATFORM}/vendor/stb/stb_image.h'/><depend name='${HELIX_PLATFORM}/src/helix/platform/adapters/imagedecoder/stb/internal/images.h'/>
 <file name='imagedecoder/stb/internal/images.c'/>
</files>
<files id='haxe'><compilerflag value='-I${HELIX_PLATFORM}/src/helix/platform/adapters/imagedecoder/stb/internal'/></files>
<target id='haxe'>
 <files id='helix-platform-imagedecoder-stb'/>
</target>")
@:include("images.h")
@:noCompletion
extern class ImageBridge {
	@:native("helix_image_decode") static function decode(data:cpp.RawConstPointer<cpp.Void>, size:Int):cpp.RawPointer<cpp.Void>;
	@:native("helix_image_width") static function width(image:cpp.RawConstPointer<cpp.Void>):Int;
	@:native("helix_image_height") static function height(image:cpp.RawConstPointer<cpp.Void>):Int;
	@:native("helix_image_copy") static function copy(image:cpp.RawConstPointer<cpp.Void>, dest:cpp.RawPointer<cpp.Void>):Void;
	@:native("helix_image_free") static function free(image:cpp.RawPointer<cpp.Void>):Void;
	@:native("helix_image_error") static function error():cpp.ConstCharStar;
}
