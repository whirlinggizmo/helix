package helix.render3d;

import haxe.io.Bytes;
import helix.assets.IAssets;
import helix.assets.IReloadable;
import helix.assets.IRequest;
import helix.assets.Request;
import helix.graphics.IGraphics;
import helix.graphics.ImageDecoding;

/** How an environment load ended. */
enum EnvironmentLoadResult {
	Ready(environment:Environment);
	Failed(message:String);
	Cancelled;
}

/** Environment maps from equirectangular images (2:1, latitude-longitude): a Radiance .hdr (true high dynamic range, recommended) or a PNG or
	JPEG (sRGB, low dynamic range). Loaded through the assets, prepared on the CPU a step at a time within a budget each frame (poll), one at a
	time, so a load spreads over frames rather than stalling one (a 1K image takes a few hundred milliseconds of steps natively), uploaded, and
	prepared again and replaced in place when a file changes during development. The host's environments service; the caller releases what it
	loads. Needs a GPU that filters half floats (IGraphics.canSample(Rgba16f)); every HeliX target's does. */
class Environments implements IReloadable {
	var assets:IAssets;
	var images:ImageDecoding;
	var gpu:IGraphics;
	var live = true;
	var budgetMs = 4.;
	// Environments loaded: each with how many loads hold it.
	var loaded:Array<{environment:Environment, users:Int}> = [];
	// Loads under way, by path: those waiting on each, and its bake once its file is read.
	var pending = new Map<String, Pending>();
	// Bakes waiting their turn, the first running: each its path and what to do when it's done or fails.
	var queue:Array<{path:String, bake:EnvironmentBake, done:Null<String>->Void}> = [];

	/** Loads through assets, decodes 8-bit images with images and uploads to gpu. */
	public function new(assets:IAssets, images:ImageDecoding, gpu:IGraphics) {
		this.assets = assets;
		this.images = images;
		this.gpu = gpu;
	}

	/** The milliseconds of preparation poll does a frame: 4 to start. A loading screen might raise it. */
	public function getBudgetMs():Float
		return budgetMs;

	/** False for a budget of 0 or less. */
	public function setBudgetMs(value:Float):Bool {
		if (!(value > 0))
			return false;
		budgetMs = value;
		return true;
	}

	/** Whether anything is still loading or being prepared. */
	public function isBusy():Bool
		return pending.iterator().hasNext() || queue.length > 0;

	/** Loads path into an environment. Loads of the same path share one (a load under way is joined); each load releases it once (release),
		and the last frees it. complete runs exactly once on the host thread: Failed for a closed service, a file that won't load or isn't an
		image, or a GPU without filtered half floats. */
	public function load(path:String, complete:EnvironmentLoadResult->Void):IRequest {
		var request:Request = null, waiter = null;
		request = new Request(() -> {
			var shared = pending[path];
			if (shared != null) {
				shared.waiting.remove(waiter);
				if (shared.waiting.length == 0)
					abandon(path, shared);
			}
			complete(Cancelled);
		});
		waiter = {request: request, complete: complete};
		if (!live || !gpu.canSample(Rgba16f)) {
			request.finish();
			complete(Failed(live ? "This GPU doesn't filter half floats" : "Closed environment service"));
			return request;
		}
		for (entry in loaded)
			if (entry.environment.getPath() == path) {
				entry.users++;
				request.finish();
				complete(Ready(entry.environment));
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
			var result = if (error != null) Failed(error) else {
				var made = try Ready(Environment.fromBake(gpu, path, bake)) catch (e:Dynamic) Failed(Std.string(e));
				switch made {
					case Ready(environment):
						loaded.push({environment: environment, users: shared.waiting.length});
						assets.subscribe(path, this);
					case _:
				}
				made;
			}
			for (w in shared.waiting)
				if (w.request.finish())
					w.complete(result);
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
	function prepare(path:String, done:(Null<EnvironmentBake>, Null<String>) -> Void):IRequest {
		var child:IRequest = null, request:Request = null, entry = null;
		request = new Request(() -> {
			if (child != null)
				child.cancel();
			queue.remove(entry);
		});
		function bake(made:EnvironmentBake):Void {
			entry = {
				path: path,
				bake: made,
				done: error -> if (request.finish()) done(error == null ? made : null, error)
			};
			queue.push(entry);
		}
		assets.load(path, result -> switch result {
			case Loaded(bytes):
				if (request.isSettled())
					return;
				if (Hdr.isHdr(bytes)) {
					bake(EnvironmentBake.fromHdr(bytes));
					return;
				}
				child = images.decode(bytes, decoded -> switch decoded {
					case Decoded(width, height, rgba):
						if (!request.isSettled()) bake(EnvironmentBake.fromRgba(width, height, rgba));
					case Failed(message):
						if (request.finish()) done(null, '$path: $message');
					case Cancelled:
				});
			case Failed(message):
				if (request.finish()) done(null, '$path: $message');
			case Cancelled:
		});
		return request;
	}

	/** Lets go of an environment this service loaded, once for each load that gave it: the last release frees it and stops reloading it. */
	public function release(environment:Environment):Void
		for (entry in loaded)
			if (entry.environment == environment) {
				if (--entry.users > 0)
					return;
				loaded.remove(entry);
				environment.destroy(gpu);
				assets.unsubscribe(environment.getPath(), this);
				return;
			}

	/** The file behind a loaded environment changed: it's prepared again and its cubes replaced, keeping its Environment object, so the stages
		using it show the new one once that's done. A file that no longer reads leaves it as it was. */
	public function reloaded(path:String, bytes:Bytes):Void {
		function replace(bake:EnvironmentBake):Void
			queue.push({
				path: path,
				bake: bake,
				done: error -> if (error == null) for (entry in loaded)
					if (entry.environment.getPath() == path)
						try
							@:privateAccess entry.environment.replace(gpu, bake)
						catch (e:Dynamic) {}
			});
		if (Hdr.isHdr(bytes)) {
			replace(EnvironmentBake.fromHdr(bytes));
			return;
		}
		images.decode(bytes, decoded -> switch decoded {
			case Decoded(width, height, rgba):
				replace(EnvironmentBake.fromRgba(width, height, rgba));
			case _:
		});
	}

	/** Prepares the bake at the head of the queue for up to the budget, finishing it when it's done; the host calls it once a frame. */
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
	public var waiting:Array<{request:Request, complete:EnvironmentLoadResult->Void}> = [];

	/** Reading and preparing its file. */
	public var request:IRequest;

	/** Nothing waiting yet. */
	public function new() {}
}
