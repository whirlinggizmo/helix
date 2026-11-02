package helix.platform.adapters.audio.webaudio;

import haxe.io.Bytes;
import helix.formats.audio.AudioHeader;
import helix.platform.IAudio;
import helix.platform.StreamSource;

/** What a voice plays: a clip, a stream or a queue, each its own class, made only by the call that makes one (`createClip`,
	`openStream`, `createQueue`), so a program that never streams or queues links neither (docs/CONVENTIONS.md, "A program links only
	what it names"). */
@:allow(helix.platform.adapters.audio.webaudio)
private class Resource {
	// Starts voice id of this through gain at position (seconds), as playbacks[id].
	function start(a:WebAudioAdapter, id:Int, gain:Dynamic, panner:Dynamic, loop:Bool, position:Float):Void {}

	// Whether a voice of this can be placed (setPosition).
	function seekable():Bool
		return true;

	// A voice of this stopped while it waited for audio to run.
	function stopWaiting(id:Int):Void {}

	// Each poll.
	function poll(a:WebAudioAdapter):Void {}

	// Lets go of what this holds once it is disposed.
	function release():Void {}
}

/** A voice: its resource, its gain and panner, its pitch and whether it is paused. */
@:allow(helix.platform.adapters.audio.webaudio)
private class Voice {
	final resource:Int;
	final gain:Dynamic;
	final panner:Dynamic;
	var pitch = 1.;
	var paused = false;

	function new(resource:Int, gain:Dynamic, panner:Dynamic) {
		this.resource = resource;
		this.gain = gain;
		this.panner = panner;
	}

	// Stops voice id, out of playbacks and the graph.
	function stop(a:WebAudioAdapter, id:Int):Void {}

	// Pauses or resumes voice id; paused differs from the voice's.
	function pause(a:WebAudioAdapter, id:Int, paused:Bool):Void {}

	// Plays on at pitch.
	function setPitch(a:WebAudioAdapter, pitch:Float):Void {}

	// Where the voice is, in seconds.
	function getPosition(a:WebAudioAdapter):Float
		return 0;

	// Moves voice id to seconds (finite, not negative); false when it can't be.
	function setPosition(a:WebAudioAdapter, id:Int, seconds:Float):Bool
		return false;
}

/** A clip: its samples, interleaved floats, and channels; its AudioBuffer once a voice of it has started. */
@:allow(helix.platform.adapters.audio.webaudio)
private class Clip extends Resource {
	final samples:Bytes;
	final channels:Int;
	var buffer:Dynamic = null;

	function new(samples:Bytes, channels:Int) {
		this.samples = samples;
		this.channels = channels;
	}

	override function start(a:WebAudioAdapter, id:Int, gain:Dynamic, panner:Dynamic, loop:Bool, position:Float):Void {
		if (buffer == null) {
			var data = new js.lib.Float32Array(samples.getData(), 0, Std.int(samples.length / 4));
			var frames = Std.int(data.length / channels);
			buffer = a.context.createBuffer(channels, frames, 44100);
			for (c in 0...channels) {
				var channel = new js.lib.Float32Array(frames);
				for (i in 0...frames)
					channel[i] = data[i * channels + c];
				buffer.copyToChannel(channel, c);
			}
		}
		var v = new ClipVoice(id, gain, panner, buffer, loop, Math.min(position, buffer.duration));
		a.playbacks[id] = v;
		v.begin(a, id);
	}

	override function release():Void
		buffer = null;
}

/** A clip's voice: its buffer and loop, its source while playing, its offset into the buffer (seconds) and the context time it last
	started or moved at. */
@:allow(helix.platform.adapters.audio.webaudio)
private class ClipVoice extends Voice {
	final buffer:Dynamic;
	final loop:Bool;
	var source:Dynamic = null;
	var offset:Float;
	var started = 0.;

