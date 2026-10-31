package helix.platform.adapters.audio.webaudio;

import haxe.io.Bytes;
import helix.platform.IAudio;
import helix.platform.StreamSource;

/** A queue's block of samples (one `queueSamples` call's): its interleaved floats and frames, how many of them were played before the
	voice last paused, and, while scheduled, its source, the context times it starts and ends at, and the rate it was scheduled with. */
@:structInit
@:allow(helix.platform.adapters.audio.webaudio.WebAudioAdapter)
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
@:structInit
@:allow(helix.platform.adapters.audio.webaudio.WebAudioAdapter)
private class Queue {
	final channels:Int;
	final rate:Int;
	var blocks:Array<Block> = [];
	var put = 0;
	var end = 0.;
	var voice = 0;
}

/** Provides `IAudio` in a browser page, over Web Audio.

	Clips are AudioBuffers and streams media elements routed through the audio graph, each voice a source through a gain and a stereo panner,
	its volume and pan changes approached by setTargetAtTime and its pitch the source's playback rate. A queue's blocks are AudioBuffers
	scheduled back to back on the context's clock, the browser resampling them; a pitch change reschedules the blocks not yet started. The page's first key, click or tap
	unlocks audio, as browsers let it start only in a user gesture; the page losing focus or being hidden suspends it. A voice asked for
	before then waits, its volume, pitch, pan and pause kept, and starts at the first poll once audio runs. */
class WebAudioAdapter implements IAudio {
	// The time constant a volume or pan change approaches its target by, in seconds: short enough to follow a fade stepped once a frame,
	// long enough not to click.
	static inline var RAMP = .01;

	var context:Dynamic;
	var clips:Map<Int, {samples:Bytes, channels:Int}> = [];
	var buffers:Map<Int, Dynamic> = [];
	var streams:Map<Int, {url:String, element:Null<js.html.AudioElement>, duration:Float}> = [];
	var queues:Map<Int, Queue> = [];
	var playbacks:Map<Int, Dynamic> = [];
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

	public function createClip(samples:Bytes, channels:Int):Int {
		if (channels != 1 && channels != 2)
			throw "Audio clip channels must be 1 or 2";
		var frames = Std.int(samples.length / (4 * channels));
		if (frames == 0)
			throw "Audio clip creation failed";
		var id = nextClip++;
		clips[id] = {samples: samples.sub(0, frames * channels * 4), channels: channels};
		return id;
	}

	// A media element's duration in seconds, 0 while unknown (NaN) or for a live stream (Infinity).
	static function durationOf(element:js.html.AudioElement):Float {
		var duration = element.duration;
		return Math.isFinite(duration) && duration > 0 ? duration : 0;
	}

