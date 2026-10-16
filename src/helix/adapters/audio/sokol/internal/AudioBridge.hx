package helix.adapters.audio.sokol.internal;

/** Built with the app by hxcpp: sokol_audio and the mixer: ALSA on Linux, WASAPI on Windows, AudioToolbox on macOS. */
@:buildXml('<files id="helix-audio-sokol" dir="${HELIX_ROOT}/src/helix/adapters">
 <compilerflag value="-I${HELIX_ROOT}/vendor"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/shared"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/audio/sokol/internal"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/audiodecoder/libsndfile/internal"/>
 <compilerflag value="-DNDEBUG"/><compilerflag value="-O2" if="windows"/><compilerflag value="-O3" unless="windows"/><compilerflag value="-D_POSIX_C_SOURCE=200809L" if="linux"/>
 <!-- hxcpp rebuilds an object when its source changes; these make a changed header rebuild it too. -->
 <depend name="${HELIX_ROOT}/vendor/sokol_audio.h"/><depend name="${HELIX_ROOT}/vendor/sokol_log.h"/><depend name="${HELIX_ROOT}/src/helix/adapters/shared/lock.h"/><depend name="${HELIX_ROOT}/src/helix/adapters/audio/sokol/internal/audio.h"/><depend name="${HELIX_ROOT}/src/helix/adapters/audiodecoder/libsndfile/internal/codec.h"/>
 <file name="audio/sokol/internal/audio.c"/>
</files>
<files id="haxe"><compilerflag value="-I${HELIX_ROOT}/vendor"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/shared"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/audio/sokol/internal"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/audiodecoder/libsndfile/internal"/></files>
<target id="haxe">
 <files id="helix-audio-sokol"/>
 <section if="linux"><lib name="-lasound"/><lib name="-lpthread"/></section>
 <section if="windows"><lib name="ole32.lib"/></section>
 <section if="macos"><vflag name="-framework" value="AudioToolbox"/></section>
</target>')
@:include("audio.h")
extern class AudioBridge {
	@:native("helix_audio_setup") static function audioSetup():Void;
	@:native("helix_audio_shutdown") static function audioShutdown():Void;
	@:native("helix_audio_clip") static function audioClip(data:cpp.RawPointer<cpp.UInt8>, bytes:Int):Int;
	@:native("helix_audio_play") static function audioPlay(clip:Int, loop:Int, volume:cpp.Float32):Int;
	@:native("helix_audio_stop") static function audioStop(voice:Int):Void;
	@:native("helix_audio_destroy_clip") static function audioDestroyClip(clip:Int):Int;
	@:native("helix_audio_available") static function audioAvailable():Int;
	@:native("helix_audio_played") static function audioPlayed():Int;
	@:native("helix_audio_stopped") static function audioStopped():Int;
	@:native("helix_audio_loops") static function audioLoops():Int;
	@:native("helix_audio_is_playing") static function audioIsPlaying(id:Int):Int;
	@:native("helix_audio_pause") static function audioPause(id:Int, paused:Int):Void;
	@:native("helix_audio_volume") static function audioVolume(id:Int, volume:cpp.Float32):Void;
	@:native("helix_audio_stream") static function audioStream(volume:cpp.Float32):Int;
	@:native("helix_audio_stream_queued") static function audioStreamQueued(id:Int):Int;
	@:native("helix_audio_stream_push") static function audioStreamPush(id:Int, data:cpp.RawPointer<cpp.UInt8>, bytes:Int, eof:Int):Int;
	@:native("helix_audio_callbacks") static function audioCallbacks():Int;
	@:native("helix_audio_sample_rate") static function audioSampleRate():Int;
	@:native("helix_audio_channels") static function audioChannels():Int;
}
