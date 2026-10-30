package helix.ray.raylib;

/** Holds raudio: sounds, as members of `Raylib`: its build takes them from here (`helix.ray.internal.Sections`), and this class is left
	empty. */
@:noCompletion
@:build(helix.ray.internal.Sections.part("audio", "raudio: sound"))
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
		var assets = Runtime.assets != null ? Runtime.assets : new helix.services.assets.Assets({sources: []});
		var audio = new helix.services.audio.Audio(output, decoder, assets, Runtime.system);
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
			trace('LoadSound: InitAudioDevice first');
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
					trace('LoadSound: $fileName: $error');
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
	#end
}
