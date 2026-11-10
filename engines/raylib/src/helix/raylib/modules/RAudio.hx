package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.math.Matrix3D;
import helix.raylib.internal.AudioStreams;
import helix.raylib.internal.DefaultFont;
import helix.raylib.internal.FrameConverter;
import helix.raylib.internal.Models;
import helix.raylib.internal.Runtime;
import helix.raylib.internal.Textures;
import helix.raylib.modules.RCore.*;
import helix.raylib.modules.RShapes.*;
import helix.raylib.modules.RTextures.*;
import helix.raylib.modules.RText.*;
import helix.raylib.modules.RModels.*;
import helix.raylib.modules.RAudio.*;
import helix.raylib.modules.RMath.*;
#end

/** Provides raylib's raudio functions (sounds, waves, music and streams), each of which `Raylib` forwards to.

	`tools/gen_raylib.py` writes the forwarding. */
@:noCompletion
@:allow(helix.raylib)
class RAudio {
	#if !macro
	// ---- Audio ----

	/** Opens the audio output, with helix-services' `Audio` over it.

		Sound may wait to play until a first key press, click or tap.

		Does nothing when the output is already open. */
	static function InitAudioDevice():Void {
		if (Runtime.audio != null)
			return;
		#if js
		var output = new helix.platform.adapters.audio.webaudio.WebAudioAdapter();
		#else
		var output = new helix.platform.adapters.audio.sdl3mixer.Sdl3MixerAudioAdapter();
		#end
		Runtime.polled.push(output);
		var decoder = audioDecoder();
		Runtime.loading();
		var audio = new helix.services.audio.Audio(output, decoder, Runtime.assets, Runtime.system);
		Runtime.polled.push(audio);
		Runtime.output = output;
		Runtime.audio = audio;
	}

	/** Closes the audio output, stopping and unloading every sound.

		Does nothing when the output isn't open. */
	static function CloseAudioDevice():Void {
		if (Runtime.audio == null)
			return;
		for (p in ([Runtime.audio, Runtime.audioDecoder, Runtime.output] : Array<helix.platform.IPollable>))
			Runtime.polled.remove(p);
		if (streams != null) {
			Runtime.polled.remove(streams);
			for (stream in streams.streams)
				stream.voice = null;
			streams = null;
		}
		Runtime.audio.dispose();
		Runtime.audioDecoder.dispose();
		Runtime.output.dispose();
		Runtime.audio = null;
		Runtime.audioDecoder = null;
		Runtime.output = null;
	}

	/** Returns whether the audio output is open.

		@return  True after `InitAudioDevice`, where the platform has an output. */
	static function IsAudioDeviceReady():Bool {
		return Runtime.audio != null && Runtime.output.available;
	}

	/** Sets the volume of every sound.

		Ignored before `InitAudioDevice`.

		@param volume  0 (silent) to 1. */
	static function SetMasterVolume(volume:Float):Void {
		if (Runtime.audio != null)
			Runtime.audio.master.volume = volume;
	}

	/** Returns the volume of every sound.

		@return  0 (silent) to 1, or 1 before `InitAudioDevice`. */
	static function GetMasterVolume():Float {
		return Runtime.audio == null ? 1 : Runtime.audio.master.volume;
	}

	// The platform's decoder, made when first needed: by InitAudioDevice, or by a wave's load before it.
	static function audioDecoder():helix.platform.IAudioDecoder {
		if (Runtime.audioDecoder == null) {
			#if js
			Runtime.audioDecoder = new helix.platform.adapters.audiodecoder.webaudio.WebAudioDecoderAdapter();
			#else
			Runtime.audioDecoder = new helix.platform.adapters.audiodecoder.sdl3mixer.Sdl3MixerAudioDecoderAdapter();
			#end
			Runtime.polled.push(Runtime.audioDecoder);
		}
		return Runtime.audioDecoder;
	}

	// ---- Waves ----

	/** Doesn't compile on any target, as raylib's wave load waits for the file. See `LoadWaveAsync` for loading a wave file.

		@param fileName  The file.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("LoadWave: Synchronous loading is not supported. See LoadWaveAsync(fileName:String, loaded:Wave->Void, ?failed:String->Void)")
	static function LoadWave(fileName:String):Wave {
		throw "LoadWave is unimplemented";
	}

	/** Doesn't compile on any target, as raylib's wave load from a file's bytes answers at once. See `LoadWaveFromMemoryAsync` for loading a wave from a file's bytes.

		A file other than WAV or QOA is decoded off the main thread.

		@param fileType  The file's extension.
		@param fileData  The file's bytes.
		@param dataSize  How many of them.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("LoadWaveFromMemory: Decoding is asynchronous. See LoadWaveFromMemoryAsync(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, loaded:Wave->Void, ?failed:String->Void)")
	static function LoadWaveFromMemory(fileType:String, fileData:haxe.io.Bytes, dataSize:Int):Wave {
		throw "LoadWaveFromMemory is unimplemented";
	}

	/** Returns whether a wave holds samples.

		@param wave  The wave.
		@return  True when it has data, frames, a rate, a sample size and channels. */
	static function IsWaveValid(wave:Wave):Bool {
		return wave.data != null && wave.frameCount > 0 && wave.sampleRate > 0 && wave.sampleSize > 0 && wave.channels > 0;
	}

	/** Frees a wave's samples, leaving its `data` null.

		@param wave  The wave. */
	static function UnloadWave(wave:Wave):Void {
		wave.data = null;
	}

