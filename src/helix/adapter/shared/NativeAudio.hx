package helix.adapter.shared;

import haxe.io.Bytes;
import helix.asset.GrowingSource;
import helix.asset.IAssets.AudioLocation;
import helix.audio.IAudio;
import sys.thread.Thread;

/** A stream voice's producer: its file's handle, its stream, whether it loops, and its download when it's still arriving (or null). */
private typedef Producer = {var handle:Int; var stream:Int; var loop:Bool; var source:Null<GrowingSource>;}

/** An opened stream's file: a stored file's path, or a download (each voice opens it again). */
private typedef StreamFile = {final path:Null<String>; final source:Null<GrowingSource>;}

/** A download waiting to open: its source, how much had arrived at the last try, and its opener's answer, unless aborted. */
private typedef Opening = {final source:GrowingSource; var tried:Int; var aborted:Bool; final done:StreamOpenResult->Void;}

/** IAudio natively, for either output (sokol_audio's or SDL3's): mono voices at 44100 Hz mixed to stereo (pan, pitch, volume ramps), 16 voices, 32 clips, mixed in C (mixer.c). Streams play stored files
	and downloads as they arrive (a remote URL fails: AudioResources downloads it, playsUrls being false), read through files (a codec adapter's), each voice kept 88200 frames (2 s) ahead by poll for up to
	2 ms a frame, so a frame stalled under that plays on: how a push-based output plays a file as it's read. A download opens once 64 KiB have arrived (or the whole, when it's smaller), tried again each
	time what has arrived doubles while its codec can't open it yet; a voice decodes it only while it has arrived 64 KiB past the codec's position (or whole), as the codec takes a short read for the end,
	and otherwise waits, its 2 s covering a slow connection's gaps; a download that fails plays to where it stopped, then ends as at the end of its file. */
@:noCompletion
abstract class NativeAudio implements IAudio {
	static inline var CHUNK = 2048;
	static inline var AHEAD = 88200;
	static inline var MARGIN = 64 * 1024;

	var files:IPcmFiles;
	var mailbox = new Mailbox();
	var streams:Map<Int, StreamFile> = [];
	var openings:Array<Opening> = [];
	var producers:Map<Int, Producer> = [];
	var nextStream = 1;
	var chunk = Bytes.alloc(CHUNK * 4);

	/** Streams read through files; the adapter opens its output (available says whether it did). */
	function new(files:IPcmFiles) {
		this.files = files;
	}

	/** Stops the output; no mixing happens after it returns, and the mixer's samples are freed. */
	abstract function closeOutput():Void;

	public var available(get, never):Bool;

	function get_available():Bool
		return MixerBridge.audioAvailable() != 0;

	public var playsUrls(get, never):Bool;

	function get_playsUrls():Bool
		return false;

	public var running(get, never):Bool;

	function get_running():Bool
		return this.available;

	public function createClip(samples:Bytes):Int {
		var id = MixerBridge.audioClip(cpp.Pointer.arrayElem(samples.getData(), 0).raw, samples.length);
		if (id == 0)
			throw "Audio clip creation failed";
		return id;
	}

	public function destroyClip(clip:Int):Void
		if (MixerBridge.audioDestroyClip(clip) != 1)
			throw "Invalid audio clip";

	public function openStream(source:AudioLocation, done:StreamOpenResult->Void):Void->Void {
		var aborted = false;
		switch source {
			case Remote(_):
				mailbox.post(() -> if (!aborted) done(Failed("Remote audio isn't streamed natively; its download is (Downloading)")));
			case Downloading(download):
				var opening:Opening = {
					source: download,
					tried: 0,
					aborted: false,
					done: done
				};
				openings.push(opening);
				return () -> opening.aborted = true;
			case Stored(lease):
				var path = lease.location;
				// Opened once on a worker to check it reads; each voice opens it again.
				Thread.create(() -> {
					var handle = files.open(path);
					if (handle != 0)
						files.close(handle);
					mailbox.post(() -> {
						if (aborted)
							return;
						if (handle == 0)
							done(Failed("Unsupported audio stream: " + path));
						else {
							var id = nextStream++;
							streams[id] = ({path: path, source: null} : StreamFile);
							done(Opened(id));
						}
					});
				});
		}
		return () -> aborted = true;
	}

	public function destroyStream(stream:Int):Void {
		if (!streams.exists(stream))
			throw "Invalid audio stream";
		for (voice in [for (v => p in producers) if (p.stream == stream) v])
			stop(voice);
		streams.remove(stream);
	}

	public function playClip(clip:Int, loop:Bool, volume:Float):Int {
		var id = MixerBridge.audioPlay(clip, loop ? 1 : 0, volume);
		if (id < 0)
			throw "Invalid audio clip";
		return id;
	}

