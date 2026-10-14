package helix.adapters.audio.webaudio;

import haxe.io.Bytes;
import helix.assets.IAssets.AudioLocation;
import helix.audio.IAudio;

/** IAudio in a browser over Web Audio: clips become AudioBuffers, streams are media elements routed through the audio graph. The page's first
	key or pointer press unlocks audio (browsers let it start only in a user gesture); the page losing focus or being hidden suspends it. */
class WebAudioAdapter implements IAudio {
	var context:Dynamic;
	var clips:Map<Int, Bytes> = [];
	var buffers:Map<Int, Dynamic> = [];
	var streams:Map<Int, {url:String, element:Null<js.html.AudioElement>}> = [];
	var playbacks:Map<Int, Dynamic> = [];
	var nextClip = 1;
	var nextPlayback = 1;

	/** Listens for the page's gestures and visibility; no AudioContext until a gesture unlocks audio. */
	public function new() {
		js.Browser.window.addEventListener("keydown", _ -> unlock());
		js.Browser.window.addEventListener("pointerdown", _ -> unlock());
		js.Browser.window.addEventListener("blur", _ -> suspend());
		js.Browser.document.addEventListener("visibilitychange", _ -> if (js.Browser.document.hidden) suspend());
	}

	/** Creates the AudioContext if needed and resumes it; it works only in a user gesture (the page's listeners call it). */
	public function unlock():Void {
		if (context == null)
			context = js.Syntax.code("new (window.AudioContext || window.webkitAudioContext)()");
		context.resume();
	}

	/** Suspends a running AudioContext, as when the page is hidden; the next gesture resumes it. */
	public function suspend():Void {
		if (context != null && context.state == "running")
			context.suspend();
	}

	public function isAvailable():Bool
		return true;

	public function isRunning():Bool
		return context != null && context.state == "running";

	public function createClip(samples:Bytes):Int {
		var id = nextClip++;
		clips[id] = samples.sub(0, samples.length);
		return id;
	}

	public function openStream(location:AudioLocation, done:StreamOpenResult->Void):Void->Void {
		var url = switch location {
			case Stored(value): value.location;
			case Remote(url): url;
		}, element = js.Browser.document.createAudioElement(), settled = false, timer = 0, opened = 0;
		function dispose():Void {
			element.onloadedmetadata = null;
			element.onerror = null;
			element.pause();
			element.removeAttribute("src");
			element.load();
		}
		function finish(result:StreamOpenResult):Void {
			if (settled)
				return;
			settled = true;
			js.Browser.window.clearTimeout(timer);
			element.onloadedmetadata = null;
			element.onerror = null;
			done(result);
		}
		element.preload = "metadata";
		element.crossOrigin = "anonymous";
		element.onloadedmetadata = _ -> {
			opened = nextClip++;
			streams[opened] = {url: url, element: element};
			finish(Opened(opened));
		};
		element.onerror = _ -> {
			dispose();
			finish(Failed("Streamed audio failed: " + url));
		};
		timer = js.Browser.window.setTimeout(() -> {
			dispose();
			finish(Failed("Streamed audio metadata timeout"));
		}, 15000);
		element.src = url;
		element.load();
		return () -> {
			if (!settled) {
				settled = true;
				js.Browser.window.clearTimeout(timer);
				dispose();
			} else if (opened != 0 && streams.exists(opened))
				destroyStream(opened);
		};
	}

	function clipSource(id:Int, v:Dynamic):Void {
		var source:Dynamic = context.createBufferSource();
		source.buffer = v.buffer;
		source.loop = v.loop;
		source.connect(v.gain);
		v.source = source;
		v.started = context.currentTime;
		v.paused = false;
		source.onended = _ -> {
			if (playbacks[id] == v && !v.paused) {
				playbacks.remove(id);
				source.disconnect();
				v.gain.disconnect();
			}
		};
		source.start(0, v.offset);
	}