	public function getStreamDuration(stream:Int):Float {
		var entry = streams[stream];
		if (entry == null)
			throw "Invalid audio stream";
		return entry.element != null ? durationOf(entry.element) : entry.duration;
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
		function dispose():Void {
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
			if (message == null)
				opened(id);
			else
				failed(message);
		}
		element.preload = "metadata";
		element.crossOrigin = "anonymous";
		element.onloadedmetadata = _ -> {
			id = nextClip++;
			streams[id] = {url: url, element: element, duration: durationOf(element)};
			finish();
		};
		element.onerror = _ -> {
			dispose();
			finish("Streamed audio failed: " + url);
		};
		timer = js.Browser.window.setTimeout(() -> {
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

	function clipSource(id:Int, v:Dynamic):Void {
		var source:Dynamic = context.createBufferSource();
		source.buffer = v.buffer;
		source.loop = v.loop;
		source.playbackRate.value = v.pitch;
		source.connect(v.gain);
		v.source = source;
		v.started = context.currentTime;
		v.paused = false;
		source.onended = _ -> {
			if (playbacks[id] == v && !v.paused) {
				playbacks.remove(id);
				source.disconnect();
				disconnect(v);
			}
		};
		source.start(0, v.offset);
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

	public function createQueue(channels:Int, sampleRate:Int):Int {
		if (channels != 1 && channels != 2)
			throw "Audio queue channels must be 1 or 2";
		if (sampleRate < 8000 || sampleRate > 96000)
			throw "Audio queue sample rate must be 8000 to 96000";
		var id = nextClip++;
		var q:Queue = {channels: channels, rate: sampleRate};
		queues[id] = q;
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
			schedule(q, v);
	}

	public function getQueuedFrames(queue:Int):Int {
		var q = queues[queue];
		if (q == null)
			throw "Invalid audio queue";
		return queued(q);
	}

	public function disposeQueue(queue:Int):Void {
		var q = queues[queue];
		if (q == null)
			throw "Invalid audio queue";
		if (isPlaying(q.voice))
			stop(q.voice);
		queues.remove(queue);
	}

	public function playQueue(queue:Int, volume:Float):Int {
		var q = queues[queue];
		if (q == null)
			throw "Invalid audio queue";
		// One voice a queue: the earlier one ends, the samples it hadn't played kept.
		if (!waiting.remove(q.voice)) {
			var earlier = playbacks[q.voice];
			if (earlier != null) {
				unschedule(q);
				playbacks.remove(q.voice);
				disconnect(earlier);
			}
		}
		q.voice = play(queue, false, volume);
		return q.voice;
	}

	// The frames of a queue not yet heard: its blocks' frames past what they played, a scheduled block's from the time it has left.
	function queued(q:Queue):Int {
		prune(q);
		var now:Float = context == null ? 0 : context.currentTime, frames = 0.;
		for (block in q.blocks)
			frames += block.source == null || now <= block.start ? block.frames - block.offset : (block.end - now) * q.rate * block.rate;
		return Math.ceil(frames - 1e-6);
	}

	// Drops a queue's blocks that have played to their end.
	function prune(q:Queue):Void {
		if (context == null)
			return;
		var now:Float = context.currentTime;
		while (q.blocks.length > 0 && q.blocks[0].source != null && q.blocks[0].end <= now)
			q.blocks.shift();
	}

	// Schedules a queue's blocks not yet scheduled after the last one, at the voice's pitch, each through the voice's gain.
	function schedule(q:Queue, v:Dynamic):Void {
		var at:Float = Math.max(q.end, context.currentTime);
		for (block in q.blocks) {
			if (block.source != null)
				continue;
			var frames = block.frames - block.offset;
			var buffer:Dynamic = context.createBuffer(q.channels, frames, q.rate);
			for (c in 0...q.channels) {
				var channel = new js.lib.Float32Array(frames);
				for (i in 0...frames)
					channel[i] = block.samples[(block.offset + i) * q.channels + c];
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
			block.end = at + frames / q.rate / v.pitch;
			at = block.end;
		}
		q.end = at;
	}

	// Takes a queue's blocks off the clock, keeping what they hadn't played: the one playing keeps its place, those after it whole. With
	// fromNow false the block playing stays scheduled and only those after it are taken off.
	function unschedule(q:Queue, fromNow = true):Void {
		prune(q);
		var now:Float = context == null ? 0 : context.currentTime;
		q.end = 0;
		for (block in q.blocks) {
			if (block.source == null)
				continue;
			if (now > block.start) {
				if (!fromNow) {
					q.end = block.end;
					continue;
				}
				block.offset += Std.int(Math.min((now - block.start) * q.rate * block.rate, block.frames - block.offset));
			}
			block.source.onended = null;
			block.source.stop();
			block.source.disconnect();
			block.source = null;
		}
		q.blocks = [for (block in q.blocks) if (block.offset < block.frames) block];
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
	function disconnect(v:Dynamic):Void {
		v.gain.disconnect();
		v.panner.disconnect();
	}

	function start(id:Int, resource:Int, loop:Bool, volume:Float, position:Float):Void {
		var gain:Dynamic = context.createGain(),
			panner:Dynamic = context.createStereoPanner();
		gain.gain.value = volume;
		gain.connect(panner);
		panner.connect(context.destination);
		if (queues.exists(resource)) {
			var q = queues[resource];
			var v:Dynamic = {
				kind: "queue",
				gain: gain,
				panner: panner,
				resource: resource,
				pitch: 1.,
				paused: false,
				base: 0
			};
			v.base = q.put - queued(q);
			playbacks[id] = v;
			schedule(q, v);
		} else if (streams.exists(resource)) {
			var entry = streams[resource],
				element:js.html.AudioElement = entry.element;
			if (element == null) {
				element = js.Browser.document.createAudioElement();
				element.crossOrigin = "anonymous";
				element.src = entry.url;
			}
			entry.element = null;
			element.ondurationchange = _ -> if (streams[resource] == entry) entry.duration = durationOf(element);
			element.loop = loop;
			element.playbackRate = 1;
			if (position > 0)
				element.currentTime = position;
			// The rate changes the pitch too, as a clip's does.
			Reflect.setField(element, "preservesPitch", false);
			var source:Dynamic = context.createMediaElementSource(element);
			source.connect(gain);
			var v:Dynamic = {
				kind: "stream",
				source: element,
				node: source,
				gain: gain,
				panner: panner,
				resource: resource,
				pitch: 1.,
				paused: false
			};
			playbacks[id] = v;
			element.onended = _ -> finishStream(id, v);
			element.onerror = _ -> finishStream(id, v);
			element.play().catchError(error -> {
				finishStream(id, v);
				return null;
			});
		} else {
			var buffer = buffers[resource];
			if (buffer == null) {
				var clip = clips[resource], channels = clip.channels;
				var data = new js.lib.Float32Array(clip.samples.getData(), 0, Std.int(clip.samples.length / 4));
				var frames = Std.int(data.length / channels);
				buffer = context.createBuffer(channels, frames, 44100);
				for (c in 0...channels) {
					var channel = new js.lib.Float32Array(frames);
					for (i in 0...frames)
						channel[i] = data[i * channels + c];
					buffer.copyToChannel(channel, c);
				}
				buffers[resource] = buffer;
			}
			var v:Dynamic = {
				kind: "clip",
				source: null,
				gain: gain,
				panner: panner,
				resource: resource,
				pitch: 1.,
				buffer: buffer,
				loop: loop,
				offset: Math.min(position, buffer.duration),
				started: 0.,
				paused: false
			};
			playbacks[id] = v;
			clipSource(id, v);
		}
	}

	function finishStream(id:Int, v:Dynamic):Void {
		if (playbacks[id] != v)
			return;
		playbacks.remove(id);
		v.source.onended = null;
		v.source.onerror = null;
		v.source.pause();
		v.source.removeAttribute("src");
		v.source.load();
		v.node.disconnect();
		disconnect(v);
	}

	public function stop(id:Int):Void {
		var w = waiting[id];
		if (w != null) {
			waiting.remove(id);
			var q = queues[w.resource];
			if (q != null && q.voice == id) {
				q.blocks = [];
				q.voice = 0;
			}
			return;
		}
		var v = playbacks[id];
		if (v == null)
			return;
		if (v.kind == "stream")
			finishStream(id, v);
		else if (v.kind == "queue") {
			// A queue's voice stopped drops what it hadn't played.
			var q = queues[v.resource];
			playbacks.remove(id);
			unschedule(q);
			q.blocks = [];
			q.voice = 0;
			disconnect(v);
		} else {
			playbacks.remove(id);
			v.source.onended = null;
			if (!v.paused)
				v.source.stop();
			v.source.disconnect();
			disconnect(v);
		}
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
		if (v.kind == "queue") {
			v.paused = paused;
			if (paused)
				unschedule(queues[v.resource]);
			else
				schedule(queues[v.resource], v);
		} else if (v.kind == "stream") {
			v.paused = paused;
			if (paused)
				v.source.pause();
			else
				v.source.play().then(_ -> null, error -> {
					finishStream(id, v);
					return null;
				});
		} else if (paused) {
			played(v);
			v.paused = true;
			v.source.onended = null;
			v.source.stop();
			v.source.disconnect();
		} else {
			if (v.offset >= v.buffer.duration) {
				stop(id);
				return;
			}
			clipSource(id, v);
		}
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

	// Moves a playing clip voice's offset (in the buffer's seconds) on by what it played since it started or last moved, at its pitch.
	function played(v:Dynamic):Void {
		var now:Float = context.currentTime;
		v.offset += (now - v.started) * v.pitch;
		if (v.loop)
			v.offset %= v.buffer.duration;
		v.started = now;
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
		if (v.kind == "queue") {
			// The block playing finishes at its rate; those after it are scheduled again at the new one.
			v.pitch = pitch;
			if (!v.paused) {
				var q = queues[v.resource];
				unschedule(q, false);
				schedule(q, v);
			}
			return true;
		}
		if (v.kind == "stream")
			v.source.playbackRate = pitch;
		else if (!v.paused) {
			played(v);
			v.source.playbackRate.value = pitch;
		}
		v.pitch = pitch;
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
		if (v == null)
			return 0;
		switch v.kind {
			case "queue":
				var q = queues[v.resource];
				return (q.put - queued(q) - v.base) / q.rate;
			case "stream":
				return v.source.currentTime;
			case _:
				var offset:Float = v.paused ? v.offset : v.offset + (context.currentTime - v.started) * v.pitch,
					duration:Float = v.buffer.duration;
				return v.loop ? offset % duration : Math.min(offset, duration);
		}
	}

	public function setPosition(id:Int, seconds:Float):Bool {
		if (!Math.isFinite(seconds) || seconds < 0)
			return false;
		var w = waiting[id];
		if (w != null) {
			if (queues.exists(w.resource))
				return false;
			w.position = seconds;
			return true;
		}
		var v = playbacks[id];
		if (v == null || v.kind == "queue")
			return false;
		if (v.kind == "stream") {
			var element:js.html.AudioElement = v.source,
				ranges = element.seekable,
				duration = durationOf(element);
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
		var duration:Float = v.buffer.duration;
		if (seconds >= duration) {
			if (!v.loop) {
				stop(id);
				return true;
			}
			seconds = 0;
		}
		if (v.paused) {
			v.offset = seconds;
			return true;
		}
		v.source.onended = null;
		v.source.stop();
		v.source.disconnect();
		v.offset = seconds;
		clipSource(id, v);
		return true;
	}

	public function disposeClip(id:Int):Void {
		if (!clips.exists(id))
			throw "Invalid audio clip";
		for (playback in [for (p in playbacks.keys()) if (playbacks[p].resource == id) p])
			stop(playback);
		for (voice in [for (w in waiting.keys()) if (waiting[w].resource == id) w])
			waiting.remove(voice);
		clips.remove(id);
		buffers.remove(id);
	}

	public function disposeStream(id:Int):Void {
		var entry = streams[id];
		if (entry == null)
			throw "Invalid audio stream";
		for (playback in [for (p in playbacks.keys()) if (playbacks[p].resource == id) p])
			stop(playback);
		for (voice in [for (w in waiting.keys()) if (waiting[w].resource == id) w])
			waiting.remove(voice);
		if (entry.element != null) {
			entry.element.removeAttribute("src");
			entry.element.load();
		}
		streams.remove(id);
	}

	/** Starts the voices that waited, in the order asked, once audio runs, and lets go of queue blocks played; media elements and the audio
		graph run on their own. */
	public function poll():Void {
		for (q in queues)
			prune(q);
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
		for (id in [for (s in streams.keys()) s])
			disposeStream(id);
		queues.clear();
		clips.clear();
		buffers.clear();
		if (context != null) {
			context.close();
			context = null;
		}
	}
}