	public function playStream(stream:Int, loop:Bool, volume:Float):Int {
		var file = streams[stream];
		if (file == null)
			throw "Invalid audio stream";
		var handle = file.source != null ? files.openArriving(file.source) : files.open(file.path);
		if (handle == 0)
			return 0;
		var voice = MixerBridge.audioStream(volume);
		if (voice == 0) {
			files.close(handle);
			return 0;
		}
		producers[voice] = {
			handle: handle,
			stream: stream,
			loop: loop,
			source: file.source != null && !file.source.done ? file.source : null};
		return fill(voice) ? voice : 0;
	}

	// Feeds voice up to AHEAD frames queued, for up to 2 ms; false when its stream failed (the voice is stopped).
	function fill(voice:Int):Bool {
		var p = producers[voice], start = haxe.Timer.stamp();
		while (haxe.Timer.stamp() - start < .002) {
			var queued = MixerBridge.audioStreamQueued(voice);
			if (queued < 0) {
				close(voice);
				return true;
			}
			var frames = Std.int(Math.min(CHUNK, AHEAD - queued));
			if (frames == 0)
				return true;
			// A download is read only while it's a margin ahead of the codec, or once nothing more will come: whole, or failed, when what came
			// plays to where it stops, the codec taking that for the end.
			if (p.source != null && !p.source.done && p.source.failure == null && p.source.received < files.position(p.handle) + MARGIN)
				return true;
			var count = files.read(p.handle, chunk, frames);
			if (count < 0 || count == 0 && p.loop && !files.rewind(p.handle)) {
				var file = streams[p.stream];
				Sys.println("Audio stream failed: " + (file.path != null ? file.path : "a download"));
				stop(voice);
				return false;
			}
			if (count == 0) {
				if (p.loop)
					continue;
				MixerBridge.audioStreamPush(voice, null, 0, 1);
				close(voice);
				return true;
			}
			if (MixerBridge.audioStreamPush(voice, cpp.Pointer.arrayElem(chunk.getData(), 0).raw, count * 4, 0) != count) {
				stop(voice);
				return false;
			}
		}
		return true;
	}

	function close(voice:Int):Void {
		var p = producers[voice];
		if (p != null) {
			files.close(p.handle);
			producers.remove(voice);
		}
	}

	public function stop(voice:Int):Void {
		close(voice);
		MixerBridge.audioStop(voice);
	}

	public function pause(voice:Int, paused:Bool):Void
		MixerBridge.audioPause(voice, paused ? 1 : 0);

	public function setVolume(voice:Int, volume:Float):Bool {
		if (!isPlaying(voice) || !Math.isFinite(volume) || volume < 0 || volume > 1)
			return false;
		MixerBridge.audioVolume(voice, volume);
		return true;
	}

	public function setPitch(voice:Int, pitch:Float):Bool {
		if (!isPlaying(voice))
			return false;
		MixerBridge.audioPitch(voice, pitch);
		return true;
	}

	public function setPan(voice:Int, pan:Float):Bool {
		if (!isPlaying(voice))
			return false;
		MixerBridge.audioPan(voice, pan);
		return true;
	}

	public function isPlaying(voice:Int):Bool
		return MixerBridge.audioIsPlaying(voice) != 0;

	// Tries the downloads waiting to open: once 64 KiB have arrived (or the whole), and again each time that doubles while the codec can't
	// open them yet; a failed download, or a whole one it can't, fails.
	function open():Void
		for (opening in openings.copy()) {
			var source = opening.source;
			if (opening.aborted) {
				openings.remove(opening);
				continue;
			}
			if (source.failure != null) {
				openings.remove(opening);
				opening.done(Failed("Download failed: " + source.failure));
				continue;
			}
			if (!source.done && (source.received < MARGIN || source.received < opening.tried * 2))
				continue;
			opening.tried = source.received;
			var handle = files.openArriving(source);
			if (handle == 0 && !source.done)
				continue;
			openings.remove(opening);
			if (handle == 0) {
				opening.done(Failed("Unsupported audio stream download"));
				continue;
			}
			files.close(handle);
			var id = nextStream++;
			streams[id] = ({path: null, source: source} : StreamFile);
			opening.done(Opened(id));
		}

	public function poll():Void {
		mailbox.deliver();
		open();
		for (voice in [for (v in producers.keys()) v])
			fill(voice);
	}

	public function shutdown():Void {
		for (voice in [for (v in producers.keys()) v])
			stop(voice);
		streams.clear();
		openings = [];
		closeOutput();
	}
}
