package helix.render3d;

import haxe.io.Bytes;
import helix.assets.Failure;
import helix.assets.IAssets;
import helix.assets.IReloadable;
import helix.assets.IRequest;
import helix.assets.Request;
import helix.graphics.IGraphics;
import helix.graphics.ImageDecoding;

/** Environment maps from equirectangular images (2:1, latitude-longitude): a Radiance .hdr (true high dynamic range, recommended) or a PNG or
	JPEG (sRGB, low dynamic range). Loaded through the assets, prepared on the CPU a step at a time within a budget each frame (poll), one at a
	time, so a load spreads over frames rather than stalling one (a 1K image takes a few hundred milliseconds of steps natively), uploaded, and
	prepared again and replaced in place when a file changes during development. The runner's is what the Environments3D static forwards to; the caller releases what it
	loads. Needs a GPU that filters half floats (IGraphics.canSample(Rgba16f)); every HeliX target's does. */
@:build(helix.macro.Facade.record())
class EnvironmentCache3D implements IReloadable {
	var assets:IAssets;
	var images:ImageDecoding;
	var gpu:IGraphics;
	var live = true;
	// Environments loaded: each with how many loads hold it.
	var entries:Array<{environment:EnvironmentMap3D, users:Int}> = [];
	// Loads under way, by path: those waiting on each, and its bake once its file is read.
	var pending = new Map<String, Pending>();
	// Bakes waiting their turn, the first running: each its path and what to do when it's done or fails.
	var queue:Array<{path:String, bake:EnvironmentBake3D, done:Null<String>->Void}> = [];

	// The program's environments, an optional part (helix.host.Part): built over the runner's assets, image decoder and GPU, polled each
	// frame, closed at the end; Environments3D installs it at its first use, so a program with no environment carries none of this.

	@:allow(helix.render3d.Environments3D)
	static function install():EnvironmentCache3D {
		return helix.host.Host.installPart(runner -> {
			var cache = new EnvironmentCache3D(runner.assets, runner.images, runner.platform.graphics);
			runner.install({
				poll: cache.poll,
				busy: () -> cache.busy,
				shutdown: () -> {
					cache.shutdown();
					Environments3D.bind(null);
				}
			});
			cache;
		});
	}

	/** Loads through assets, decodes 8-bit images with images and uploads to gpu. */
	public function new(assets:IAssets, images:ImageDecoding, gpu:IGraphics) {
		this.assets = assets;
		this.images = images;
		this.gpu = gpu;
	}

	/** The milliseconds of preparation poll does a frame: 4 to start. A loading screen might raise it. At least 1e-6 (0 or less, or NaN, is 1e-6). */
	@:isVar public var budgetMs(get, set):Float = 4.;

	function get_budgetMs():Float
		return budgetMs;

	function set_budgetMs(value:Float):Float {
		value = value > 1e-6 ? value : 1e-6;
		budgetMs = value;
		return value;
	}

	/** Whether anything is still loading or being prepared. */
	public var busy(get, never):Bool;

	function get_busy():Bool
		return pending.iterator().hasNext() || queue.length > 0;

	/** Loads path into an environment. Loads of the same path share one (a load under way is joined); each load releases it once (release),
		and the last frees it. One of loaded or failed runs once on the host thread, and neither once the request is cancelled; failed (else the
		log, with the path) for a closed service, a file that won't load or isn't an image, or a GPU without filtered half floats. */
	public function load(path:String, loaded:EnvironmentMap3D->Void, ?failed:String->Void):IRequest {
		var request:Request = null, waiter = null;
		request = new Request(() -> {
			var shared = pending[path];
			if (shared != null) {
				shared.waiting.remove(waiter);
				if (shared.waiting.length == 0)
					abandon(path, shared);
			}
		});
		waiter = {request: request, loaded: loaded, failed: failed};
		if (!live || !gpu.canSample(Rgba16f)) {
			request.finish();
			Failure.report(path, live ? "This GPU doesn't filter half floats" : "Closed environment service", failed);
			return request;
		}
		for (entry in entries)
			if (entry.environment.path == path) {
				entry.users++;
				request.finish();
				loaded(entry.environment);
				return request;
			}
		var shared = pending[path];
		if (shared != null) {
			shared.waiting.push(waiter);
			return request;
		}
		shared = new Pending();
		shared.waiting.push(waiter);
		pending[path] = shared;
		shared.request = prepare(path, (bake, error) -> {
			if (pending[path] != shared)
				return;
			pending.remove(path);
			var environment = null;
			if (error == null) {
				environment = try EnvironmentMap3D.fromBake(gpu, path, bake) catch (e:Dynamic) {
					error = Std.string(e);
					null;
				}
				if (environment != null) {
					entries.push({environment: environment, users: shared.waiting.length});
					assets.subscribe(path, this);
				}
			}
			for (w in shared.waiting)
				if (w.request.finish())
					if (environment != null)
						w.loaded(environment);
					else
						Failure.report(path, error, w.failed);
		});
		return request;
	}