	/** Doesn't compile on any target, as raylib's wave export is done when it returns. See `ExportWaveAsync` for writing a wave to a sound file.

		A file is kept later, once written.

		@param wave  The wave.
		@param fileName  The file.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("ExportWave: A file is written later, or is refused. See ExportWaveAsync(wave:Wave, fileName:String, ?done:Void->Void, ?failed:String->Void)")
	static function ExportWave(wave:Wave, fileName:String):Bool {
		throw "ExportWave is unimplemented";
	}

	// ExportWaveAsync's file: a WAV file or the raw samples, by the name's extension; null for another, or a wave with no samples.
	static function waveFile(wave:Wave, fileName:String):Null<haxe.io.Bytes> {
		if (wave.data == null)
			return null;
		if (IsFileExtension(fileName, ".wav"))
			return try helix.formats.wav.WavFile.write(wave.sampleRate, wave.channels, wave.sampleSize, wave.frameCount,
				padded(wave.data, waveBytes(wave))) catch (_:Dynamic) null;
		if (IsFileExtension(fileName, ".raw"))
			return padded(wave.data, waveBytes(wave));
		return null;
	}

	/** Doesn't compile on any target, as raylib's export of a wave as code is done when it returns. See `ExportWaveAsCodeAsync` for writing a wave as a C header.

		A file is kept later, once written.

		@param wave  The wave.
		@param fileName  The file.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("ExportWaveAsCode: A file is written later, or is refused. See ExportWaveAsCodeAsync(wave:Wave, fileName:String, ?done:Void->Void, ?failed:String->Void)")
	static function ExportWaveAsCode(wave:Wave, fileName:String):Bool {
		throw "ExportWaveAsCode is unimplemented";
	}

	// ExportWaveAsCodeAsync's text, as raylib's writes it.
	static function waveAsCode(wave:Wave, fileName:String):String {
		var waveDataSize = waveBytes(wave);
		var text = new StringBuf();
		text.add("\n//////////////////////////////////////////////////////////////////////////////////\n");
		text.add("//                                                                              //\n");
		text.add("// WaveAsCode exporter v1.1 - Wave data exported as an array of bytes           //\n");
		text.add("//                                                                              //\n");
		text.add("// more info and bugs-report:  github.com/raysan5/raylib                        //\n");
		text.add("// feedback and support:       ray[at]raylib.com                                //\n");
		text.add("//                                                                              //\n");
		text.add("// Copyright (c) 2018-2024 Ramon Santamaria (@raysan5)                          //\n");
		text.add("//                                                                              //\n");
		text.add("//////////////////////////////////////////////////////////////////////////////////\n\n");
		var name = new StringBuf(), base = GetFileNameWithoutExt(fileName);
		for (i in 0...base.length) {
			var c = StringTools.fastCodeAt(base, i);
			name.addChar(c >= "a".code && c <= "z".code ? c - 32 : c);
		}
		var varName = name.toString();
		text.add("// Wave data information\n");
		text.add('#define ${varName}_FRAME_COUNT      ${unsigned(wave.frameCount)}\n');
		text.add('#define ${varName}_SAMPLE_RATE      ${unsigned(wave.sampleRate)}\n');
		text.add('#define ${varName}_SAMPLE_SIZE      ${unsigned(wave.sampleSize)}\n');
		text.add('#define ${varName}_CHANNELS         ${unsigned(wave.channels)}\n\n');
		var data = wave.data;
		if (wave.sampleSize == 32) {
			var count = Std.int(waveDataSize / 4);
			inline function at(i:Int):String
				return TextFormat("%.4f", data != null && i >= 0 && i * 4 + 4 <= data.length ? data.getFloat(i * 4) : 0.);
			text.add('static float ${varName}_DATA[$count] = {\n');
			for (i in 1...count)
				text.add(i % 20 == 0 ? '${at(i - 1)}f,\n    ' : '${at(i - 1)}f, ');
			text.add('${at(count - 1)}f };\n');
		} else {
			inline function at(i:Int):String
				return StringTools.hex(data != null && i >= 0 && i < data.length ? data.get(i) : 0).toLowerCase();
			text.add('static unsigned char ${varName}_DATA[$waveDataSize] = { ');
			for (i in 1...waveDataSize)
				text.add(i % 20 == 0 ? '0x${at(i - 1)},\n    ' : '0x${at(i - 1)}, ');
			text.add('0x${at(waveDataSize - 1)} };\n');
		}
		return text.toString();
	}

	/** Returns a copy of a wave, with samples of its own.

		@param wave  The wave.
		@return  The copy. */
	static function WaveCopy(wave:Wave):Wave {
		var size = waveBytes(wave);
		return new Wave(wave.frameCount, wave.sampleRate, wave.sampleSize, wave.channels, padded(wave.data, size).sub(0, size));
	}

	/** Crops a wave to a range of its frames, from `initFrame` up to `finalFrame`, not including it.

		A range outside the wave, or an empty one, changes nothing and logs a warning.

		@param wave  The wave, changed in place.
		@param initFrame  The first frame kept.
		@param finalFrame  The frame after the last one kept, at most `frameCount`. */
	static function WaveCrop(wave:Wave, initFrame:Int, finalFrame:Int):Void {
		if (initFrame >= 0 && initFrame < finalFrame && finalFrame <= wave.frameCount) {
			var frameCount = finalFrame - initFrame;
			var frameBytes = wave.channels * wave.sampleSize / 8;
			var start = Std.int(initFrame * frameBytes),
				size = Std.int(frameCount * wave.channels * wave.sampleSize / 8);
			var data = haxe.io.Bytes.alloc(size);
			var from = wave.data;
			if (from != null)
				data.blit(0, from, start, Std.int(Math.max(0, Math.min(size, from.length - start))));
			wave.data = data;
			wave.frameCount = frameCount;
		} else
			Runtime.log(LOG_WARNING, "WAVE: Crop range out of bounds");
	}