	function new(resource:Int, gain:Dynamic, panner:Dynamic, buffer:Dynamic, loop:Bool, offset:Float) {
		super(resource, gain, panner);
		this.buffer = buffer;
		this.loop = loop;
		this.offset = offset;
	}

	// Starts a source at the offset, through the gain.
	function begin(a:WebAudioAdapter, id:Int):Void {
		var s:Dynamic = a.context.createBufferSource();
		s.buffer = buffer;
		s.loop = loop;
		s.playbackRate.value = pitch;
		s.connect(gain);
		source = s;
		started = a.context.currentTime;
		paused = false;
		s.onended = _ -> {
			if (a.playbacks[id] == this && !paused) {
				a.playbacks.remove(id);
				s.disconnect();
				a.disconnect(this);
			}
		};
		s.start(0, offset);
	}

	// Moves the offset on by what played since it started or last moved, at its pitch.
	function played(a:WebAudioAdapter):Void {
		var now:Float = a.context.currentTime;
		offset += (now - started) * pitch;
		if (loop)
			offset %= buffer.duration;
		started = now;
	}

	// Stops the source, still in playbacks.
	function halt():Void {
		source.onended = null;
		source.stop();
		source.disconnect();
	}

	override function stop(a:WebAudioAdapter, id:Int):Void {
		a.playbacks.remove(id);
		source.onended = null;
		if (!paused)
			source.stop();
		source.disconnect();
		a.disconnect(this);
	}

	override function pause(a:WebAudioAdapter, id:Int, paused:Bool):Void {
		if (paused) {
			played(a);
			this.paused = true;
			halt();
		} else {
			if (offset >= buffer.duration) {
				a.stop(id);
				return;
			}
			begin(a, id);
		}
	}

	override function setPitch(a:WebAudioAdapter, pitch:Float):Void {
		if (!paused) {
			played(a);
			source.playbackRate.value = pitch;
		}
		this.pitch = pitch;
	}

	override function getPosition(a:WebAudioAdapter):Float {
		var at:Float = paused ? offset : offset + (a.context.currentTime - started) * pitch,
			duration:Float = buffer.duration;
		return loop ? at % duration : Math.min(at, duration);
	}

	override function setPosition(a:WebAudioAdapter, id:Int, seconds:Float):Bool {
		var duration:Float = buffer.duration;
		if (seconds >= duration) {
			if (!loop) {
				a.stop(id);
				return true;
			}
			seconds = 0;
		}
		if (paused) {
			offset = seconds;
			return true;
		}
		halt();
		offset = seconds;
		begin(a, id);
		return true;
	}
}

/** A stream: its URL, its media element until a voice takes it, its duration (seconds, 0 while unknown) and its channels. */
@:allow(helix.platform.adapters.audio.webaudio)
private class Stream extends Resource {
	final url:String;
	var element:Null<js.html.AudioElement>;
	var duration:Float;
	final channels:Int;

	function new(url:String, element:js.html.AudioElement, channels:Int) {
		this.url = url;
		this.element = element;
		this.duration = durationOf(element);
		this.channels = channels;
	}

	// A media element's duration in seconds, 0 while unknown (NaN) or for a live stream (Infinity).
	static function durationOf(element:js.html.AudioElement):Float {
		var duration = element.duration;
		return Math.isFinite(duration) && duration > 0 ? duration : 0;
	}

	// The duration as known now.
	function getDuration():Float
		return element != null ? durationOf(element) : duration;

	override function start(a:WebAudioAdapter, id:Int, gain:Dynamic, panner:Dynamic, loop:Bool, position:Float):Void {
		var e = element;
		if (e == null) {
			e = js.Browser.document.createAudioElement();
			e.crossOrigin = "anonymous";
			e.src = url;
		}
		element = null;
		e.ondurationchange = _ -> duration = durationOf(e);
		e.loop = loop;
		e.playbackRate = 1;
		if (position > 0)
			e.currentTime = position;
		// The rate changes the pitch too, as a clip's does.
		Reflect.setField(e, "preservesPitch", false);
		var node:Dynamic = a.context.createMediaElementSource(e);
		node.connect(gain);
		var v = new StreamVoice(id, gain, panner, e, node);
		a.playbacks[id] = v;
		e.onended = _ -> v.finish(a, id);
		e.onerror = _ -> v.finish(a, id);
		e.play().catchError(error -> {
			v.finish(a, id);
			return null;
		});
	}

