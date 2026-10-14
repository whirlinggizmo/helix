package helix.audio;

import helix.assets.IRequest;
import helix.assets.Request;
import helix.core.WorkQueue;
import helix.assets.IAssets;
import helix.audio.IAudio;
import helix.assets.IReloadable;

/** How an audio load ended: the resource, which the caller owns and releases, a failure message, or cancellation. */
enum AudioLoadResult<T> {
	Ready(resource:T);
	Failed(message:String);
	Cancelled;
}

/** Sounds, the same on every platform: clips loaded through the assets and decoded whole (AudioDecoding), streams opened from a cached or
	packaged copy (or a remote URL where the platform plays one), their lifetimes counted, and playbacks, which wait while audio hasn't
	started. Plays on a platform's IAudio, which it polls; neither that nor the decoding is shut down by it. */
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

	/** Loads path and decodes it whole into a clip, which reloads in place when the file changes. complete runs exactly once on the host thread with a clip the caller owns and releases; Failed for a closed service, a load or decode failure, or a clip the backend refuses. A clip that arrives after cancellation is released. */
	public function loadClip(path:String, complete:AudioLoadResult<AudioClip>->Void):IRequest {
		var child:IRequest = null, request:Request = null;
		function finish(result:AudioLoadResult<AudioClip>) {
			if (request.finish()) {
				requests.remove(request);
				queue.add(() -> complete(result));
			} else
				switch result {
					case Ready(resource):
						resource.release();
					case _:
				}
		}
		request = new Request(() -> {
			if (child != null)
				child.cancel();
			requests.remove(request);
			queue.add(() -> complete(Cancelled));
		});
		requests.push(request);
		if (!live) {
			queue.add(() -> finish(Failed("Closed audio resource service")));
			return request;
		}
		child = assets.ensure(path, result -> {
			if (request.isSettled())
				return;
			switch result {
				case Loaded(bytes): child = decoding.decode(bytes, result -> {
						if (request.isSettled())
							return;
						switch result {
							case Decoded(samples): try {
									var resource = new AudioClip(backend.createClip(samples), backend, path);
									resources.push(resource);
									assets.subscribe(path, this);
									finish(Ready(resource));
								} catch (error:Dynamic)
									finish(Failed(Std.string(error)));
							case Failed(message): finish(Failed(message));
							case Cancelled: finish(Cancelled);
						}
					});
				case Failed(message): finish(Failed(message));
				case Cancelled: finish(Cancelled);
			}
		});
		return request;
	}

	/** Opens path for progressive playback from a cached or packaged copy, or else its remote URL, without loading it whole. complete runs exactly once on the host thread with a stream the caller owns and releases (its stored copy's lease ends with it); Failed for a closed service, a missing asset, or a source the backend cannot open, such as a remote URL natively. */
	public function loadStream(path:String, complete:AudioLoadResult<AudioStream>->Void):IRequest {
		var child:IRequest = null,
			request:Request = null,
			abort:Null<Void->Void> = null;
		function finish(result:AudioLoadResult<AudioStream>) {
			if (request.finish()) {
				requests.remove(request);
				queue.add(() -> complete(result));
			} else
				switch result {
					case Ready(resource):
						resource.release();
					case _:
				}
		}
		request = new Request(() -> {
			if (child != null)
				child.cancel();
			if (abort != null)
				abort();
			requests.remove(request);
			queue.add(() -> complete(Cancelled));
		});
		requests.push(request);
		if (!live) {
			queue.add(() -> finish(Failed("Closed audio resource service")));
			return request;
		}
		child = assets.streamSource(path, result -> {
			if (request.isSettled()) {
				switch result {
					case Located(Stored(value)): value.release();
					case _:
				}
				return;
			}
			switch result {
				case Located(source):
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
								finish(Ready(resource));
							case Failed(message):
								release();
								finish(Failed(message));
						}
					});
				case Failed(message): finish(Failed(message));
				case Cancelled: finish(Cancelled);
			}
		});
		return request;
	}

	/** Starts resource from the beginning at volume 0 to 1, looping if asked; the playback holds the resource until it stops or finishes. While
		audio hasn't started (a browser before the page's first key or pointer press) the playback waits and starts once it runs; without an
		output, or with no free voice, it's finished at once. Throws for a closed service, a resource of another backend or already released by
		its owner, or a volume outside 0 to 1. */
	public function play(resource:AudioResource, loop = false, volume = 1.):AudioPlayback {
		if (!live || resource.getBackend() != backend)
			throw "Invalid audio resource service";
		if (!Math.isFinite(volume) || volume < 0 || volume > 1)
			throw "Invalid volume";
		resource.retainPlayback();
		var playback = try new AudioPlayback(resource, loop, volume) catch (error:Dynamic) {
			resource.releasePlayback();
			throw error;
		};
		if (!playback.isFinished())
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
					if (!resource.isDisposed() && Std.isOfType(resource, AudioClip) && (cast resource : AudioClip).getPath() == path) {
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
			if (!Lambda.exists(playbacks, p -> !p.isFinished() && p.getSource() == id)) {
				retired.remove(id);
				backend.destroyClip(id);
			}
		resources = [for (resource in resources) if (!resource.isDisposed()) resource];
		for (playback in playbacks.copy()) {
			playback.poll();
			if (playback.isFinished())
				playbacks.remove(playback);
		}
		queue.poll();
	}

	/** Cancels pending loads (each completes Cancelled), stops every playback, releases the owner's reference on every resource, destroys replaced clips, and refuses later loads and plays. */
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