	// The last waiter gave up: its file's load stops, or its bake leaves the queue.
	function abandon(path:String, shared:Pending):Void {
		pending.remove(path);
		if (shared.request != null)
			shared.request.cancel();
	}

	// Reads path and queues its bake; done gets the finished bake, or why there's none. Cancelling it stops its decode or its bake (a file's read
	// runs on, ignored).
	function prepare(path:String, done:(Null<EnvironmentBake3D>, Null<String>) -> Void):IRequest {
		var child:IRequest = null, request:Request = null, entry = null;
		request = new Request(() -> {
			if (child != null)
				child.cancel();
			queue.remove(entry);
		});
		function bake(made:EnvironmentBake3D):Void {
			entry = {
				path: path,
				bake: made,
				done: error -> if (request.finish()) done(error == null ? made : null, error)
			};
			queue.push(entry);
		}
		var loading = assets.load(path, bytes -> {
			if (request.settled)
				return;
			if (Hdr.isHdr(bytes)) {
				bake(EnvironmentBake3D.fromHdr(bytes));
				return;
			}
			child = images.decode(bytes, decoded -> switch decoded {
				case Decoded(width, height, rgba):
					if (!request.settled) bake(EnvironmentBake3D.fromRgba(width, height, rgba));
				case Failed(message):
					if (request.finish()) done(null, '$path: $message');
				case Cancelled:
			});
		}, message -> if (request.finish()) done(null, '$path: $message'));
		if (child == null)
			child = loading;
		return request;
	}

	/** Lets go of an environment this service loaded, once for each load that gave it: the last release frees it and stops reloading it. */
	public function release(environment:EnvironmentMap3D):Void
		for (entry in entries)
			if (entry.environment == environment) {
				if (--entry.users > 0)
					return;
				entries.remove(entry);
				environment.destroy(gpu);
				assets.unsubscribe(environment.path, this);
				return;
			}

	/** The file behind a loaded environment changed: it's prepared again and its cubes replaced, keeping its EnvironmentMap3D object, so the stages
		using it show the new one once that's done. A file that no longer reads leaves it as it was. */
	public function reloaded(path:String, bytes:Bytes):Void {
		function replace(bake:EnvironmentBake3D):Void
			queue.push({
				path: path,
				bake: bake,
				done: error -> if (error == null) for (entry in entries)
					if (entry.environment.path == path)
						try
							@:privateAccess entry.environment.replace(gpu, bake)
						catch (e:Dynamic) {}
			});
		if (Hdr.isHdr(bytes)) {
			replace(EnvironmentBake3D.fromHdr(bytes));
			return;
		}
		images.decode(bytes, decoded -> switch decoded {
			case Decoded(width, height, rgba):
				replace(EnvironmentBake3D.fromRgba(width, height, rgba));
			case _:
		});
	}

	/** Prepares the bake at the head of the queue for up to the budget, finishing it when it's done; the Runner calls it once a frame. */
	public function poll():Void {
		if (queue.length == 0)
			return;
		var head = queue[0];
		var finished = try head.bake.run(budgetMs) catch (e:Dynamic) {
			queue.shift();
			head.done('${head.path}: ${Std.string(e)}');
			return;
		};
		if (finished) {
			queue.shift();
			head.done(null);
		}
	}

	/** Refuses new loads and drops the bakes under way; the environments already loaded stay until released. */
	public function shutdown():Void {
		live = false;
		queue = [];
	}
}

/** A load under way: those waiting on it, and the request reading and preparing its file. */
private class Pending {
	/** The loads waiting for it. */
	public var waiting:Array<{request:Request, loaded:EnvironmentMap3D->Void, failed:Null<String->Void>}> = [];

	/** Reading and preparing its file. */
	public var request:IRequest;

	/** Nothing waiting yet. */
	public function new() {}
}
