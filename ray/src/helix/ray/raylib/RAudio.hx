package helix.ray.raylib;

#if !macro
import helix.ray.*;
import helix.ray.Raylib.*;
import helix.math.Matrix3D;
import helix.ray.internal.DefaultFont;
import helix.ray.internal.Models;
import helix.ray.internal.Runtime;
import helix.ray.internal.Textures;
import helix.ray.raylib.RCore.*;
import helix.ray.raylib.RShapes.*;
import helix.ray.raylib.RTextures.*;
import helix.ray.raylib.RText.*;
import helix.ray.raylib.RModels.*;
import helix.ray.raylib.RAudio.*;
import helix.ray.raylib.RMath.*;
import helix.ray.raylib.HelixRay.*;
#end

/** Holds raylib's raudio (sounds), written here; `Raylib` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
class RAudio {
	#if !macro
	// ---- Audio ----

	/** Opens the audio output, with helix-services' `Audio` over it. In a page it plays once the player's first press lets it. */
	public static function InitAudioDevice():Void {
		if (Runtime.audio != null)
			return;
		#if js
		var output = new helix.platform.adapters.audio.webaudio.WebAudioAdapter();
		var decoder = new helix.platform.adapters.audiodecoder.webaudio.WebAudioDecoderAdapter();
		#else
		var output = new helix.platform.adapters.audio.sdl3mixer.Sdl3MixerAudioAdapter();
		var decoder = new helix.platform.adapters.audiodecoder.sdl3mixer.Sdl3MixerAudioDecoderAdapter();
		#end
		Runtime.polled.push(output);
		Runtime.polled.push(decoder);
		Runtime.loading();
		var audio = new helix.services.audio.Audio(output, decoder, Runtime.assets, Runtime.system);
		Runtime.polled.push(audio);
		Runtime.output = output;
		Runtime.audioDecoder = decoder;
		Runtime.audio = audio;
	}

	/** Closes the audio output, stopping and unloading every sound. */
	public static function CloseAudioDevice():Void {
		if (Runtime.audio == null)
			return;
		for (p in ([Runtime.audio, Runtime.audioDecoder, Runtime.output] : Array<helix.platform.IPollable>))
			Runtime.polled.remove(p);
		Runtime.audio.dispose();
		Runtime.audioDecoder.dispose();
		Runtime.output.dispose();
		Runtime.audio = null;
		Runtime.audioDecoder = null;
		Runtime.output = null;
	}

	/** Returns whether the audio output is open.

		@return  True after `InitAudioDevice`, where the platform has an output. */
	public static function IsAudioDeviceReady():Bool {
		return Runtime.audio != null && Runtime.output.available;
	}

	/** Sets the volume of every sound.

		@param volume  0 (silent) to 1. */
	public static function SetMasterVolume(volume:Float):Void {
		if (Runtime.audio != null)
			Runtime.audio.master.volume = volume;
	}

	/** Returns the volume of every sound.

		@return  0 (silent) to 1. */
	public static function GetMasterVolume():Float {
		return Runtime.audio == null ? 1 : Runtime.audio.master.volume;
	}

	/** Loads a sound file whole. It decodes in the background; played before then, it starts once decoded. A file loaded again shares
		its first load's decoded sound.

		@param fileName  The file, as the program names it, such as "assets/coin.wav".
		@return  The sound. */
	public static function LoadSound(fileName:String):Sound {
		var sound = new Sound();
		if (Runtime.audio == null) {
			Runtime.log(4, 'LoadSound: InitAudioDevice first');
			return sound;
		}
		var path = normalize(fileName);
		sound.path = path;
		var entry = sounds.get(path);
		if (entry == null) {
			var made = {
				loaded: null,
				refs: 0,
				waiting: [],
				cancel: null,
				answers: []
			};
			entry = made;
			sounds.set(path, made);
			made.cancel = Runtime.audio.load(path, loaded -> {
				made.cancel = null;
				made.loaded = loaded;
				for (s in made.waiting)
					arrived(s, loaded);
				made.waiting = [];
				for (answer in made.answers)
					answer(null);
				made.answers = [];
			}, error -> {
				made.cancel = null;
				if (made.answers.length == 0)
					Runtime.log(4, 'LoadSound: $fileName: $error');
				for (answer in made.answers)
					answer(error);
				made.answers = [];
			});
		}
		entry.refs++;
		if (entry.loaded != null)
			sound.sound = entry.loaded;
		else
			entry.waiting.push(sound);
		return sound;
	}

	/** Frees a sound, stopping it: one load of its file, the decoded sound with the last.

		@param sound  The sound. */
	public static function UnloadSound(sound:Sound):Void {
		StopSound(sound);
		sound.unloaded = true;
		var entry = sounds.get(sound.path);
		sound.sound = null;
		if (entry == null)
			return;
		entry.waiting.remove(sound);
		if (--entry.refs > 0)
			return;
		sounds.remove(sound.path);
		if (entry.cancel != null)
			entry.cancel();
		if (entry.loaded != null && Runtime.audio != null)
			Runtime.audio.unload(entry.loaded);
	}

	// A sound's file decoded: it plays as often as it was asked to meanwhile.

	@:allow(helix.ray)
	static function arrived(sound:Sound, loaded:helix.services.audio.Sound):Void {
		if (sound.unloaded)
			return;
		sound.sound = loaded;
		for (_ in 0...sound.waiting)
			PlaySound(sound);
		sound.waiting = 0;
	}

	/** Returns whether a sound was loaded.

		@param sound  The sound.
		@return  True once it is decoded. */
	public static function IsSoundValid(sound:Sound):Bool {
		return sound.sound != null;
	}

	/** Plays a sound from its start, restarting it when it is already playing.

		@param sound  The sound. */
	public static function PlaySound(sound:Sound):Void {
		if (Runtime.audio == null || sound.unloaded)
			return;
		if (sound.sound == null) {
			sound.waiting++;
			return;
		}
		StopSound(sound);
		sound.voice = Runtime.audio.play(sound.sound, null, false, sound.volume);
		sound.voice.pitch = sound.pitch;
		sound.voice.pan = sound.pan * 2 - 1;
	}

	/** Stops a sound.

		@param sound  The sound. */
	public static function StopSound(sound:Sound):Void {
		if (sound.voice != null)
			sound.voice.stop();
		sound.voice = null;
	}

	/** Returns whether a sound is playing.

		@param sound  The sound.
		@return  True while it plays. */
	public static function IsSoundPlaying(sound:Sound):Bool {
		return sound.voice != null && sound.voice.playing;
	}

	/** Sets a sound's volume, for its next play and the one playing.

		@param sound  The sound.
		@param volume  0 (silent) to 1. */
	public static function SetSoundVolume(sound:Sound, volume:Float):Void {
		sound.volume = volume;
		if (sound.voice != null)
			sound.voice.volume = volume;
	}

	/** Sets a sound's pitch, for its next play and the one playing.

		@param sound  The sound.
		@param pitch  1 for as recorded, 2 an octave up. */
	public static function SetSoundPitch(sound:Sound, pitch:Float):Void {
		sound.pitch = pitch;
		if (sound.voice != null)
			sound.voice.pitch = pitch;
	}

	/** Sets where a sound is heard, for its next play and the one playing.

		@param sound  The sound.
		@param pan  0 for left, 0.5 the middle, 1 for right, as raylib's. */
	public static function SetSoundPan(sound:Sound, pan:Float):Void {
		sound.pan = pan;
		if (sound.voice != null)
			sound.voice.pan = pan * 2 - 1;
	}

	// ---- Music ----

	/** Opens a music file, to be played as it is read (helix-services' `Audio.stream`): natively from its file, in a page from the
		download as it arrives, so it is never loaded before `main`. It may be played at once; it starts once it opens.

		@param fileName  The file, as the program names it, such as "assets/theme.ogg".
		@return  The music. */
	public static function LoadMusicStream(fileName:String):Music {
		var music = new Music();
		if (Runtime.audio == null) {
			Runtime.log(4, 'LoadMusicStream: InitAudioDevice first');
			music.failed = true;
			return music;
		}
		var path = normalize(fileName);
		music.cancel = Runtime.audio.stream(path, opened -> {
			music.cancel = null;
			music.sound = opened;
			if (music.waiting) {
				music.waiting = false;
				PlayMusicStream(music);
			}
		}, error -> {
			music.cancel = null;
			music.failed = true;
			Runtime.log(4, 'LoadMusicStream: $fileName: $error');
		});
		return music;
	}

	/** Returns whether music was opened, or is still opening.

		@param music  The music.
		@return  False once its file couldn't be opened. */
	public static function IsMusicValid(music:Music):Bool {
		return !music.failed;
	}

	/** Stops music and closes it.

		@param music  The music. */
	public static function UnloadMusicStream(music:Music):Void {
		StopMusicStream(music);
		if (music.cancel != null)
			music.cancel();
		if (music.sound != null && Runtime.audio != null)
			Runtime.audio.unload(music.sound);
		music.cancel = null;
		music.sound = null;
		music.failed = true;
	}

	/** Plays music from its start, looping while its `looping` is true.

		@param music  The music. */
	public static function PlayMusicStream(music:Music):Void {
		if (Runtime.audio == null || music.failed)
			return;
		if (music.sound == null) {
			music.waiting = true;
			return;
		}
		StopMusicStream(music);
		var voice = Runtime.audio.play(music.sound, null, music.looping, music.volume);
		voice.pitch = music.pitch;
		voice.pan = music.pan * 2 - 1;
		music.voice = voice;
	}

	/** Returns whether music is playing, or will once it opens.

		@param music  The music.
		@return  True while it plays, paused or not. */
	public static function IsMusicStreamPlaying(music:Music):Bool {
		return music.waiting || music.voice != null && music.voice.playing;
	}

	/** Keeps music playing. raylib's programs call it each frame; here the stream feeds itself, so it does nothing.

		@param music  The music. */
	public static function UpdateMusicStream(music:Music):Void {}

	/** Stops music.

		@param music  The music. */
	public static function StopMusicStream(music:Music):Void {
		music.waiting = false;
		if (music.voice != null)
			music.voice.stop();
		music.voice = null;
	}

	/** Pauses music where it is.

		@param music  The music. */
	public static function PauseMusicStream(music:Music):Void {
		if (music.voice != null)
			music.voice.paused = true;
	}

	/** Resumes paused music.

		@param music  The music. */
	public static function ResumeMusicStream(music:Music):Void {
		if (music.voice != null)
			music.voice.paused = false;
	}

	/** Sets music's volume.

		@param music  The music.
		@param volume  0 (silent) to 1. */
	public static function SetMusicVolume(music:Music, volume:Float):Void {
		music.volume = volume;
		if (music.voice != null)
			music.voice.volume = volume;
	}

	/** Sets music's pitch.

		@param music  The music.
		@param pitch  1 for as recorded. */
	public static function SetMusicPitch(music:Music, pitch:Float):Void {
		music.pitch = pitch;
		if (music.voice != null)
			music.voice.pitch = pitch;
	}

	/** Sets where music is heard.

		@param music  The music.
		@param pan  0 for left, 0.5 the middle, 1 for right, as raylib's. */
	public static function SetMusicPan(music:Music, pan:Float):Void {
		music.pan = pan;
		if (music.voice != null)
			music.voice.pan = pan * 2 - 1;
	}
	#end
}
