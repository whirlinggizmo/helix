package helix.adapter.shared;

/** The shared mixer's C (audio.h: mixer.c, and the output's availability, rate and channels), built by whichever audio adapter the
	program links (its own AudioBridge). */
@:include("audio.h")
extern class MixerBridge {
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
	@:native("helix_audio_pitch") static function audioPitch(id:Int, pitch:cpp.Float32):Void;
	@:native("helix_audio_pan") static function audioPan(id:Int, pan:cpp.Float32):Void;
	@:native("helix_audio_stream") static function audioStream(volume:cpp.Float32):Int;
	@:native("helix_audio_stream_queued") static function audioStreamQueued(id:Int):Int;
	@:native("helix_audio_stream_push") static function audioStreamPush(id:Int, data:cpp.RawPointer<cpp.UInt8>, bytes:Int, eof:Int):Int;
	@:native("helix_audio_callbacks") static function audioCallbacks():Int;
	@:native("helix_audio_sample_rate") static function audioSampleRate():Int;
	@:native("helix_audio_channels") static function audioChannels():Int;
}
