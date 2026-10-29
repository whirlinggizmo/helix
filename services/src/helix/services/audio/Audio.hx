package helix.services.audio;

import helix.log.Log;
import helix.platform.IAudio;
import helix.platform.IAudioDecoder;
import helix.platform.IPollable;
import helix.platform.ISystem;
import helix.services.assets.Assets;

/** Provides sounds by path, played as voices in groups whose volumes and fades apply to every voice in them.

	A sound is loaded in one of two ways. `load` decodes it whole, for short sounds played often. `stream` plays it as it is read, for
	music and other long sounds. Every group is under `master`.

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
		var abortLoad = assets.load(path, bytes -> decoder.decode(bytes, samples -> {
			if (aborted || disposed)
				return;
			var clip = try output.createClip(samples) catch (e:Dynamic) {
				fail(failed, path, Std.string(e));
				return;
			}
			var sound = new Sound(path, false, clip, null);
			sounds.push(sound);
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
				var sound = new Sound(path, true, stream, release);
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
		var heard = volume * group.heard();
		heard = heard > 0 ? (heard < 1 ? heard : 1) : 0;
		var id = sound.streamed ? output.playStream(sound.id, loop, heard) : output.playClip(sound.id, loop, heard);
		var voice = new Voice(this, output, id, sound, group, volume);
		voice.sent = heard;
		if (id != 0)
			voices.push(voice);
		return voice;
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
		if (sound.streamed)
			output.disposeStream(sound.id);
		else
			output.disposeClip(sound.id);
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

	/** Stops every voice and unloads every sound.

		Call it before disposing the output, decoder and `Assets` it was given. */
	public function dispose():Void {
		for (voice in voices)
			voice.stop();
		voices = [];
		for (sound in sounds.copy())
			unload(sound);
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
