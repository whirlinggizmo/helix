package helix.adapters.shared;

import haxe.io.Bytes;
import helix.assets.IAssets.AudioLocation;
import helix.audio.IAudio;
import sys.thread.Thread;

/** A stream voice's producer: its file's handle, its stream, and whether it loops. */
private typedef Producer = {var handle:Int; var stream:Int; var loop:Bool;}

/** IAudio natively, for either output (sokol_audio's or SDL3's): mono at 44100 Hz, 16 voices, 32 clips, mixed in C (mixer.c). Streams play stored files (a remote URL fails), read
	through files (a codec adapter's), each voice kept 88200 frames (2 s) ahead by poll for up to 2 ms a frame, so a frame stalled under that plays on: how a push-based output plays a file as
	it's read. */
abstract class NativeAudio implements IAudio {
	static inline var CHUNK = 2048;
	static inline var AHEAD = 88200;

	var files:IPcmFiles;
	var mailbox = new Mailbox();
	var streams:Map<Int, String> = [];
	var producers:Map<Int, Producer> = [];
	var nextStream = 1;
	var chunk = Bytes.alloc(CHUNK * 4);

	/** Streams read through files; the adapter opens its output (isAvailable says whether it did). */
	function new(files:IPcmFiles) {
		this.files = files;
	}

	/** Stops the output; no mixing happens after it returns, and the mixer's samples are freed. */
	abstract function closeOutput():Void;

	public function isAvailable():Bool
		return MixerBridge.audioAvailable() != 0;

	public function isRunning():Bool
		return isAvailable();

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
				mailbox.post(() -> if (!aborted) done(Failed("Remote audio isn't streamed natively; ensure the asset first")));
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
							streams[id] = path;
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
		var path = streams[stream];
		if (path == null)
			throw "Invalid audio stream";
		var handle = files.open(path);
		if (handle == 0)
			return 0;
		var voice = MixerBridge.audioStream(volume);
		if (voice == 0) {
			files.close(handle);
			return 0;
		}
		producers[voice] = {handle: handle, stream: stream, loop: loop};
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
			var count = files.read(p.handle, chunk, frames);
			if (count < 0 || count == 0 && p.loop && !files.rewind(p.handle)) {
				Sys.println("Audio stream failed: " + streams[p.stream]);
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

	public function isPlaying(voice:Int):Bool
		return MixerBridge.audioIsPlaying(voice) != 0;

	public function poll():Void {
		mailbox.deliver();
		for (voice in [for (v in producers.keys()) v])
			fill(voice);
	}

	public function shutdown():Void {
		for (voice in [for (v in producers.keys()) v])
			stop(voice);
		streams.clear();
		closeOutput();
	}
}