	override function release():Void {
		if (element != null) {
			element.removeAttribute("src");
			element.load();
		}
	}
}

/** A stream's voice: its media element and the element's node in the graph. */
@:allow(helix.platform.adapters.audio.webaudio)
private class StreamVoice extends Voice {
	final element:js.html.AudioElement;
	final node:Dynamic;

	function new(resource:Int, gain:Dynamic, panner:Dynamic, element:js.html.AudioElement, node:Dynamic) {
		super(resource, gain, panner);
		this.element = element;
		this.node = node;
	}

	// Ends voice id, its element let go, if it is still the one playing.
	function finish(a:WebAudioAdapter, id:Int):Void {
		if (a.playbacks[id] != this)
			return;
		a.playbacks.remove(id);
		element.onended = null;
		element.onerror = null;
		element.pause();
		element.removeAttribute("src");
		element.load();
		node.disconnect();
		a.disconnect(this);
	}

	override function stop(a:WebAudioAdapter, id:Int):Void
		finish(a, id);

	override function pause(a:WebAudioAdapter, id:Int, paused:Bool):Void {
		this.paused = paused;
		if (paused)
			element.pause();
		else
			element.play().then(_ -> null, error -> {
				finish(a, id);
				return null;
			});
	}

	override function setPitch(a:WebAudioAdapter, pitch:Float):Void {
		element.playbackRate = pitch;
		this.pitch = pitch;
	}

	override function getPosition(a:WebAudioAdapter):Float
		return element.currentTime;

	override function setPosition(a:WebAudioAdapter, id:Int, seconds:Float):Bool {
		var ranges = element.seekable, duration = Stream.durationOf(element);
		// Past the end clamped to it, where the element ends or loops as it would.
		if (duration > 0 && seconds > duration)
			seconds = duration;
		for (i in 0...ranges.length)
			if (seconds >= ranges.start(i) && seconds <= ranges.end(i)) {
				element.currentTime = seconds;
				return true;
			}
		return false;
	}
}

/** A queue's block of samples (one `queueSamples` call's): its interleaved floats and frames, how many of them were played before the
	voice last paused, and, while scheduled, its source, the context times it starts and ends at, and the rate it was scheduled with. */
@:structInit
@:allow(helix.platform.adapters.audio.webaudio)
private class Block {
	final samples:js.lib.Float32Array;
	final frames:Int;
	var offset = 0;
	var source:Dynamic = null;
	var start = 0.;
	var end = 0.;
	var rate = 1.;
}

/** A queue: its channels and rate, its blocks not yet played, the frames ever added, the context time its last scheduled block ends at,
	and its voice (0 for none). */
@:allow(helix.platform.adapters.audio.webaudio)
private class Queue extends Resource {
	final channels:Int;
	final rate:Int;
	var blocks:Array<Block> = [];
	var put = 0;
	var end = 0.;
	var voice = 0;

	function new(channels:Int, rate:Int) {
		this.channels = channels;
		this.rate = rate;
	}

	override function start(a:WebAudioAdapter, id:Int, gain:Dynamic, panner:Dynamic, loop:Bool, position:Float):Void {
		var v = new QueueVoice(id, gain, panner, put - queued(a));
		a.playbacks[id] = v;
		schedule(a, v);
	}

	override function seekable():Bool
		return false;

	override function stopWaiting(id:Int):Void {
		if (voice == id) {
			blocks = [];
			voice = 0;
		}
	}

