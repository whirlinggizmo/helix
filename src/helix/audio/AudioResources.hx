package helix.audio;

import helix.assets.Failure;
import helix.assets.IRequest;
import helix.assets.Request;
import helix.core.WorkQueue;
import helix.assets.IAssets;
import helix.audio.IAudio;
import helix.assets.IReloadable;

/** Sounds, the same on every platform: clips loaded through the assets and decoded whole (AudioDecoding), streams opened from a cached or
	packaged copy (or a remote URL where the platform plays one), their lifetimes counted, and playbacks, which wait while audio hasn't
	started. Plays on a platform's IAudio, which it polls; neither that nor the decoding is shut down by it. */
@:build(helix.macro.Facade.record())
class AudioResources implements IReloadable {
	var assets:IAssets;
	var backend:IAudio;
	var decoding:AudioDecoding;
	var playbacks:Array<AudioPlayback> = [];
	var resources:Array<AudioResource> = [];
	var requests:Array<IRequest> = [];
	var queue = new WorkQueue();
	var live = true;

	/** Backend clips a reload replaced, destroyed once nothing started from them still plays. */
	var retired:Array<Int> = [];

	/** Loads through assets, decodes with decoding (polled by its owner) and plays on backend (polled here). */
	public function new(assets:IAssets, backend:IAudio, decoding:AudioDecoding) {
		this.assets = assets;
		this.backend = backend;
		this.decoding = decoding;
	}

	/** Loads path and decodes it whole into a clip, which reloads in place when the file changes. One of loaded or failed runs once on the host
		thread, and neither once the request is cancelled: loaded with a clip the caller owns and releases; failed (else the log, with the path)
		for a closed service, a load or decode failure, or a clip the backend refuses. A clip that arrives after cancellation is released. */
	public function loadClip(path:String, loaded:AudioClip->Void, ?failed:String->Void):IRequest {
		var child:IRequest = null, request:Request = null;
		// Ends the request with a clip, or a failure for null; a clip that arrives too late is released.
		function finish(clip:Null<AudioClip>, ?message:String) {
			if (request.finish()) {
				requests.remove(request);
				queue.add(() -> if (clip != null) loaded(clip) else Failure.report(path, message, failed));
			} else if (clip != null)
				clip.release();
		}
		// A cancellation from below (a service shutting down) ends the request telling no one.
		function stop()
			if (request.finish())
				requests.remove(request);
		request = new Request(() -> {
			if (child != null)
				child.cancel();
			requests.remove(request);
		});
		requests.push(request);
		if (!live) {
			queue.add(() -> finish(null, "Closed audio resource service"));
			return request;
		}
		var loading = assets.ensure(path, bytes -> {
			if (request.settled)
				return;
			child = decoding.decode(bytes, result -> {
				if (request.settled)
					return;
				switch result {
					case Decoded(samples): try {
							var resource = new AudioClip(backend.createClip(samples), backend, path);
							resources.push(resource);
							assets.subscribe(path, this);
							finish(resource);
						} catch (error:Dynamic)
							finish(null, Std.string(error));
					case Failed(message): finish(null, message);
					case Cancelled: stop();
				}
			});
		}, message -> if (!request.settled) finish(null, message));
		if (child == null)
			child = loading;
		return request;
	}

	/** Opens path for progressive playback from a cached or packaged copy, or else its remote URL, without loading it whole. One of loaded or
		failed runs once on the host thread, and neither once the request is cancelled: loaded with a stream the caller owns and releases (its
		stored copy's lease ends with it); failed (else the log, with the path) for a closed service, a missing asset, or a source the backend
		cannot open, such as a remote URL natively. */
	public function loadStream(path:String, loaded:AudioStream->Void, ?failed:String->Void):IRequest {
		var child:IRequest = null,
			request:Request = null,
			abort:Null<Void->Void> = null;
		// Ends the request with a stream, or a failure for null; a stream that arrives too late is released.
		function finish(stream:Null<AudioStream>, ?message:String) {
			if (request.finish()) {
				requests.remove(request);
				queue.add(() -> if (stream != null) loaded(stream) else Failure.report(path, message, failed));
			} else if (stream != null)
				stream.release();
		}
		request = new Request(() -> {
			if (child != null)
				child.cancel();
			if (abort != null)
				abort();
			requests.remove(request);
		});
		requests.push(request);
		if (!live) {
			queue.add(() -> finish(null, "Closed audio resource service"));
			return request;
		}
		child = assets.streamSource(path, source -> {
			if (request.settled) {
				switch source {
					case Stored(value): value.release();
					case _:
				}
				return;
			}
			var release = switch source {
				case Stored(value): value.release;
				case Remote(_): () -> {};
			}
			child = null;
			abort = backend.openStream(source, result -> {
				abort = null;
				switch result {
					case Opened(id):
						var resource = new AudioStream(id, backend, release);
						resources.push(resource);
						finish(resource);
					case Failed(message):
						release();
						finish(null, message);
				}
			});
		}, message -> if (!request.settled) finish(null, message));
		return request;
	}

	/** Starts resource from the beginning at volume 0 to 1, looping if asked; the playback holds the resource until it stops or finishes. While
		audio hasn't started (a browser before the page's first key or pointer press) the playback waits and starts once it runs; without an
		output, or with no free voice, it's finished at once. Throws for a closed service, a resource of another backend or already released by
		its owner, or a volume outside 0 to 1. */
	public function play(resource:AudioResource, loop = false, volume = 1.):AudioPlayback {
		if (!live || resource.backend != backend)
			throw "Invalid audio resource service";
		if (!Math.isFinite(volume) || volume < 0 || volume > 1)
			throw "Invalid volume";
		resource.retainPlayback();
		var playback = try new AudioPlayback(resource, loop, volume) catch (error:Dynamic) {
			resource.releasePlayback();
			throw error;
		};
		if (!playback.finished)
			playbacks.push(playback);
		return playback;
	}

	/** A clip's file changed: decode it, then give each clip from that path a new backend clip in place. */
	public function reloaded(path:String, bytes:haxe.io.Bytes):Void {
		if (!live)
			return;
		decoding.decode(bytes, result -> switch result {
			case Decoded(samples):
				for (resource in resources)
					if (!resource.disposed && Std.isOfType(resource, AudioClip) && (cast resource : AudioClip).path == path) {
						retired.push(resource.id);
						resource.id = backend.createClip(samples);
					}
			case Failed(message): trace('Reloaded clip failed to decode, kept the old one: ' + path + ': ' + message);
			case Cancelled:
		});
	}

	/** Polls the backend, destroys replaced clips nothing still plays, drops disposed resources and finished playbacks, and runs queued completions. Call once per frame on the host thread. */
	public function poll():Void {
		backend.poll();
		for (id in retired.copy())
			if (!Lambda.exists(playbacks, p -> !p.finished && p.source == id)) {
				retired.remove(id);
				backend.destroyClip(id);
			}
		resources = [for (resource in resources) if (!resource.disposed) resource];
		for (playback in playbacks.copy()) {
			playback.poll();
			if (playback.finished)
				playbacks.remove(playback);
		}
		queue.poll();
	}

	/** Cancels pending loads (telling none of their callers), stops every playback, releases the owner's reference on every resource, destroys replaced clips, and refuses later loads and plays. */
	public function shutdown():Void {
		live = false;
		for (request in requests.copy())
			request.cancel();
		for (playback in playbacks)
			playback.stop();
		playbacks = [];
		for (resource in resources)
			resource.release();
		resources = [];
		for (id in retired)
			backend.destroyClip(id);
		retired = [];
		queue.poll();
	}
}
