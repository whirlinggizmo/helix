package helix.platform.adapters.audiodecoder.sdl3mixer.internal;

/** Provides whole-file audio decoding over SDL3_mixer's decoder (`decoder_sdl3mixer.c`), callable from any thread.

	hxcpp builds the C with the program; SDL3_mixer itself comes with `Sdl3MixerBridge`. */
@:buildXml("<set name='HELIX_PLATFORM' value='${haxelib:helix-platform}' unless='HELIX_PLATFORM'/>
<files id='helix-platform-audiodecoder-sdl3mixer' dir='${HELIX_PLATFORM}/src/helix/platform/adapters'>
 <compilerflag value='-I${HELIX_PLATFORM}/vendor/sdl3'/><compilerflag value='-I${HELIX_PLATFORM}/vendor/sdl3_mixer/include'/><compilerflag value='-I${HELIX_PLATFORM}/src/helix/platform/adapters/audiodecoder/sdl3mixer/internal'/>
 <compilerflag value='-DNDEBUG' unless='debug'/><compilerflag value='-O2' if='windows' unless='debug'/><compilerflag value='-O3' unless='windows||debug'/><compilerflag value='-D_POSIX_C_SOURCE=200809L' if='linux'/>
 <depend name='${HELIX_PLATFORM}/vendor/sdl3/SDL3/SDL.h'/><depend name='${HELIX_PLATFORM}/vendor/sdl3_mixer/include/SDL3_mixer/SDL_mixer.h'/><depend name='${HELIX_PLATFORM}/src/helix/platform/adapters/audiodecoder/sdl3mixer/internal/decoder_sdl3mixer.h'/>
 <file name='audiodecoder/sdl3mixer/internal/decoder_sdl3mixer.c'/>
</files>
<files id='haxe'><compilerflag value='-I${HELIX_PLATFORM}/src/helix/platform/adapters/audiodecoder/sdl3mixer/internal'/></files>
<target id='haxe'>
 <files id='helix-platform-audiodecoder-sdl3mixer'/>
</target>")
@:include("decoder_sdl3mixer.h")
@:noCompletion
extern class AudioDecoderBridge {
	@:native("helix_decoder_init") static function init():Int;
	@:native("helix_decoder_decode") static function decode(data:cpp.RawPointer<cpp.UInt8>, bytes:Int, rate:Int):cpp.RawPointer<cpp.Void>;
	@:native("helix_decoder_count") static function count(result:cpp.RawPointer<cpp.Void>):Int;
	@:native("helix_decoder_channels") static function channels(result:cpp.RawPointer<cpp.Void>):Int;
	@:native("helix_decoder_take") static function take(result:cpp.RawPointer<cpp.Void>, into:cpp.RawPointer<cpp.UInt8>):Void;
	@:native("helix_decoder_error") static function error():cpp.ConstCharStar;
}