	override function poll(a:WebAudioAdapter):Void
		prune(a);

	// The frames not yet heard: the blocks' frames past what they played, a scheduled block's from the time it has left.
	function queued(a:WebAudioAdapter):Int {
		prune(a);
		var now:Float = a.context == null ? 0 : a.context.currentTime, frames = 0.;
		for (block in blocks)
			frames += block.source == null || now <= block.start ? block.frames - block.offset : (block.end - now) * rate * block.rate;
		return Math.ceil(frames - 1e-6);
	}

	// Drops the blocks that have played to their end.
	function prune(a:WebAudioAdapter):Void {
		if (a.context == null)
			return;
		var now:Float = a.context.currentTime;
		while (blocks.length > 0 && blocks[0].source != null && blocks[0].end <= now)
			blocks.shift();
	}

	// Schedules the blocks not yet scheduled after the last one, at the voice's pitch, each through the voice's gain.
	function schedule(a:WebAudioAdapter, v:Voice):Void {
		var context = a.context;
		var at:Float = Math.max(end, context.currentTime);
		for (block in blocks) {
			if (block.source != null)
				continue;
			var frames = block.frames - block.offset;
			var buffer:Dynamic = context.createBuffer(channels, frames, rate);
			for (c in 0...channels) {
				var channel = new js.lib.Float32Array(frames);
				for (i in 0...frames)
					channel[i] = block.samples[(block.offset + i) * channels + c];
				buffer.copyToChannel(channel, c);
			}
			var source:Dynamic = context.createBufferSource();
			source.buffer = buffer;
			source.playbackRate.value = v.pitch;
			source.connect(v.gain);
			source.onended = _ -> source.disconnect();
			source.start(at);
			block.source = source;
			block.rate = v.pitch;
			block.start = at;
			block.end = at + frames / rate / v.pitch;
			at = block.end;
		}
		end = at;
	}

	// Takes the blocks off the clock, keeping what they hadn't played: the one playing keeps its place, those after it whole. With
	// fromNow false the block playing stays scheduled and only those after it are taken off.
	function unschedule(a:WebAudioAdapter, fromNow = true):Void {
		prune(a);
		var now:Float = a.context == null ? 0 : a.context.currentTime;
		end = 0;
		for (block in blocks) {
			if (block.source == null)
				continue;
			if (now > block.start) {
				if (!fromNow) {
					end = block.end;
					continue;
				}
				block.offset += Std.int(Math.min((now - block.start) * rate * block.rate, block.frames - block.offset));
			}
			block.source.onended = null;
			block.source.stop();
			block.source.disconnect();
			block.source = null;
		}
		blocks = [for (block in blocks) if (block.offset < block.frames) block];
	}
}

/** A queue's voice: the frames the queue had been given before it started, which its position counts from. */
@:allow(helix.platform.adapters.audio.webaudio)
private class QueueVoice extends Voice {
	final base:Int;

	function new(resource:Int, gain:Dynamic, panner:Dynamic, base:Int) {
		super(resource, gain, panner);
		this.base = base;
	}

	function queue(a:WebAudioAdapter):Queue
		return a.queues[resource];

	override function stop(a:WebAudioAdapter, id:Int):Void {
		// A queue's voice stopped drops what it hadn't played.
		var q = queue(a);
		a.playbacks.remove(id);
		q.unschedule(a);
		q.blocks = [];
		q.voice = 0;
		a.disconnect(this);
	}

	override function pause(a:WebAudioAdapter, id:Int, paused:Bool):Void {
		this.paused = paused;
		if (paused)
			queue(a).unschedule(a);
		else
			queue(a).schedule(a, this);
	}

	override function setPitch(a:WebAudioAdapter, pitch:Float):Void {
		// The block playing finishes at its rate; those after it are scheduled again at the new one.
		this.pitch = pitch;
		if (!paused) {
			var q = queue(a);
			q.unschedule(a, false);
			q.schedule(a, this);
		}
	}

