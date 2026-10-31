package helix.platform.adapters.audio.sdl3mixer;

import haxe.io.Bytes;
import helix.platform.GrowingSource;
import helix.platform.IAudio;
import helix.platform.StreamSource;
import helix.platform.adapters.audio.sdl3mixer.internal.AudioBridge;
import helix.platform.adapters.shared.ProgramName;
import helix.platform.adapters.shared.sdl3.Sdl3Bridge;
import helix.platform.adapters.shared.sdl3mixer.Sdl3MixerBridge;

/** A download's copy in C (`id`), kept up with its source at each poll: how much of it has been copied, and whether its end was told. */
@:structInit
@:allow(helix.platform.adapters.audio.sdl3mixer.Sdl3MixerAudioAdapter)
private class Copy {
	final source:GrowingSource;
	final id:Int;
	var copied:Int;
	var ended:Bool;
}

/** A stream's file: a path, or a download's copy; its channels; and its length in seconds once asked for and known (`duration`,
	`measured`). */
@:structInit
@:allow(helix.platform.adapters.audio.sdl3mixer.Sdl3MixerAudioAdapter)
private class StreamFile {
	final path:Null<String>;
	final copy:Null<Copy>;
	final channels:Int;
	var duration = 0.;
	var measured = false;
}

/** A download waiting to open: its copy, how much had arrived at the last try, and its callbacks, unless aborted. */
@:structInit
@:allow(helix.platform.adapters.audio.sdl3mixer.Sdl3MixerAudioAdapter)
private class Opening {
	final copy:Copy;
	var tried:Int;
	var aborted:Bool;
	final opened:Int->Void;
	final failed:String->Void;
}

/** Provides `IAudio` natively over SDL3_mixer on SDL3's default playback device.

	Voices are SDL3_mixer's tracks; a stream is decoded on the main thread at each poll, up to a second ahead, from a file or from a download
	as it arrives, in its file's channels. A queue is an SDL audio stream its track plays, SDL resampling it. A stream's position is counted
	from what was decoded and what its track hasn't taken yet, and it is moved by SDL3_mixer's own decoder seek. A download opens once 16 KiB have arrived (or the whole, when smaller), tried again each time what has arrived doubles while
	its codec can't open it yet; it is decoded only while 16 KiB ahead of the decoder's reads, or complete, and its voice sounds once a second
	is decoded. A download that fails plays to where it stopped, then ends. A `Remote` source fails: the caller downloads it, `playsUrls`
	being false. */
class Sdl3MixerAudioAdapter implements IAudio {
	static inline var MARGIN = 16 * 1024;

	var deliveries:Array<Void->Void> = [];
	var streams:Map<Int, StreamFile> = [];
	var voices:Map<Int, Int> = [];
	var openings:Array<Opening> = [];
	var nextStream = 1;
	var output:Bool;

	/** Creates the output, opening the default playback device; with none, clips are still made, nothing plays and `available` is
		false. */
	public function new() {
		Sdl3Bridge.nameApp(ProgramName.product());
		Sdl3MixerBridge.version();
		output = AudioBridge.open(1) != 0;
	}

	public var available(get, never):Bool;

	function get_available():Bool
		return output;

	public var running(get, never):Bool;

	function get_running():Bool
		return output;

	public var playsUrls(get, never):Bool;

	function get_playsUrls():Bool
		return false;

	public function createClip(samples:Bytes, channels:Int):Int {
		if (channels != 1 && channels != 2)
			throw "Audio clip channels must be 1 or 2";
		var frames = Std.int(samples.length / (4 * channels));
		var id = frames == 0 ? 0 : AudioBridge.clip(cpp.Pointer.arrayElem(samples.getData(), 0).raw, frames, channels);
		if (id == 0)
			throw "Audio clip creation failed";
		return id;
	}

	public function disposeClip(clip:Int):Void
		if (AudioBridge.disposeClip(clip) != 1)
			throw "Invalid audio clip";

	public function openStream(source:StreamSource, opened:Int->Void, failed:String->Void):Void->Void {
		var aborted = false;
		switch source {
			case Remote(_):
				deliveries.push(() -> if (!aborted) failed("Remote audio isn't streamed natively; its download is (Downloading)"));
			case Local(path):
				deliveries.push(() -> {
					if (aborted)
						return;
					var channels = AudioBridge.checkFile(cpp.ConstCharStar.fromString(path));
					if (channels == 0)
						failed("Unsupported audio stream: " + path);
					else
						opened(add({path: path, copy: null, channels: channels}));
				});
			case Downloading(download):
				var opening:Opening = {
					copy: {
						source: download,
						id: AudioBridge.download(download.total),
						copied: 0,
						ended: false
					},
					tried: 0,
					aborted: false,
					opened: opened,
					failed: failed
				};
				openings.push(opening);
				return () -> opening.aborted = true;
		}
		return () -> aborted = true;
	}

	function add(file:StreamFile):Int {
		var id = nextStream++;
		streams[id] = file;
		return id;
	}

	public function disposeStream(stream:Int):Void {
		var file = streams[stream];
		if (file == null)
			throw "Invalid audio stream";
		for (voice in [for (v => s in voices) if (s == stream) v])
			stop(voice);
		if (file.copy != null)
			AudioBridge.downloadRelease(file.copy.id);
		streams.remove(stream);
	}

	public function getStreamDuration(stream:Int):Float {
		var file = streams[stream];
		if (file == null)
			throw "Invalid audio stream";
		if (!file.measured) {
			// A file's length is asked for once; a download's once it has all arrived and been copied.
			if (file.copy == null)
				file.duration = AudioBridge.fileDuration(cpp.ConstCharStar.fromString(file.path));
			else if (file.copy.copied == file.copy.source.total && file.copy.ended)
				file.duration = AudioBridge.downloadDuration(file.copy.id);
			else
				return 0;
			file.measured = true;
		}
		return file.duration;
	}

