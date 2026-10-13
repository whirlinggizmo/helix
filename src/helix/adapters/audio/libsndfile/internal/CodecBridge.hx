package helix.adapters.audio.libsndfile.internal;

import helix.adapters.internal.SokolNativeBuild;

@:include("codec.h")
extern class CodecBridge extends SokolNativeBuild {
	@:native("hy_codec_memory") static function codecMemory(data:cpp.RawPointer<cpp.UInt8>, bytes:Int):Int;
	@:native("hy_codec_file") static function codecFile(path:cpp.ConstCharStar):Int;
	@:native("hy_codec_frames") static function codecFrames(id:Int):Float;
	@:native("hy_codec_read") static function codecRead(id:Int, data:cpp.RawPointer<cpp.UInt8>, frames:Int):Int;
	@:native("hy_codec_rewind") static function codecRewind(id:Int):Int;
	@:native("hy_codec_close") static function codecClose(id:Int):Void;
	@:native("hy_codec_version") static function codecVersion():cpp.ConstCharStar;
}