	override function getPosition(a:WebAudioAdapter):Float {
		var q = queue(a);
		return (q.put - q.queued(a) - base) / q.rate;
	}
}

/** Provides `IAudio` in a browser page, over Web Audio.

	Clips are AudioBuffers and streams media elements routed through the audio graph, each voice a source through a gain and a stereo panner,
	its volume and pan changes approached by setTargetAtTime and its pitch the source's playback rate. A queue's blocks are AudioBuffers
	scheduled back to back on the context's clock, the browser resampling them; a pitch change reschedules the blocks not yet started. The page's first key, click or tap
	unlocks audio, as browsers let it start only in a user gesture; the page losing focus or being hidden suspends it. A voice asked for
	before then waits, its volume, pitch, pan and pause kept, and starts at the first poll once audio runs. */
@:allow(helix.platform.adapters.audio.webaudio)
class WebAudioAdapter implements IAudio {
	// The time constant a volume or pan change approaches its target by, in seconds: short enough to follow a fade stepped once a frame,
	// long enough not to click.
	static inline var RAMP = .01;

	var context:Dynamic;
	// Every clip, stream and queue, by id; and each kind's, for the calls that take only that kind.
	var resources:Map<Int, Resource> = [];
	var clips:Map<Int, Clip> = [];
	var streams:Map<Int, Stream> = [];
	var queues:Map<Int, Queue> = [];
	var playbacks:Map<Int, Voice> = [];
	// Voices asked for before audio ran, by id, started in order at the first poll once it runs.
	var waiting:Map<Int, {
		resource:Int,
		loop:Bool,
		volume:Float,
		pitch:Float,
		pan:Float,
		paused:Bool,
		position:Float
	}> = [];
	var nextClip = 1;
	var nextPlayback = 1;
	var output = true;

	// The events that unlock audio. A key or a mouse button counts as it goes down, but a finger only as it lifts (pointerup, touchend,
	// click): on a phone, a tap's pointerdown isn't a gesture the browser lets audio start in.
	static final GESTURES = ["keydown", "pointerdown", "pointerup", "touchend", "click"];

	/** Creates the output, listening for the page's gestures (as they reach the window, before the page's own handlers) and its visibility;
		no AudioContext exists until a gesture unlocks audio. */
	public function new() {
		for (name in GESTURES)
			js.Browser.window.addEventListener(name, _ -> unlock(), true);
		js.Browser.window.addEventListener("blur", _ -> suspend());
		js.Browser.document.addEventListener("visibilitychange", _ -> if (js.Browser.document.hidden) suspend());
	}

	// Creates the AudioContext if needed and resumes it; it works only in a user gesture (the page's listeners call it).
	function unlock():Void {
		if (context == null)
			context = js.Syntax.code("new (window.AudioContext || window.webkitAudioContext)()");
		// Outside a gesture the browser keeps it suspended and may refuse: the next gesture tries again.
		js.Syntax.code("{0}.resume().catch(function() {})", context);
	}

	// Suspends a running AudioContext, as when the page is hidden; the next gesture resumes it.
	function suspend():Void {
		if (context != null && context.state == "running")
			context.suspend();
	}

	public var available(get, never):Bool;

	function get_available():Bool
		return output;

	public var playsUrls(get, never):Bool;

	function get_playsUrls():Bool
		return true;

	public var running(get, never):Bool;

	function get_running():Bool
		return context != null && context.state == "running";

	public function createClip(samples:Bytes, channelCount:Int):Int {
		if (channelCount != 1 && channelCount != 2)
			throw "Audio clip channels must be 1 or 2";
		var frames = Std.int(samples.length / (4 * channelCount));
		if (frames == 0)
			throw "Audio clip creation failed";
		var id = nextClip++;
		var clip = new Clip(samples.sub(0, frames * channelCount * 4), channelCount);
		clips[id] = clip;
		resources[id] = clip;
		return id;
	}