	/** Converts a wave's samples to another rate, sample size and channel count, as raylib's does through miniaudio.

		The conversion:

		- turns integers to floats and back without dithering.
		- mixes channels by miniaudio's standard speaker layouts.
		- changes the rate by miniaudio's linear resampler, low-pass filtered.

		A wave that can't be converted is unchanged, and a warning is logged.

		@param wave  The wave, changed in place.
		@param sampleRate  The frames a second.
		@param sampleSize  The bits a sample takes: 8, 16 or 32.
		@param channels  The number of channels. */
	static function WaveFormat(wave:Wave, sampleRate:Int, sampleSize:Int, channels:Int):Void {
		var frameCountIn = wave.frameCount;
		var frameCount = FrameConverter.expectedFrames(frameCountIn, wave.sampleSize, wave.channels, wave.sampleRate, sampleSize, channels, sampleRate);
		if (frameCount == 0) {
			Runtime.log(LOG_WARNING, "WAVE: Failed to get frame count for format conversion");
			return;
		}
		var data = haxe.io.Bytes.alloc(frameCount * channels * Std.int(sampleSize / 8));
		frameCount = FrameConverter.convert(data, frameCount, sampleSize, channels, sampleRate, wave.data == null ? haxe.io.Bytes.alloc(0) : wave.data,
			frameCountIn, wave.sampleSize, wave.channels, wave.sampleRate);
		if (frameCount == 0) {
			Runtime.log(LOG_WARNING, "WAVE: Failed format conversion");
			return;
		}
		wave.frameCount = frameCount;
		wave.sampleSize = sampleSize;
		wave.sampleRate = sampleRate;
		wave.channels = channels;
		wave.data = data;
	}

	/** Returns a wave's samples as numbers from -1 to 1, as raylib's does.

		Each sample size maps as:

		- 8-bit: less 128, over 128.
		- 16-bit: over 32768.
		- 32-bit: unchanged.
		- any other size: 0.

		@param wave  The wave.
		@return  `frameCount * channels` samples, interleaved. */
	static function LoadWaveSamples(wave:Wave):Array<Float> {
		var count = wave.frameCount * wave.channels, data = wave.data;
		var samples = [for (_ in 0...count) 0.];
		if (data == null)
			return samples;
		for (i in 0...count) {
			if (wave.sampleSize == 8 && i < data.length)
				samples[i] = (data.get(i) - 128) / 128;
			else if (wave.sampleSize == 16 && i * 2 + 2 <= data.length)
				samples[i] = ((data.getUInt16(i * 2) << 16) >> 16) / 32768;
			else if (wave.sampleSize == 32 && i * 4 + 4 <= data.length)
				samples[i] = data.getFloat(i * 4);
		}
		return samples;
	}

	/** Frees samples `LoadWaveSamples` returned.

		Does nothing, as there is nothing to free.

		@param samples  The samples. */
	static function UnloadWaveSamples(samples:Array<Float>):Void {}

	// A wave's bytes, as raylib counts them: frames times channels times bits, over 8.
	static function waveBytes(wave:Wave):Int {
		return Std.int(wave.frameCount * wave.channels * wave.sampleSize / 8);
	}

	// Bytes at least size long: the data itself when it is, else a copy padded with zeros.
	static function padded(data:Null<haxe.io.Bytes>, size:Int):haxe.io.Bytes {
		if (data != null && data.length >= size)
			return data;
		var out = haxe.io.Bytes.alloc(size < 0 ? 0 : size);
		if (data != null)
			out.blit(0, data, 0, data.length);
		return out;
	}

	// An Int as C's %u writes it.
	static function unsigned(value:Int):String {
		return value < 0 ? Std.string(value + 4294967296.0) : Std.string(value);
	}

	// ---- Sounds ----

	/** Doesn't compile on any target, as raylib's sound load waits for the file. See `LoadSoundAsync` for loading a sound file.

		@param fileName  The file.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("LoadSound: Synchronous loading is not supported. See LoadSoundAsync(fileName:String, loaded:Sound->Void, ?failed:String->Void)")
	static function LoadSound(fileName:String):Sound {
		throw "LoadSound is unimplemented";
	}

	/** Returns a sound made from a wave, ready to play at once.

		`InitAudioDevice` must come first.

		The samples are converted to 32-bit floats at 44100 Hz. A wave with 1 or 2 channels keeps them, and one with more is mixed to 2.

		@param wave  The wave. It is unchanged, and may be unloaded after.
		@return  The sound, or one that isn't valid (`IsSoundValid`) when the wave has no samples or can't be converted. */
	static function LoadSoundFromWave(wave:Wave):Sound {
		var sound = new Sound();
		if (wave.data == null)
			return sound;
		if (Runtime.audio == null) {
			Runtime.log(LOG_WARNING, "SOUND: Failed to create buffer: InitAudioDevice first");
			return sound;
		}
		var channels = wave.channels < 2 ? 1 : 2;
		var frameCount = FrameConverter.expectedFrames(wave.frameCount, wave.sampleSize, wave.channels, wave.sampleRate, 32, channels, 44100);
		if (frameCount == 0) {
			Runtime.log(LOG_WARNING, "SOUND: Failed to get frame count for format conversion");
			return sound;
		}
		var samples = haxe.io.Bytes.alloc(frameCount * channels * 4);
		var converted = FrameConverter.convert(samples, frameCount, 32, channels, 44100, wave.data, wave.frameCount, wave.sampleSize, wave.channels,
			wave.sampleRate);
		if (converted == 0)
			Runtime.log(LOG_WARNING, "SOUND: Failed format conversion");
		made(sound, samples, channels);
		sound.frameCount = converted;
		return sound;
	}