	public function getStreamChannels(stream:Int):Int {
		var file = streams[stream];
		if (file == null)
			throw "Invalid audio stream";
		return file.channels;
	}

	public function createQueue(channels:Int, sampleRate:Int):Int {
		if (channels != 1 && channels != 2)
			throw "Audio queue channels must be 1 or 2";
		if (sampleRate < 8000 || sampleRate > 96000)
			throw "Audio queue sample rate must be 8000 to 96000";
		var id = AudioBridge.queue(channels, sampleRate);
		if (id == 0)
			throw "Audio queue creation failed";
		return id;
	}

	public function queueSamples(queue:Int, samples:Bytes):Void
		if (AudioBridge.queueSamples(queue, samples.length == 0 ? null : cpp.Pointer.arrayElem(samples.getData(), 0).raw, samples.length) == 0)
			throw "Invalid audio queue";

	public function getQueuedFrames(queue:Int):Int {
		var frames = AudioBridge.queuedFrames(queue);
		if (frames < 0)
			throw "Invalid audio queue";
		return frames;
	}

	public function disposeQueue(queue:Int):Void
		if (AudioBridge.disposeQueue(queue) != 1)
			throw "Invalid audio queue";

	public function playQueue(queue:Int, volume:Float):Int {
		var voice = AudioBridge.playQueue(queue, volume);
		if (voice < 0)
			throw "Invalid audio queue";
		return voice;
	}

	public function playClip(clip:Int, loop:Bool, volume:Float):Int {
		var voice = AudioBridge.playClip(clip, loop ? 1 : 0, volume);
		if (voice < 0)
			throw "Invalid audio clip";
		return voice;
	}

	public function playStream(stream:Int, loop:Bool, volume:Float):Int {
		var file = streams[stream];
		if (file == null)
			throw "Invalid audio stream";
		var voice = file.copy != null ? AudioBridge.playDownload(file.copy.id, loop ? 1 : 0,
			volume) : AudioBridge.playFile(cpp.ConstCharStar.fromString(file.path), loop ? 1 : 0, volume);
		if (voice != 0)
			voices[voice] = stream;
		return voice;
	}

	public function stop(voice:Int):Void {
		AudioBridge.stop(voice);
		voices.remove(voice);
	}

	public function pause(voice:Int, paused:Bool):Void
		AudioBridge.pause(voice, paused ? 1 : 0);

	public function setVolume(voice:Int, volume:Float):Bool
		return Math.isFinite(volume) && AudioBridge.setVolume(voice, volume) != 0;

	public function setPitch(voice:Int, pitch:Float):Bool
		return Math.isFinite(pitch) && AudioBridge.setPitch(voice, pitch) != 0;

	public function setPan(voice:Int, pan:Float):Bool
		return Math.isFinite(pan) && AudioBridge.setPan(voice, pan) != 0;

	public function isPlaying(voice:Int):Bool
		return AudioBridge.isPlaying(voice) != 0;

	public function getPosition(voice:Int):Float
		return AudioBridge.position(voice);

	public function setPosition(voice:Int, seconds:Float):Bool
		return Math.isFinite(seconds) && seconds >= 0 && AudioBridge.setPosition(voice, seconds) != 0;

	// Copies what has arrived of a download since the last poll into its C copy, and tells it when nothing more will come.
	static function update(copy:Copy):Void {
		var source = copy.source;
		if (source.received > copy.copied) {
			AudioBridge.downloadAdd(copy.id, cpp.Pointer.arrayElem(source.bytes.getData(), copy.copied).raw, source.received - copy.copied);
			copy.copied = source.received;
		}
		if (!copy.ended && (source.done || source.failure != null)) {
			copy.ended = true;
			AudioBridge.downloadEnd(copy.id);
		}
	}

	// Tries the downloads waiting to open: once 16 KiB have arrived (or the whole), and again each time that doubles while the codec can't
	// open them yet; a failed download, or a whole one it can't, fails.
	function open():Void
		for (opening in openings.copy()) {
			var copy = opening.copy, source = copy.source;
			if (opening.aborted) {
				openings.remove(opening);
				AudioBridge.downloadRelease(copy.id);
				continue;
			}
			if (source.failure != null) {
				openings.remove(opening);
				AudioBridge.downloadRelease(copy.id);
				opening.failed("Download failed: " + source.failure);
				continue;
			}
			update(copy);
			if (!source.done && (source.received < MARGIN || source.received < opening.tried * 2))
				continue;
			opening.tried = source.received;
			var channels = AudioBridge.checkDownload(copy.id);
			if (channels == 0 && !source.done)
				continue;
			openings.remove(opening);
			if (channels == 0) {
				AudioBridge.downloadRelease(copy.id);
				opening.failed("Unsupported audio stream download");
			} else
				opening.opened(add({path: null, copy: copy, channels: channels}));
		}

	public function poll():Void {
		var due = deliveries;
		deliveries = [];
		for (delivery in due)
			delivery();
		open();
		for (file in streams)
			if (file.copy != null && !file.copy.ended)
				update(file.copy);
		AudioBridge.feed();
		for (voice in [for (v in voices.keys()) if (AudioBridge.isPlaying(v) == 0) v])
			voices.remove(voice);
	}

	public function dispose():Void {
		AudioBridge.close();
		streams.clear();
		voices.clear();
		openings = [];
		deliveries = [];
		output = false;
	}
}