	public function getStreamDuration(stream:Int):Float {
		var entry = streams[stream];
		if (entry == null)
			throw "Invalid audio stream";
		return entry.getDuration();
	}

	public function getStreamChannelCount(stream:Int):Int {
		var entry = streams[stream];
		if (entry == null)
			throw "Invalid audio stream";
		return entry.channels;
	}

	public function openStream(source:StreamSource, opened:Int->Void, failed:String->Void):Void->Void {
		var url = switch source {
			case Local(location): location;
			case Remote(url): url;
			case Downloading(_): null;
		};
		// A media element plays a URL, so a remote stream is given as one (playsUrls), never as a download.
		if (url == null) {
			var aborted = false;
			js.Browser.window.setTimeout(() -> if (!aborted) failed("A download isn't streamed in a browser; its URL is"), 0);
			return () -> aborted = true;
		}
		var element = js.Browser.document.createAudioElement(), settled = false, timer = 0, id = 0;
		// The file's channels from its header, which a second fetch of its first bytes reads (-1 until it has); the element doesn't say.
		var channels = -1, metadata = false;
		var fetching = new js.html.AbortController();
		function dispose():Void {
			fetching.abort();
			element.onloadedmetadata = null;
			element.onerror = null;
			element.pause();
			element.removeAttribute("src");
			element.load();
		}
		// Settles the open once: with the stream's id, or with message for a failure.
		function finish(?message:String):Void {
			if (settled)
				return;
			settled = true;
			js.Browser.window.clearTimeout(timer);
			element.onloadedmetadata = null;
			element.onerror = null;
			if (message != null) {
				failed(message);
				return;
			}
			fetching.abort();
			id = nextClip++;
			var stream = new Stream(url, element, channels < 0 ? 0 : channels);
			streams[id] = stream;
			resources[id] = stream;
			opened(id);
		}
		// Opens once both the element's metadata and the header have arrived.
		function ready():Void
			if (metadata && channels >= 0)
				finish();
		readChannels(url, fetching, read -> {
			channels = read;
			ready();
		});
		element.preload = "metadata";
		element.crossOrigin = "anonymous";
		element.onloadedmetadata = _ -> {
			metadata = true;
			ready();
		};
		element.onerror = _ -> {
			dispose();
			finish("Streamed audio failed: " + url);
		};
		timer = js.Browser.window.setTimeout(() -> {
			// Metadata without the header opens with the channels unknown.
			if (metadata) {
				finish();
				return;
			}
			dispose();
			finish("Streamed audio metadata timeout");
		}, 15000);
		element.src = url;
		element.load();
		return () -> {
			if (!settled) {
				settled = true;
				js.Browser.window.clearTimeout(timer);
				dispose();
			} else if (id != 0 && streams.exists(id))
				disposeStream(id);
		};
	}

	// Reads a file's channels from its first 64 KiB, fetched as a range and cut off there should the server send it all; 0 when the
	// fetch fails or the header doesn't tell. Nothing is called once aborted.
	static function readChannels(url:String, fetching:js.html.AbortController, read:Int->Void):Void {
		var limit = 65536, buffer = new js.lib.Uint8Array(limit), got = 0;
		function done():Void
			if (!fetching.signal.aborted)
				read(AudioHeader.readChannelCount(Bytes.ofData(buffer.buffer).sub(0, got)));
		var init:Dynamic = {headers: {"Range": 'bytes=0-${limit - 1}'}, signal: fetching.signal};
		js.Browser.window.fetch(url, init).then((response:Dynamic) -> {
			if (!response.ok || response.body == null) {
				done();
				return;
			}
			var reader:Dynamic = response.body.getReader();
			function next():Void
				reader.read().then((chunk:Dynamic) -> {
					if (chunk.done) {
						done();
						return;
					}
					var bytes:js.lib.Uint8Array = chunk.value;
					var count = Std.int(Math.min(bytes.length, limit - got));
					buffer.set(bytes.subarray(0, count), got);
					got += count;
					if (got < limit)
						next();
					else {
						reader.cancel();
						done();
					}
				}, _ -> done());
			next();
		}, _ -> done());
	}

