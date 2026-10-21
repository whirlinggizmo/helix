package helix.adapters.imagedecoder.stb.internal;

/** Built with the app by hxcpp: stb_image. */
@:buildXml('<set name="HELIX_ROOT" value="${haxelib:helix}" unless="HELIX_ROOT"/>
<files id="helix-images-stb" dir="${HELIX_ROOT}/src/helix/adapters">
 <compilerflag value="-I${HELIX_ROOT}/vendor/stb"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/shared"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/imagedecoder/stb/internal"/>
 <compilerflag value="-DNDEBUG" unless="debug"/><compilerflag value="-O2" if="windows" unless="debug"/><compilerflag value="-O3" unless="windows||debug"/><compilerflag value="-D_POSIX_C_SOURCE=200809L" if="linux"/>
 <!-- hxcpp rebuilds an object when its source changes; these make a changed header rebuild it too. -->
 <depend name="${HELIX_ROOT}/vendor/stb/stb_image.h"/><depend name="${HELIX_ROOT}/src/helix/adapters/imagedecoder/stb/internal/images.h"/>
 <file name="imagedecoder/stb/internal/images.c"/>
</files>
<files id="haxe"><compilerflag value="-I${HELIX_ROOT}/vendor/stb"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/shared"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/imagedecoder/stb/internal"/></files>
<target id="haxe">
 <files id="helix-images-stb"/>
</target>')
@:include("images.h")
extern class ImageBridge {
	@:native("helix_image_decode") static function decode(data:cpp.RawConstPointer<cpp.Void>, size:Int):cpp.RawPointer<cpp.Void>;
	@:native("helix_image_width") static function width(image:cpp.RawConstPointer<cpp.Void>):Int;
	@:native("helix_image_height") static function height(image:cpp.RawConstPointer<cpp.Void>):Int;
	@:native("helix_image_copy") static function copy(image:cpp.RawConstPointer<cpp.Void>, dest:cpp.RawPointer<cpp.Void>):Void;
	@:native("helix_image_free") static function free(image:cpp.RawPointer<cpp.Void>):Void;
	@:native("helix_image_error") static function error():cpp.ConstCharStar;
}
