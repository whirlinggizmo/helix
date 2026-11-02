package helix.services.audio;

import haxe.io.Bytes;
import helix.log.Log;
import helix.platform.IAudio;
import helix.platform.IAudioDecoder;
import helix.platform.IPollable;
import helix.platform.ISystem;
import helix.services.assets.Assets;

/** Provides sounds by path, played as voices in groups whose volumes and fades apply to every voice in them.

	A sound is loaded in one of two ways. `load` decodes it whole, for short sounds played often. `stream` plays it as it is read, for
	music and other long sounds. `createSound` makes one from samples, and `createSampleQueue` a queue that plays samples as they are added.
	Every group is under `master`.

	The program calls `poll` once a frame, which steps the fades and releases voices that ended. A fade runs on real time from when it
	starts, whether or not anything is heard yet. In a page, sound starts with the player's first key, click or tap (`IAudio.running`),
	so a fade started before then may already have ended.

	```haxe
	var effects = audio.createGroup();
	var music = audio.createGroup();
	audio.load("jump.wav", sound -> jump = sound);
	audio.stream("music.ogg", sound -> audio.play(sound, music, true, 0).fadeTo(0.5, 2));
	audio.play(jump, effects);
	audio.master.muted = true;
	``` */
class Audio implements IPollable {
	final output:IAudio;
	final decoder:IAudioDecoder;
	final assets:Assets;
	final system:ISystem;
	final groups:Array<Group> = [];
	final sounds:Array<Sound> = [];
	final queues:Array<SampleQueue> = [];
	var voices:Array<Voice> = [];
	var disposed = false;

	/** Creates the audio over the platform's output, with `master` as its only group.

		@param output  The platform's sound output.
		@param decoder  The platform's decoder, for sounds loaded whole.
		@param assets  The assets that sounds are found in by path.
		@param system  The platform's system, whose monotonic time (`getTime`) times the fades. */
	public function new(output:IAudio, decoder:IAudioDecoder, assets:Assets, system:ISystem) {
		this.output = output;
		this.decoder = decoder;
		this.assets = assets;
		this.system = system;
		master = new Group(this, null);
		groups.push(master);
	}

	/** Gets the group that every other group is under. Its volume and `muted` apply to every voice. */
	public var master(default, null):Group;

	/** Creates a group, such as music or effects, with its own volume.

		@param parent  Optional. The group it is under. Defaults to `master`.
		@return  The group, at volume 1. */
	public function createGroup(?parent:Group):Group {
		var group = new Group(this, parent == null ? master : parent);
		groups.push(group);
		return group;
	}

	/** Loads a sound whole, so it plays at once each time.

		The file is read through `Assets.load`, decoded, and held as samples.

		@param path  The file's path in `Assets`. The file is WAV, Ogg Vorbis, MP3 or FLAC.
		@param loaded  Receives the sound.
		@param failed  Optional. Receives why the sound can't be loaded or decoded. When omitted, the failure is logged with the path.
		@return  The abort: nothing is called after it. */
	public function load(path:String, loaded:Sound->Void, ?failed:String->Void):Void->Void {
		var aborted = false;
		// Decoded at 44100 Hz, the rate a clip plays at.
		var abortLoad = assets.load(path, bytes -> decoder.decode(bytes, 44100, (samples, channelCount, _) -> {
			if (aborted || disposed)
				return;
			var sound = try clipOf(path, samples, channelCount) catch (e:Dynamic) {
				fail(failed, path, Std.string(e));
				return;
			}
			loaded(sound);
		},
			message -> if (!aborted) fail(failed, path, message)), message -> if (!aborted) report(failed, message));
		return () -> {
			aborted = true;
			abortLoad();
		};
	}

	/** Opens a sound to be played as it is read, never held whole.

		The file is found through `Assets.locate`. A file system's file is read where it is. A server's file is read from its kept copy,
		or played as it downloads while the copy is kept.

		@param path  The file's path in `Assets`.
		@param opened  Receives the sound, once enough of it has arrived to start.
		@param failed  Optional. Receives why the sound can't be found or opened. When omitted, the failure is logged with the path.
		@return  The abort: nothing is called after it. */
	public function stream(path:String, opened:Sound->Void, ?failed:String->Void):Void->Void {
		var aborted = false, abortOpen:Null<Void->Void> = null;
		var abortLocate = assets.locate(path, (source, release) -> {
			if (aborted || disposed) {
				release();
				return;
			}
			abortOpen = output.openStream(source, stream -> {
				var sound = new Sound(path, stream, output.getStreamChannelCount(stream), 0, release,
					(loop, volume) -> output.playStream(stream, loop, volume), () -> output.disposeStream(stream), () -> output.getStreamDuration(stream));
				// Natively a download from a server starts with its last bytes (Assets.tailOf), its length read once its start arrives too.
				#if !js
				switch source {
					case Downloading(growing):
						var tail = assets.tailOf(growing);
						if (tail != null) sound.measureFrom(growing, tail);
					case _:
				}
				#end
				sounds.push(sound);
				opened(sound);
			}, message -> {
				release();
				fail(failed, path, message);
			});
		}, message -> if (!aborted) report(failed, message));
		return () -> {
			aborted = true;
			abortLocate();
			if (abortOpen != null)
				abortOpen();
		};
	}