	public function playClip(clip:Int, loop:Bool, volume:Float):Int {
		if (!clips.exists(clip))
			throw "Invalid audio clip";
		return play(clip, loop, volume);
	}

	public function playStream(stream:Int, loop:Bool, volume:Float):Int {
		if (!streams.exists(stream))
			throw "Invalid audio stream";
		return play(stream, loop, volume);
	}

	public function createQueue(channelCount:Int, sampleRate:Int):Int {
		if (channelCount != 1 && channelCount != 2)
			throw "Audio queue channels must be 1 or 2";
		if (sampleRate < 8000 || sampleRate > 96000)
			throw "Audio queue sample rate must be 8000 to 96000";
		var id = nextClip++;
		var q = new Queue(channelCount, sampleRate);
		queues[id] = q;
		resources[id] = q;
		return id;
	}

	public function queueSamples(queue:Int, samples:Bytes):Void {
		var q = queues[queue];
		if (q == null)
			throw "Invalid audio queue";
		var frames = Std.int(samples.length / (4 * q.channels));
		if (frames == 0)
			return;
		var copy = new js.lib.Float32Array(frames * q.channels);
		copy.set(new js.lib.Float32Array(samples.getData(), 0, frames * q.channels));
		var block:Block = {samples: copy, frames: frames};
		q.blocks.push(block);
		q.put += frames;
		var v = playbacks[q.voice];
		if (v != null && !v.paused)
			q.schedule(this, v);
	}

	public function getQueuedFrameCount(queue:Int):Int {
		var q = queues[queue];
		if (q == null)
			throw "Invalid audio queue";
		return q.queued(this);
	}

	public function disposeQueue(queue:Int):Void {
		var q = queues[queue];
		if (q == null)
			throw "Invalid audio queue";
		if (isPlaying(q.voice))
			stop(q.voice);
		queues.remove(queue);
		resources.remove(queue);
	}

	public function playQueue(queue:Int, volume:Float):Int {
		var q = queues[queue];
		if (q == null)
			throw "Invalid audio queue";
		// One voice a queue: the earlier one ends, the samples it hadn't played kept.
		if (!waiting.remove(q.voice)) {
			var earlier = playbacks[q.voice];
			if (earlier != null) {
				q.unschedule(this);
				playbacks.remove(q.voice);
				disconnect(earlier);
			}
		}
		q.voice = play(queue, false, volume);
		return q.voice;
	}

	// A new voice of resource: started now if audio runs, else waiting for it; 0 with no output.
	function play(resource:Int, loop:Bool, volume:Float):Int {
		if (!output)
			return 0;
		var id = nextPlayback++;
		if (this.running)
			start(id, resource, loop, volume, 0);
		else
			waiting[id] = {
				resource: resource,
				loop: loop,
				volume: volume,
				pitch: 1.,
				pan: 0.,
				paused: false,
				position: 0.
			};
		return id;
	}

	// A voice's gain and panner, out of the graph.
	function disconnect(v:Voice):Void {
		v.gain.disconnect();
		v.panner.disconnect();
	}

	function start(id:Int, resource:Int, loop:Bool, volume:Float, position:Float):Void {
		var gain:Dynamic = context.createGain(),
			panner:Dynamic = context.createStereoPanner();
		gain.gain.value = volume;
		gain.connect(panner);
		panner.connect(context.destination);
		resources[resource].start(this, id, gain, panner, loop, position);
	}

	public function stop(id:Int):Void {
		var w = waiting[id];
		if (w != null) {
			waiting.remove(id);
			var r = resources[w.resource];
			if (r != null)
				r.stopWaiting(id);
			return;
		}
		var v = playbacks[id];
		if (v != null)
			v.stop(this, id);
	}

