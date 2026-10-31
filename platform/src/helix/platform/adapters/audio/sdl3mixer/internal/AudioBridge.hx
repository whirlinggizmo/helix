package helix.platform.adapters.audio.sdl3mixer.internal;

/** Provides the native audio output's C over SDL3_mixer (`audio_sdl3mixer.c`): clips, voices, streams, downloads and queues.

	hxcpp builds the C with the program; SDL3_mixer itself comes with `Sdl3MixerBridge`. */
@:buildXml("<set name='HELIX_PLATFORM' value='${haxelib:helix-platform}' unless='HELIX_PLATFORM'/>
<files id='helix-platform-audio-sdl3mixer' dir='${HELIX_PLATFORM}/src/helix/platform/adapters'>
 <compilerflag value='-I${HELIX_PLATFORM}/vendor/sdl3'/><compilerflag value='-I${HELIX_PLATFORM}/vendor/sdl3_mixer/include'/><compilerflag value='-I${HELIX_PLATFORM}/vendor/sdl3_mixer/src'/><compilerflag value='-I${HELIX_PLATFORM}/src/helix/platform/adapters/audio/sdl3mixer/internal'/>
 <compilerflag value='-DNDEBUG' unless='debug'/><compilerflag value='-O2' if='windows' unless='debug'/><compilerflag value='-O3' unless='windows||debug'/><compilerflag value='-D_POSIX_C_SOURCE=200809L' if='linux'/>
 <depend name='${HELIX_PLATFORM}/vendor/sdl3/SDL3/SDL.h'/><depend name='${HELIX_PLATFORM}/vendor/sdl3_mixer/include/SDL3_mixer/SDL_mixer.h'/><depend name='${HELIX_PLATFORM}/vendor/sdl3_mixer/src/SDL_mixer_internal.h'/><depend name='${HELIX_PLATFORM}/src/helix/platform/adapters/audio/sdl3mixer/internal/audio_sdl3mixer.h'/>
 <file name='audio/sdl3mixer/internal/audio_sdl3mixer.c'/>
</files>
<files id='haxe'><compilerflag value='-I${HELIX_PLATFORM}/src/helix/platform/adapters/audio/sdl3mixer/internal'/></files>
<target id='haxe'>
 <files id='helix-platform-audio-sdl3mixer'/>
</target>")
@:include("audio_sdl3mixer.h")
@:noCompletion
extern class AudioBridge {
	@:native("helix_audio_open") static function open(device:Int):Int;
	@:native("helix_audio_close") static function close():Void;
	@:native("helix_audio_clip") static function clip(samples:cpp.RawPointer<cpp.UInt8>, frames:Int, channels:Int):Int;
	@:native("helix_audio_dispose_clip") static function disposeClip(clip:Int):Int;
	@:native("helix_audio_play_clip") static function playClip(clip:Int, loop:Int, volume:cpp.Float32):Int;
	@:native("helix_audio_download") static function download(total:Int):Int;
	@:native("helix_audio_download_add") static function downloadAdd(download:Int, bytes:cpp.RawPointer<cpp.UInt8>, count:Int):Int;
	@:native("helix_audio_download_end") static function downloadEnd(download:Int):Void;
	@:native("helix_audio_download_release") static function downloadRelease(download:Int):Void;
	@:native("helix_audio_check_file") static function checkFile(path:cpp.ConstCharStar):Int;
	@:native("helix_audio_check_download") static function checkDownload(download:Int):Int;
	@:native("helix_audio_file_duration") static function fileDuration(path:cpp.ConstCharStar):Float;
	@:native("helix_audio_download_duration") static function downloadDuration(download:Int):Float;
	@:native("helix_audio_play_file") static function playFile(path:cpp.ConstCharStar, loop:Int, volume:cpp.Float32):Int;
	@:native("helix_audio_play_download") static function playDownload(download:Int, loop:Int, volume:cpp.Float32):Int;
	@:native("helix_audio_queue") static function queue(channels:Int, rate:Int):Int;
	@:native("helix_audio_queue_samples") static function queueSamples(queue:Int, samples:cpp.RawPointer<cpp.UInt8>, bytes:Int):Int;
	@:native("helix_audio_queued_frames") static function queuedFrames(queue:Int):Int;
	@:native("helix_audio_dispose_queue") static function disposeQueue(queue:Int):Int;
	@:native("helix_audio_play_queue") static function playQueue(queue:Int, volume:cpp.Float32):Int;
	@:native("helix_audio_feed") static function feed():Void;
	@:native("helix_audio_stop") static function stop(voice:Int):Void;
	@:native("helix_audio_pause") static function pause(voice:Int, paused:Int):Void;
	@:native("helix_audio_set_volume") static function setVolume(voice:Int, volume:cpp.Float32):Int;
	@:native("helix_audio_set_pitch") static function setPitch(voice:Int, pitch:cpp.Float32):Int;
	@:native("helix_audio_set_pan") static function setPan(voice:Int, pan:cpp.Float32):Int;
	@:native("helix_audio_is_playing") static function isPlaying(voice:Int):Int;
	@:native("helix_audio_position") static function position(voice:Int):Float;
	@:native("helix_audio_set_position") static function setPosition(voice:Int, seconds:Float):Int;
	@:native("helix_audio_is_sounding") static function isSounding(voice:Int):Int;
}