	/** Makes a sound from samples, held whole as a loaded sound is.

		The samples are copied. A partial frame at the end is ignored.

		@param samples  32-bit float PCM at 44100 Hz, -1 to 1, interleaved when stereo: the platform's clip format (`IAudio.createClip`).
		@param channelCount  The channels, 1 (mono) or 2 (stereo).
		@return  The sound, its path "".
		@throws String  When channelCount isn't 1 or 2, or the samples hold no whole frame. */
	public function createSound(samples:Bytes, channelCount:Int):Sound {
		return clipOf("", samples, channelCount);
	}

	/** Creates a queue, which plays samples as they are added to it, at its own rate.

		@param channelCount  The channels, 1 (mono) or 2 (stereo).
		@param sampleRate  The samples' rate in frames a second, 8000 to 96000; the platform resamples them.
		@return  The queue, holding nothing.
		@throws String  When channelCount or sampleRate is out of range. */
	public function createSampleQueue(channelCount:Int, sampleRate:Int):SampleQueue {
		var queue = new SampleQueue(this, output, output.createQueue(channelCount, sampleRate));
		queues.push(queue);
		return queue;
	}

	/** Starts a sound playing.

		@param sound  The sound, from `load` or `stream`.
		@param group  Optional. The group it plays in. Defaults to `master`.
		@param loop  Optional. True to play it again from the start each time it ends. Defaults to false.
		@param volume  Optional. The voice's own volume, 0 to 1, before its groups' volumes apply. Defaults to 1.
		@return  The voice, which changes or stops the sound.
		@throws String  When the sound is null or unloaded. */
	public function play(sound:Sound, ?group:Group, loop = false, volume = 1.):Voice {
		if (sound == null || sound.unloaded)
			throw sound == null ? 'play needs a sound' : '${sound.path} is unloaded';
		if (group == null)
			group = master;
		var heard = heardIn(group, volume);
		var id = sound.playing(loop, heard);
		return voiceOf(id, sound, group, volume, heard);
	}

	// A queue's voice, in its group (SampleQueue.play).

	@:allow(helix.services.audio)
	function start(queue:SampleQueue, group:Null<Group>, volume:Float):Voice {
		if (group == null)
			group = master;
		var heard = heardIn(group, volume);
		return voiceOf(output.playQueue(queue.id, heard), null, group, volume, heard);
	}

	// A queue disposed (SampleQueue.dispose).

	@:allow(helix.services.audio)
	function forget(queue:SampleQueue):Void {
		queues.remove(queue);
	}

	function voiceOf(id:Int, sound:Null<Sound>, group:Group, volume:Float, heard:Float):Voice {
		var voice = new Voice(this, output, id, sound, group, volume);
		voice.sent = heard;
		if (id != 0)
			voices.push(voice);
		return voice;
	}

	static function heardIn(group:Group, volume:Float):Float {
		var heard = volume * group.heard();
		return heard > 0 ? (heard < 1 ? heard : 1) : 0;
	}

	// A clip from samples, its length counted from them.
	function clipOf(path:String, samples:Bytes, channelCount:Int):Sound {
		var clip = output.createClip(samples, channelCount);
		var frames = Std.int(samples.length / (4 * channelCount));
		var sound = new Sound(path, clip, channelCount, frames / 44100, null, (loop, volume) -> output.playClip(clip, loop, volume),
			() -> output.disposeClip(clip), null);
		sounds.push(sound);
		return sound;
	}

	/** Unloads a sound. Its voices stop, and the memory or file that holds it is released.

		Does nothing for a sound already unloaded.

		@param sound  The sound. */
	public function unload(sound:Sound):Void {
		if (sound.unloaded)
			return;
		sound.unloaded = true;
		for (voice in voices)
			if (voice.sound == sound)
				voice.stop();
		sound.disposing();
		if (sound.release != null)
			sound.release();
		sounds.remove(sound);
	}

	/** Steps the fades to the current time and releases the voices that ended.

		Call it once a frame. */
	public function poll():Void {
		var time = now();
		for (group in groups)
			group.step(time);
		voices = [for (voice in voices) if (voice.step(time)) voice];
	}

	/** Stops every voice, unloads every sound and disposes every queue.

		Call it before disposing the output, decoder and `Assets` it was given. */
	public function dispose():Void {
		for (voice in voices)
			voice.stop();
		voices = [];
		for (sound in sounds.copy())
			unload(sound);
		for (queue in queues.copy())
			queue.dispose();
		disposed = true;
	}

	/** Returns the real seconds that fades are timed by. */
	@:allow(helix.services.audio)
	function now():Float
		return system.getTime();

	static function fail(failed:Null<String->Void>, path:String, message:String):Void
		report(failed, '$path: $message');

	// Assets' failures already name the path.
	static function report(failed:Null<String->Void>, message:String):Void {
		if (failed != null)
			failed(message);
		else
			Log.warn(message, "audio");
	}
}
