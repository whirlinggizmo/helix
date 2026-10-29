package helix.services.audio;

import helix.log.Log;
import helix.platform.IAudio;
import helix.platform.IAudioDecoder;
import helix.platform.IPollable;
import helix.platform.ISystem;
import helix.services.assets.Assets;

/** Provides sounds by path, played as voices in groups whose volumes and fades apply to every voice in them.

	A sound is loaded one of two ways: decoded whole (`load`), for short sounds played often, or played as it's read (`stream`), for music
	and other long sounds. Every group is under `master`. A fade runs on real time from when it's asked for, whether or not anything is
	heard yet: in a page, sound starts with the player's first key, click or tap (`IAudio.running`), and a fade asked for before then may
	have ended by then. The program calls `poll` once a frame, which steps the fades and lets go of ended voices.

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

	/** Creates the audio over the platform's output, with only `master`.

		@param output  The platform's sound output.
		@param decoder  The platform's decoder, for sounds loaded whole.
		@param assets  Where sounds are found by path.
		@param system  The platform's facts: fades read its monotonic time (`getTime`). */
	public function new(output:IAudio, decoder:IAudioDecoder, assets:Assets, system:ISystem) {
		this.output = output;
		this.decoder = decoder;
		this.assets = assets;
		this.system = system;
		master = new Group(this, null);
		groups.push(master);
	}

	/** Gets the group every other is under: its volume and `muted` apply to every voice. */
	public var master(default, null):Group;

	/** Creates a group, such as music or effects, with its own volume.

		@param parent  Optional. The group it's under; `master` by default.
		@return  The group, at volume 1. */
	public function createGroup(?parent:Group):Group {
		var group = new Group(this, parent == null ? master : parent);
		groups.push(group);
		return group;
	}

	/** Loads a sound whole: read through `Assets.load`, decoded and held as samples, so it plays at once each time.

		@param path  The file's path, as `Assets` finds it: WAV, Ogg Vorbis, MP3 or FLAC.
		@param loaded  Receives the sound.
		@param failed  Optional. Receives why it can't be had or decoded; left out, it's logged with the path.
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

	/** Opens a sound to be played as it's read, never held whole.

		It's found through `Assets.locate`: a file system's file is read where it is; a server's file is read from its kept copy, or
		played as it downloads while the copy is kept.

		@param path  The file's path, as `Assets` finds it.
		@param opened  Receives the sound, once enough of it is there to start.
		@param failed  Optional. Receives why it can't be had or opened; left out, it's logged with the path.
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

		@param sound  The sound, as `load` or `stream` gave it.
		@param group  Optional. The group it plays in; `master` by default.
		@param loop  Optional. True to play it again from the start each time it ends; false by default.
		@param volume  Optional. Its own volume, 0 to 1, before its groups'; 1 by default.
		@return  The voice, to change or stop it.
		@throws String  For a null sound, or one unloaded. */
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

	/** Lets go of a sound: its voices stop, and what holds it is freed.

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

	/** Steps the fades to now and lets go of the voices that ended; call once a frame. */
	public function poll():Void {
		var time = now();
		for (group in groups)
			group.step(time);
		voices = [for (voice in voices) if (voice.step(time)) voice];
	}

	/** Stops every voice and lets go of every sound; before the output, decoder and `Assets` it was given are disposed. */
	public function dispose():Void {
		for (voice in voices)
			voice.stop();
		voices = [];
		for (sound in sounds.copy())
			unload(sound);
		disposed = true;
	}

	/** The real seconds fades are timed by. */
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