	public function playClip(clip:Int, loop:Bool, volume:Float):Int {
		if (!clips.exists(clip))
			throw "Invalid audio clip";
		if (!isRunning())
			return 0;
		var id = nextPlayback++;
		start(id, clip, loop, volume);
		return id;
	}

	public function playStream(stream:Int, loop:Bool, volume:Float):Int {
		if (!streams.exists(stream))
			throw "Invalid audio stream";
		if (!isRunning())
			return 0;
		var id = nextPlayback++;
		start(id, stream, loop, volume);
		return id;
	}

	function start(id:Int, resource:Int, loop:Bool, volume:Float):Void {
		var gain:Dynamic = context.createGain();
		gain.gain.value = volume;
		gain.connect(context.destination);
		if (streams.exists(resource)) {
			var entry = streams[resource],
				element:js.html.AudioElement = entry.element;
			if (element == null) {
				element = js.Browser.document.createAudioElement();
				element.crossOrigin = "anonymous";
				element.src = entry.url;
			}
			entry.element = null;
			element.loop = loop;
			var source:Dynamic = context.createMediaElementSource(element);
			source.connect(gain);
			var v:Dynamic = {
				kind: "stream",
				source: element,
				node: source,
				gain: gain,
				resource: resource,
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
				var data = clips[resource];
				buffer = context.createBuffer(1, Std.int(data.length / 4), 44100);
				buffer.copyToChannel(new js.lib.Float32Array(data.getData()), 0);
				buffers[resource] = buffer;
			}
			var v:Dynamic = {
				kind: "clip",
				source: null,
				gain: gain,
				resource: resource,
				buffer: buffer,
				loop: loop,
				offset: 0.,
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
		v.gain.disconnect();
	}

	public function stop(id:Int):Void {
		var v = playbacks[id];
		if (v == null)
			return;
		if (v.kind == "stream")
			finishStream(id, v);
		else {
			playbacks.remove(id);
			v.source.onended = null;
			if (!v.paused)
				v.source.stop();
			v.source.disconnect();
			v.gain.disconnect();
		}
	}

	public function pause(id:Int, paused:Bool):Void {
		var v = playbacks[id];
		if (v == null || v.paused == paused)
			return;
		if (v.kind == "stream") {
			v.paused = paused;
			if (paused)
				v.source.pause();
			else
				v.source.play().then(_ -> null, error -> {
					finishStream(id, v);
					return null;
				});
		} else if (paused) {
			v.offset += context.currentTime - v.started;
			if (v.loop)
				v.offset %= v.buffer.duration;
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

	public function setVolume(id:Int, volume:Float):Void {
		var v = playbacks[id];
		if (v != null)
			v.gain.gain.value = volume;
	}

	public function isPlaying(id:Int):Bool
		return playbacks.exists(id);

	public function destroyClip(id:Int):Void {
		if (!clips.exists(id))
			throw "Invalid audio clip";
		for (playback in [for (p in playbacks.keys()) if (playbacks[p].resource == id) p])
			stop(playback);
		clips.remove(id);
		buffers.remove(id);
	}

	public function destroyStream(id:Int):Void {
		var entry = streams[id];
		if (entry == null)
			throw "Invalid audio stream";
		for (playback in [for (p in playbacks.keys()) if (playbacks[p].resource == id) p])
			stop(playback);
		if (entry.element != null) {
			entry.element.removeAttribute("src");
			entry.element.load();
		}
		streams.remove(id);
	}

	/** Nothing to keep fed: media elements and the audio graph run on their own. */
	public function poll():Void {}

	public function shutdown():Void {
		for (id in [for (p in playbacks.keys()) p])
			stop(id);
		for (id in [for (s in streams.keys()) s])
			destroyStream(id);
		clips.clear();
		buffers.clear();
		if (context != null) {
			context.close();
			context = null;
		}
	}
}