	public function pause(id:Int, paused:Bool):Void {
		var w = waiting[id];
		if (w != null) {
			w.paused = paused;
			return;
		}
		var v = playbacks[id];
		if (v == null || v.paused == paused)
			return;
		v.pause(this, id, paused);
	}

	public function setVolume(id:Int, volume:Float):Bool {
		if (!Math.isFinite(volume) || volume < 0 || volume > 1)
			return false;
		var w = waiting[id];
		if (w != null) {
			w.volume = volume;
			return true;
		}
		var v = playbacks[id];
		if (v == null)
			return false;
		v.gain.gain.setTargetAtTime(volume, context.currentTime, RAMP);
		return true;
	}

	public function setPitch(id:Int, pitch:Float):Bool {
		var w = waiting[id];
		if (w != null) {
			w.pitch = pitch;
			return true;
		}
		var v = playbacks[id];
		if (v == null)
			return false;
		v.setPitch(this, pitch);
		return true;
	}

	public function setPan(id:Int, pan:Float):Bool {
		var w = waiting[id];
		if (w != null) {
			w.pan = pan;
			return true;
		}
		var v = playbacks[id];
		if (v == null)
			return false;
		v.panner.pan.setTargetAtTime(pan, context.currentTime, RAMP);
		return true;
	}

	public function isPlaying(id:Int):Bool
		return playbacks.exists(id) || waiting.exists(id);

	public function getPosition(id:Int):Float {
		var w = waiting[id];
		if (w != null)
			return w.position;
		var v = playbacks[id];
		return v == null ? 0 : v.getPosition(this);
	}

	public function setPosition(id:Int, seconds:Float):Bool {
		if (!Math.isFinite(seconds) || seconds < 0)
			return false;
		var w = waiting[id];
		if (w != null) {
			var r = resources[w.resource];
			if (r != null && !r.seekable())
				return false;
			w.position = seconds;
			return true;
		}
		var v = playbacks[id];
		return v != null && v.setPosition(this, id, seconds);
	}

	public function disposeClip(id:Int):Void {
		if (!clips.exists(id))
			throw "Invalid audio clip";
		release(id);
		clips.remove(id);
	}

	public function disposeStream(id:Int):Void {
		if (!streams.exists(id))
			throw "Invalid audio stream";
		release(id);
		streams.remove(id);
	}

	// Stops a clip's or stream's voices, those waiting dropped, and lets go of what it holds.
	function release(id:Int):Void {
		for (playback in [for (p in playbacks.keys()) if (playbacks[p].resource == id) p])
			stop(playback);
		for (voice in [for (w in waiting.keys()) if (waiting[w].resource == id) w])
			waiting.remove(voice);
		resources[id].release();
		resources.remove(id);
	}

	/** Starts the voices that waited, in the order asked, once audio runs, and lets go of queue blocks played; media elements and the audio
		graph run on their own. */
	public function poll():Void {
		for (r in resources)
			r.poll(this);
		if (!this.running || !waiting.keys().hasNext())
			return;
		var ids = [for (id in waiting.keys()) id];
		ids.sort((a, b) -> a - b);
		for (id in ids) {
			var w = waiting[id];
			waiting.remove(id);
			start(id, w.resource, w.loop, w.volume, w.position);
			if (w.pitch != 1)
				setPitch(id, w.pitch);
			if (w.pan != 0)
				setPan(id, w.pan);
			if (w.paused)
				pause(id, true);
		}
	}

	public function dispose():Void {
		waiting.clear();
		for (id in [for (p in playbacks.keys()) p])
			stop(id);
		for (r in resources)
			r.release();
		resources.clear();
		clips.clear();
		streams.clear();
		queues.clear();
		if (context != null) {
			context.close();
			context = null;
		}
	}
}