	/** Returns an alias that plays another sound's samples with its own volume, pitch, pan and voice, as raylib's does.

		Takes no memory for samples of its own. Holds a reference to its source's samples, so it plays on after the source is unloaded;
		they're freed when the last held reference, a load or an alias, is released.

		@param source  The sound whose samples it plays.
		@return  The alias, or one that isn't valid when the source isn't loaded. */
	static function LoadSoundAlias(source:Sound):Sound {
		var owner = source.source != null ? source.source : source;
		var alias = new Sound();
		if (owner.sound == null || owner.unloaded) {
			Runtime.log(LOG_WARNING, "SOUND: Failed to create buffer");
			return alias;
		}
		alias.source = owner;
		alias.sound = owner.sound;
		alias.frameCount = owner.frameCount;
		alias.volume = owner.volume;
		owner.aliases.push(alias);
		// A share of a file's decoded sound, as each load holds one.
		var entry = owner.path == "" ? null : sounds.get(owner.path);
		if (entry != null)
			entry.refs++;
		return alias;
	}

	// A sound file, loaded whole for `LoadSoundAsync`: it decodes in the background, and played before then, it starts once decoded. A
	// file loaded again shares its first load's decoded sound.

	static function loadSound(fileName:String):Sound {
		var sound = new Sound();
		if (Runtime.audio == null) {
			Runtime.log(4, 'LoadSoundAsync: InitAudioDevice first');
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
					Runtime.log(4, 'LoadSoundAsync: $error');
				for (answer in made.answers)
					answer(error);
				made.answers = [];
			});
		}
		entry.refs++;
		if (entry.loaded != null)
			arrived(sound, entry.loaded);
		else
			entry.waiting.push(sound);
		return sound;
	}

	/** Frees a sound, stopping it.

		Releases the sound's reference to its samples; they're freed when the last held reference, a load or an alias, is released:

		- a sound loaded from a file: its load's reference to the file's decoded sound.
		- a sound made from a wave: its own reference to its samples.
		- an alias: as `UnloadSoundAlias` releases it.

		Its aliases play on.

		@param sound  The sound. */
	static function UnloadSound(sound:Sound):Void {
		if (sound.source != null) {
			UnloadSoundAlias(sound);
			return;
		}
		StopSound(sound);
		sound.unloaded = true;
		var service = sound.sound;
		sound.sound = null;
		if (sound.path == "") {
			// Made from a wave: its samples are freed once its aliases are unloaded too.
			sound.held = service;
			freeHeld(sound);
			return;
		}
		release(sound);
	}

	/** Frees an alias, stopping it, and releases its reference to its source's samples. They're freed when it held the last.

		@param alias  The alias. */
	static function UnloadSoundAlias(alias:Sound):Void {
		StopSound(alias);
		if (alias.unloaded)
			return;
		alias.unloaded = true;
		alias.sound = null;
		var owner = alias.source;
		if (owner == null)
			return;
		owner.aliases.remove(alias);
		if (owner.path != "")
			release(alias, owner.path);
		else if (owner.unloaded)
			freeHeld(owner);
	}

	// Frees an unloaded sound made from a wave once no alias holds its samples.
	static function freeHeld(owner:Sound):Void {
		if (owner.aliases.length > 0)
			return;
		owner.samples = null;
		if (owner.held != null && Runtime.audio != null)
			Runtime.audio.unload(owner.held);
		owner.held = null;
	}

	// Lets go of a sound's share of its file's decoded sound, the last share unloading it.
	static function release(sound:Sound, ?path:String):Void {
		var entry = sounds.get(path == null ? sound.path : path);
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
		sound.frameCount = Math.round(loaded.duration * 44100);
		for (_ in 0...sound.waiting)
			PlaySound(sound);
		sound.waiting = 0;
	}

	// A sound given its own samples, made into the service's sound: it then holds them, for UpdateSound.
	static function made(sound:Sound, samples:haxe.io.Bytes, channels:Int):Void {
		sound.sound = Runtime.audio.createSound(samples, channels);
		sound.samples = samples;
		sound.path = "";
		sound.frameCount = Std.int(samples.length / (4 * channels));
	}

	/** Returns whether a sound is loaded.

		@param sound  The sound.
		@return  True once it is decoded or made, until it is unloaded. */
	static function IsSoundValid(sound:Sound):Bool {
		return sound.sound != null;
	}

	/** Writes new samples over the start of a sound and stops it, as raylib's does.

		The sound's length is unchanged. Its aliases play the new samples.

		@param sound  The sound, or one of its aliases.
		@param data  32-bit float samples at 44100 Hz in the sound's channels (a wave's channels, when 1 or 2), interleaved.
		@param sampleCount  How many frames to write, at most the sound's `frameCount`. The frames after them keep their samples; for a
			sound loaded from a file, whose samples aren't held, they are silent. */
	static function UpdateSound(sound:Sound, data:haxe.io.Bytes, sampleCount:Int):Void {
		var owner = sound.source != null ? sound.source : sound;
		var service = owner.sound;
		if (service == null || Runtime.audio == null || data == null)
			return;
		StopSound(sound);
		var channels = service.channelCount;
		var samples = owner.samples != null ? owner.samples : haxe.io.Bytes.alloc(Std.int(Math.max(1, Math.round(service.duration * 44100))) * channels * 4);
		var bytes = Std.int(Math.min(Math.min(sampleCount * channels * 4, data.length), samples.length));
		if (bytes > 0)
			samples.blit(0, data, 0, bytes);
		var path = owner.path;
		var frames = owner.frameCount;
		made(owner, samples, channels);
		owner.frameCount = frames;
		if (path == "")
			Runtime.audio.unload(service);
		else
			release({
				var held = new Sound();
				held.path = path;
				held;
			});
		for (alias in owner.aliases)
			alias.sound = owner.sound;
	}

	/** Plays a sound from its start, restarting it when it is already playing.

		A sound still decoding starts once decoded, once for each play asked for meanwhile.

		Ignored before `InitAudioDevice`, and once the sound is unloaded.

		@param sound  The sound. */
	static function PlaySound(sound:Sound):Void {
		if (Runtime.audio == null || sound.unloaded)
			return;
		if (sound.sound == null) {
			if (sound.source == null)
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
	static function StopSound(sound:Sound):Void {
		if (sound.voice != null)
			sound.voice.stop();
		sound.voice = null;
	}

	/** Pauses a sound where it is.

		@param sound  The sound. */
	static function PauseSound(sound:Sound):Void {
		if (sound.voice != null)
			sound.voice.paused = true;
	}

	/** Resumes a paused sound.

		@param sound  The sound. */
	static function ResumeSound(sound:Sound):Void {
		if (sound.voice != null)
			sound.voice.paused = false;
	}

	/** Returns whether a sound is playing.

		@param sound  The sound.
		@return  True while it plays. False while it is paused, as raylib's is. */
	static function IsSoundPlaying(sound:Sound):Bool {
		return sound.voice != null && sound.voice.playing && !sound.voice.paused;
	}

	/** Sets a sound's volume, for the play under way and the next.

		@param sound  The sound.
		@param volume  0 (silent) to 1. */
	static function SetSoundVolume(sound:Sound, volume:Float):Void {
		sound.volume = volume;
		if (sound.voice != null)
			sound.voice.volume = volume;
	}

	/** Sets a sound's pitch, for the play under way and the next, speeding or slowing the sound with it.

		The pitch is absolute, whatever was set before, so 1 sets the sound back to as recorded.

		Clamped to 0.25 to 4, the platform's range.

		@param sound  The sound.
		@param pitch  1 for as recorded, 2 an octave up. */
	static function SetSoundPitch(sound:Sound, pitch:Float):Void {
		sound.pitch = pitch;
		if (sound.voice != null)
			sound.voice.pitch = pitch;
	}

	/** Sets where a sound is heard, for the play under way and the next.

		The range is raylib 5.5's, 0 to 1 with 0.5 the middle and 1 the right.

		@param sound  The sound.
		@param pan  0 for left, 0.5 the middle, 1 for right. */
	static function SetSoundPan(sound:Sound, pan:Float):Void {
		sound.pan = pan;
		if (sound.voice != null)
			sound.voice.pan = pan * 2 - 1;
	}

	// ---- Music ----

	/** Doesn't compile on any target, as raylib's music load knows at once whether the file opened. See `LoadMusicStreamAsync` for opening a music file.

		@param fileName  The file.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("LoadMusicStream: Synchronous loading is not supported. See LoadMusicStreamAsync(fileName:String, loaded:Music->Void, ?failed:String->Void)")
	static function LoadMusicStream(fileName:String):Music {
		throw "LoadMusicStream is unimplemented";
	}

	/** Returns music opened from a file's bytes, to be played as it is read.

		`InitAudioDevice` must come first.

		A FLAC file (".flac" or ".FLAC") is refused, as raylib 5.5's default build leaves FLAC out. The music is invalid, and "STREAM: Data format not supported" is logged.

		@param fileType  The file's extension, such as ".ogg": Ogg Vorbis, MP3 or WAV.
		@param data  The file's bytes; they are kept until the music is unloaded.
		@param dataSize  How many of them.
		@return  The music. */
	static function LoadMusicStreamFromMemory(fileType:String, data:haxe.io.Bytes, dataSize:Int):Music {
		var music = new Music();
		if (Runtime.audio == null || data == null || dataSize <= 0 || fileType == ".flac" || fileType == ".FLAC") {
			var flac = fileType == ".flac" || fileType == ".FLAC";
			Runtime.log(LOG_WARNING, Runtime.audio == null
				&& !flac ? 'LoadMusicStreamFromMemory: InitAudioDevice first' : 'STREAM: Data format not supported');
			music.failed = true;
			return music;
		}
		var path = Runtime.memory.add(dataSize < data.length ? data.sub(0, dataSize) : data, fileType == null ? "" : fileType);
		open(music, path, 'LoadMusicStreamFromMemory: $fileType');
		return music;
	}

	// Opens music's stream by its path, answering opened or failed when given, or logging the failure under name; a play asked for
	// meanwhile starts once it opens.
	static function open(music:Music, path:String, name:String, ?opened:Void->Void, ?failed:String->Void):Void {
		music.cancel = Runtime.audio.stream(path, sound -> {
			music.cancel = null;
			music.sound = sound;
			if (music.waiting) {
				music.waiting = false;
				PlayMusicStream(music);
			}
			if (opened != null)
				opened();
		}, error -> {
			music.cancel = null;
			music.failed = true;
			if (failed != null)
				failed(error);
			else
				Runtime.log(4, '$name: $error');
		});
	}

	/** Returns whether music is open, or still opening.

		@param music  The music.
		@return  False once its file couldn't be opened, or once it is unloaded. */
	static function IsMusicValid(music:Music):Bool {
		return !music.failed;
	}

	/** Stops music and closes it.

		@param music  The music. */
	static function UnloadMusicStream(music:Music):Void {
		StopMusicStream(music);
		if (music.cancel != null)
			music.cancel();
		if (music.sound != null && Runtime.audio != null)
			Runtime.audio.unload(music.sound);
		music.cancel = null;
		music.sound = null;
		music.failed = true;
	}

	/** Plays music from its start, or from where `SeekMusicStream` moved it, looping while its `looping` is true.

		Music still opening starts once it opens.

		@param music  The music. */
	static function PlayMusicStream(music:Music):Void {
		if (Runtime.audio == null || music.failed)
			return;
		if (music.sound == null) {
			music.waiting = true;
			return;
		}
		var seek = music.seek;
		StopMusicStream(music);
		var voice = Runtime.audio.play(music.sound, null, music.looping, music.volume);
		voice.pitch = music.pitch;
		voice.pan = music.pan * 2 - 1;
		music.voice = voice;
		if (seek >= 0)
			voice.setPosition(seek);
	}

	/** Returns whether music is playing, or will once it opens.

		@param music  The music.
		@return  True while it plays. False while it is paused, as raylib's is. */
	static function IsMusicStreamPlaying(music:Music):Bool {
		return music.waiting || music.voice != null && music.voice.playing && !music.voice.paused;
	}

	/** Does nothing, as the stream feeds itself.

		Music that doesn't loop is heard to its last sample, and stops then.

		@param music  The music. */
	static function UpdateMusicStream(music:Music):Void {}

	/** Stops music, so its next play starts from its beginning.

		@param music  The music. */
	static function StopMusicStream(music:Music):Void {
		music.waiting = false;
		music.seek = -1;
		if (music.voice != null)
			music.voice.stop();
		music.voice = null;
	}

	/** Pauses music where it is.

		@param music  The music. */
	static function PauseMusicStream(music:Music):Void {
		if (music.voice != null)
			music.voice.paused = true;
	}

	/** Resumes paused music.

		@param music  The music. */
	static function ResumeMusicStream(music:Music):Void {
		if (music.voice != null)
			music.voice.paused = false;
	}

	/** Moves music to a position.

		Music not playing starts there when next played.

		Music streamed from a server moves only as far as the server's range requests reach.

		@param music  The music.
		@param position  The position, in seconds from its start, clamped to 0 or more. */
	static function SeekMusicStream(music:Music, position:Float):Void {
		if (music.voice != null && music.voice.playing)
			music.voice.setPosition(position < 0 ? 0 : position);
		else
			music.seek = position < 0 ? 0 : position;
	}

	/** Sets music's volume.

		@param music  The music.
		@param volume  0 (silent) to 1. */
	static function SetMusicVolume(music:Music, volume:Float):Void {
		music.volume = volume;
		if (music.voice != null)
			music.voice.volume = volume;
	}

	/** Sets music's pitch, absolute whatever was set before, as `SetSoundPitch` sets a sound's.

		Clamped to 0.25 to 4.

		@param music  The music.
		@param pitch  1 for as recorded. */
	static function SetMusicPitch(music:Music, pitch:Float):Void {
		music.pitch = pitch;
		if (music.voice != null)
			music.voice.pitch = pitch;
	}

	/** Sets where music is heard, in `SetSoundPan`'s range, with 1 the right.

		@param music  The music.
		@param pan  0 for left, 0.5 the middle, 1 for right. */
	static function SetMusicPan(music:Music, pan:Float):Void {
		music.pan = pan;
		if (music.voice != null)
			music.voice.pan = pan * 2 - 1;
	}

	/** Returns music's length (helix-services' `Sound.duration`).

		Known once the music opens from a file. A server's file's length is known once its start and its last 64 KiB have arrived.

		@param music  The music.
		@return  The length, in seconds, or 0 while it isn't known. */
	static function GetMusicTimeLength(music:Music):Float {
		return music.sound == null ? 0 : music.sound.duration;
	}

	/** Returns how far music has played, back to 0 at each loop, as raylib's does.

		Holds while paused. Is 0 once stopped, or once played to its end without looping, and starts from 0 when played again.

		@param music  The music.
		@return  The position, in seconds from its start. */
	static function GetMusicTimePlayed(music:Music):Float {
		return music.voice == null ? 0 : music.voice.position;
	}

	// ---- Audio streams ----

	/** Returns a stream that plays samples the program makes as it goes, each buffer as `UpdateAudioStream` gives it.

		`InitAudioDevice` must come first.

		Played through helix-services' `SampleQueue`, which the platform resamples.

		@param sampleRate  The frames a second, 8000 to 96000.
		@param sampleSize  The bits a sample takes: 8 (unsigned), 16 (signed) or 32 (float).
		@param channels  The number of channels, 1 or 2.
		@return  The stream, or one that isn't valid (`IsAudioStreamValid`) when it can't be made. */
	static function LoadAudioStream(sampleRate:Int, sampleSize:Int, channels:Int):AudioStream {
		var stream = new AudioStream(sampleRate, sampleSize, channels);
		stream.bufferFrames = bufferSizeDefault == 0 ? Std.int(44100 / 30) : bufferSizeDefault;
		if (Runtime.audio != null)
			stream.queue = try Runtime.audio.createSampleQueue(channels, sampleRate) catch (_:Dynamic) null;
		if (stream.queue != null)
			Runtime.log(LOG_INFO, 'STREAM: Initialized successfully ($sampleRate Hz, $sampleSize bit, ${channels == 1 ? "Mono" : "Stereo"})');
		else
			Runtime.log(LOG_WARNING, "STREAM: Failed to load audio buffer, stream could not be created");
		return stream;
	}

	/** Returns whether a stream is open.

		@param stream  The stream.
		@return  True when it has its queue, a rate, a sample size and channels. */
	static function IsAudioStreamValid(stream:AudioStream):Bool {
		return stream.queue != null && stream.sampleRate > 0 && stream.sampleSize > 0 && stream.channels > 0;
	}

	/** Closes a stream, stopping it.

		@param stream  The stream. */
	static function UnloadAudioStream(stream:AudioStream):Void {
		if (streams != null)
			streams.streams.remove(stream);
		if (stream.queue != null)
			stream.queue.dispose();
		stream.queue = null;
		stream.voice = null;
		Runtime.log(LOG_INFO, "STREAM: Unloaded audio stream data from RAM");
	}

	/** Gives a stream its next buffer of samples, as raylib's does, filling the rest of the buffer with silence.

		Taken only once a buffer has been heard (`IsAudioStreamProcessed`), and only up to a buffer's frames (`SetAudioStreamBufferSizeDefault`). Otherwise nothing is taken, and a warning is logged.

		@param stream  The stream.
		@param data  The samples in the stream's sample size and channels, interleaved.
		@param frameCount  How many frames. */
	static function UpdateAudioStream(stream:AudioStream, data:haxe.io.Bytes, frameCount:Int):Void {
		if (stream.queue == null)
			return;
		if (!IsAudioStreamProcessed(stream)) {
			Runtime.log(LOG_WARNING, "STREAM: Buffer not available for updating");
			return;
		}
		if (frameCount > stream.bufferFrames) {
			Runtime.log(LOG_WARNING, "STREAM: Attempting to write too many frames to buffer");
			return;
		}
		queueBuffer(stream, data, frameCount);
	}

	/** Returns whether a stream has room for another buffer, as raylib's double buffer has one free.

		@param stream  The stream.
		@return  True while it holds no more than one buffer not yet heard, when `UpdateAudioStream` would take samples. */
	static function IsAudioStreamProcessed(stream:AudioStream):Bool {
		return stream.queue != null && stream.queue.queuedFrameCount <= stream.bufferFrames;
	}

	/** Plays a stream: what it holds, and what it is given after.

		A stream with a callback (`SetAudioStreamCallback`) is filled by it at once.

		@param stream  The stream. */
	static function PlayAudioStream(stream:AudioStream):Void {
		if (stream.queue == null || Runtime.audio == null)
			return;
		var voice = stream.queue.play(null, stream.volume);
		voice.pitch = stream.pitch;
		voice.pan = stream.pan * 2 - 1;
		stream.voice = voice;
		topUp(stream);
	}

	/** Pauses a stream where it is.

		@param stream  The stream. */
	static function PauseAudioStream(stream:AudioStream):Void {
		if (stream.voice != null)
			stream.voice.paused = true;
	}

	/** Resumes a paused stream.

		@param stream  The stream. */
	static function ResumeAudioStream(stream:AudioStream):Void {
		if (stream.voice != null)
			stream.voice.paused = false;
	}

	/** Returns whether a stream is playing.

		@param stream  The stream.
		@return  True while it plays, even when it has run out of samples. False while it is paused, as raylib's is. */
	static function IsAudioStreamPlaying(stream:AudioStream):Bool {
		return stream.voice != null && stream.voice.playing && !stream.voice.paused;
	}

	/** Stops a stream, dropping the samples it hasn't played.

		@param stream  The stream. */
	static function StopAudioStream(stream:AudioStream):Void {
		if (stream.voice != null)
			stream.voice.stop();
		stream.voice = null;
	}

	/** Sets a stream's volume.

		@param stream  The stream.
		@param volume  0 (silent) to 1. */
	static function SetAudioStreamVolume(stream:AudioStream, volume:Float):Void {
		stream.volume = volume;
		if (stream.voice != null)
			stream.voice.volume = volume;
	}

	/** Sets a stream's pitch, absolute whatever was set before, as `SetSoundPitch` sets a sound's.

		Clamped to 0.25 to 4.

		@param stream  The stream.
		@param pitch  1 for as given. */
	static function SetAudioStreamPitch(stream:AudioStream, pitch:Float):Void {
		stream.pitch = pitch;
		if (stream.voice != null)
			stream.voice.pitch = pitch;
	}

	/** Sets where a stream is heard, in `SetSoundPan`'s range, with 1 the right.

		@param stream  The stream.
		@param pan  0 for left, 0.5 the middle, 1 for right. */
	static function SetAudioStreamPan(stream:AudioStream, pan:Float):Void {
		stream.pan = pan;
		if (stream.voice != null)
			stream.voice.pan = pan * 2 - 1;
	}

	/** Sets the frames in each of a stream's two buffers, for the streams opened after.

		0 restores raylib's default, a 30th of a second at 44100 Hz (1470 frames).

		@param size  The frames. */
	static function SetAudioStreamBufferSizeDefault(size:Int):Void {
		bufferSizeDefault = size;
	}

	/** Sets the callback a stream asks for its samples, or removes it.

		While the stream plays, the callback is called with a buffer's frames to fill until the stream holds two buffers ahead of what is heard.

		Called on the main thread as each frame ends (`EndDrawing`'s poll), and once as the stream starts to play. raylib calls it on its audio thread.

		A frame long enough to empty both buffers is heard as a gap.

		Ignored for a stream that isn't open.

		@param stream  The stream.
		@param callback  Receives a buffer to fill, in the stream's sample size and channels, and its frames; null for none. */
	static function SetAudioStreamCallback(stream:AudioStream, callback:Null<(bufferData:haxe.io.Bytes, frames:Int) -> Void>):Void {
		if (stream.queue == null)
			return;
		stream.callback = callback;
		if (streams != null)
			streams.streams.remove(stream);
		if (callback != null) {
			if (streams == null) {
				streams = new AudioStreams();
				Runtime.polled.push(streams);
			}
			streams.streams.push(stream);
		}
	}

	/** Doesn't compile on any target, as raylib calls a stream's processor on its audio thread, where Haxe can't run.

		@param stream  The stream.
		@param processor  The processor.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("AttachAudioStreamProcessor: raylib calls it on the audio thread, where Haxe can't run")
	static function AttachAudioStreamProcessor(stream:AudioStream, processor:Null<(bufferData:haxe.io.Bytes, frames:Int) -> Void>):Void {
		throw "AttachAudioStreamProcessor is unimplemented";
	}

	/** Doesn't compile on any target, as no stream processor can be attached (`AttachAudioStreamProcessor`).

		@param stream  The stream.
		@param processor  The processor.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("DetachAudioStreamProcessor: raylib calls processors on the audio thread, where Haxe can't run")
	static function DetachAudioStreamProcessor(stream:AudioStream, processor:Null<(bufferData:haxe.io.Bytes, frames:Int) -> Void>):Void {
		throw "DetachAudioStreamProcessor is unimplemented";
	}

	/** Doesn't compile on any target, as raylib calls the mix's processor on its audio thread, where Haxe can't run.

		@param processor  The processor.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("AttachAudioMixedProcessor: raylib calls it on the audio thread, where Haxe can't run")
	static function AttachAudioMixedProcessor(processor:Null<(bufferData:haxe.io.Bytes, frames:Int) -> Void>):Void {
		throw "AttachAudioMixedProcessor is unimplemented";
	}

	/** Doesn't compile on any target, as no mix processor can be attached (`AttachAudioMixedProcessor`).

		@param processor  The processor.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("DetachAudioMixedProcessor: raylib calls processors on the audio thread, where Haxe can't run")
	static function DetachAudioMixedProcessor(processor:Null<(bufferData:haxe.io.Bytes, frames:Int) -> Void>):Void {
		throw "DetachAudioMixedProcessor is unimplemented";
	}

	// Calls a playing stream's callback until it holds two buffers ahead of what is heard (AudioStreams' poll).
	static function topUp(stream:AudioStream):Void {
		var callback = stream.callback;
		if (callback == null || stream.queue == null || stream.voice == null || !stream.voice.playing || stream.voice.paused)
			return;
		var frames = stream.bufferFrames;
		if (frames <= 0)
			return;
		while (stream.queue != null && stream.callback == callback && stream.queue.queuedFrameCount < 2 * frames) {
			var buffer = haxe.io.Bytes.alloc(frames * stream.channels * bytesPerSample(stream.sampleSize));
			callback(buffer, frames);
			if (stream.queue != null)
				queueBuffer(stream, buffer, frames);
		}
	}

	// A buffer of a stream's samples, in its format, queued as floats, filled with silence to a buffer's frames.
	static function queueBuffer(stream:AudioStream, data:haxe.io.Bytes, frameCount:Int):Void {
		var frames = stream.bufferFrames, channels = stream.channels;
		var given = Std.int(Math.max(0, Math.min(frameCount, frames)));
		var size = bytesPerSample(stream.sampleSize) * channels;
		var source = padded(data, given * size);
		var floats = haxe.io.Bytes.alloc(frames * channels * 4);
		if (given > 0)
			FrameConverter.convert(floats, given, 32, channels, stream.sampleRate, source, given, stream.sampleSize, channels, stream.sampleRate);
		stream.queue.queueSamples(floats);
	}

	// The bytes a sample of a size takes, as miniaudio's formats have them: u8, s16, or f32 for any other.
	static function bytesPerSample(sampleSize:Int):Int {
		return sampleSize == 8 ? 1 : sampleSize == 16 ? 2 : 4;
	}

	// The streams' default buffer frames (SetAudioStreamBufferSizeDefault), 0 for raylib's own.
	static var bufferSizeDefault = 0;

	// The streams with callbacks, made and polled with the first (SetAudioStreamCallback), so a program giving none never links their
	// topping up; null until then and after CloseAudioDevice. A stream fed by UpdateAudioStream needs no poll: its samples are queued as
	// they are given.
	static var streams:Null<AudioStreams> = null;
	#end
}
