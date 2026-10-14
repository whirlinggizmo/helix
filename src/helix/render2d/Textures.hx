package helix.render2d;

import haxe.io.Bytes;
import helix.assets.IAssets;
import helix.assets.IReloadable;
import helix.assets.IRequest;
import helix.assets.Request;
import helix.graphics.IGraphics;
import helix.graphics.ImageDecoding;
import helix.graphics.Sampling;
import helix.graphics.TextureFormat;

/** How a texture load ended. */
enum TextureLoadResult {
	Ready(texture:Texture2D);
	Failed(message:String);
	Cancelled;
}

/** Textures from image files (PNG, JPEG, BMP, TGA, GIF) and compressed ones (KTX 1: BC7, ASTC 4x4, ETC2 RGBA8): loaded through the assets,
	decoded off the frame, uploaded, and replaced in place when a file changes during development. A path "name.ktx" picks the file this GPU
	can sample: name.bc7.ktx, name.astc.ktx or name.etc2.ktx, the first it can and that loads, else name.png (made beforehand, each with its
	mipmaps, by a texture compressor; keep the PNG). The host's textures service; the caller releases what it loads. */
class Textures implements IReloadable {
	static var VARIANTS:Array<{suffix:String, format:TextureFormat}> = [
		{suffix: ".bc7.ktx", format: Bc7},
		{suffix: ".astc.ktx", format: Astc4x4},
		{suffix: ".etc2.ktx", format: Etc2Rgba8}
	];

	var assets:IAssets;
	var images:ImageDecoding;
	var gpu:IGraphics;
	var live = true;
	// Textures loaded: each the file it came from, what it was asked for by (the path and filter: loads of both alike share it), whether it
	// has mipmaps, and how many loads hold it.
	var loaded:Array<{
		path:String,
		key:String,
		texture:Texture2D,
		mipmaps:Bool,
		users:Int
	}> = [];
	// Loads under way, by what they were asked for: those waiting on each.
	var pending = new Map<String, {request:IRequest, waiting:Array<{request:Request, complete:TextureLoadResult->Void}>}>();

	/** Loads through assets, decodes with images (shared, polled by its owner) and uploads to gpu; shutdown shuts nothing down but this service. */
	public function new(assets:IAssets, images:ImageDecoding, gpu:IGraphics) {
		this.assets = assets;
		this.images = images;
		this.gpu = gpu;
	}

	/** The files path loads from, in order, the first that loads winning: a "name.ktx" this GPU's compressed variants then name.png; any other
		path itself. */
	public function getCandidates(path:String):Array<String> {
		if (!StringTools.endsWith(path, ".ktx"))
			return [path];
		for (variant in VARIANTS)
			if (StringTools.endsWith(path, variant.suffix))
				return [path];
		var base = path.substr(0, path.length - 4);
		return [
			for (variant in VARIANTS)
				if (gpu.canSample(variant.format)) base + variant.suffix
		].concat([base + ".png"]);
	}

	/** The file texture was loaded from (for a "name.ktx", the one chosen), or null for one this service didn't load. */
	public function getPath(texture:Texture2D):Null<String> {
		for (entry in loaded)
			if (entry.texture == texture)
				return entry.path;
		return null;
	}

	/** Loads path into a texture: linear samples it smoothly, with mipmaps so it can be drawn smaller without shimmering; otherwise nearest,
		for pixel art (Texture2D.setSampling changes it later). A "name.ktx" loads this GPU's variant or else name.png (getCandidates). Loads of the
		same path and filter share one texture (a load under way is joined, not started again), so its sampling is theirs together; each load
		releases it once (release), and the last frees it. complete runs exactly once on the host thread; Failed for a closed service, or when no
		candidate loads and decodes. */
	public function load(path:String, linear:Bool, complete:TextureLoadResult->Void):IRequest {
		var key = (linear ? "linear:" : "nearest:") + path, request:Request = null, waiter = null;
		request = new Request(() -> {
			// One load giving up: the shared one goes on while another still waits.
			var shared = pending[key];
			if (shared != null) {
				shared.waiting.remove(waiter);
				if (shared.waiting.length == 0) {
					pending.remove(key);
					shared.request.cancel();
				}
			}
			complete(Cancelled);
		});
		waiter = {request: request, complete: complete};
		if (!live) {
			request.finish();
			complete(Failed("Closed texture service"));
			return request;
		}
		for (entry in loaded)
			if (entry.key == key) {
				entry.users++;
				request.finish();
				complete(Ready(entry.texture));
				return request;
			}
		var shared = pending[key];
		if (shared != null) {
			shared.waiting.push(waiter);
			return request;
		}
		shared = {request: null, waiting: [waiter]};
		pending[key] = shared;
		shared.request = fetch(path, linear, (file, result) -> {
			if (pending[key] != shared)
				return;
			pending.remove(key);
			switch result {
				case Ready(texture):
					loaded.push({
						path: file,
						key: key,
						texture: texture,
						mipmaps: linear && texture.getFormat() == Rgba8,
						users: shared.waiting.length
					});
					assets.subscribe(file, this);
				case _:
			}
			for (w in shared.waiting)
				if (w.request.finish())
					w.complete(result);
		});
		return request;
	}

	// Loads path's first candidate that loads and decodes into a new texture; done gets the file it came from. Cancelled gives up silently.
	function fetch(path:String, linear:Bool, done:(String, TextureLoadResult) -> Void):IRequest {
		var child:IRequest = null, request:Request = null;
		request = new Request(() -> if (child != null) child.cancel());
		var candidates = getCandidates(path), errors = [];
		function next():Void {
			if (candidates.length == 0) {
				if (request.finish())
					done(path, Failed(errors.join("; ")));
				return;
			}
			var file = candidates.shift();
			function fail(message:String):Void {
				errors.push('$file: $message');
				next();
			}
			assets.load(file, result -> switch result {
				case Loaded(bytes):
					if (request.isSettled())
						return;
					if (StringTools.endsWith(file, ".ktx")) {
						var texture = try fromKtx(bytes, linear) catch (e:Dynamic) {
							fail(Std.string(e));
							return;
						}
						if (request.finish())
							done(file, Ready(texture));
						else
							texture.destroy(gpu);
						return;
					}
					child = images.decode(bytes, decoded -> switch decoded {
						case Decoded(width, height, rgba):
							if (request.finish()) done(file, Ready(Texture2D.fromRgba(gpu, width, height, rgba, linear, -1, -1, linear)));
						case Failed(message):
							if (!request.isSettled()) fail(message);
						case Cancelled:
					});
				case Failed(message):
					if (!request.isSettled()) fail(message);
				case Cancelled:
			});
		}
		next();
		return request;
	}

	function fromKtx(bytes:Bytes, linear:Bool):Texture2D {
		var ktx = Ktx.read(bytes);
		if (!gpu.canSample(ktx.format))
			throw "This GPU can't sample its format";
		return Texture2D.fromLevels(gpu, ktx.width, ktx.height, ktx.levels, ktx.format, new Sampling(linear));
	}

	/** Decodes encoded image bytes (a file's contents already in memory, such as a model's embedded image) into a texture, as load does but
		with nothing to reload: the caller owns the texture and destroys it. complete runs exactly once on the host thread. */
	public function decode(encoded:Bytes, linear:Bool, complete:TextureLoadResult->Void):IRequest {
		var child:IRequest = null, request:Request = null;
		request = new Request(() -> {
			if (child != null)
				child.cancel();
			complete(Cancelled);
		});
		if (!live) {
			request.finish();
			complete(Failed("Closed texture service"));
			return request;
		}
		child = images.decode(encoded, decoded -> switch decoded {
			case Decoded(width, height, rgba):
				if (request.finish()) complete(Ready(Texture2D.fromRgba(gpu, width, height, rgba, linear, -1, -1, linear)));
			case Failed(message):
				if (request.finish()) complete(Failed(message));
			case Cancelled:
		});
		return request;
	}

	/** Lets go of a texture this service loaded, once for each load that gave it: the last release frees it and stops reloading it. */
	public function release(texture:Texture2D):Void
		for (entry in loaded.copy())
			if (entry.texture == texture) {
				if (--entry.users > 0)
					return;
				loaded.remove(entry);
				texture.destroy(gpu);
				if (!Lambda.exists(loaded, e -> e.path == entry.path))
					assets.unsubscribe(entry.path, this);
				return;
			}

	/** The file behind loaded textures changed: they're read and uploaded again, keeping their Texture2D objects and sampling, so what draws them
		shows the new image. A file that no longer reads leaves them as they were. */
	public function reloaded(path:String, bytes:Bytes):Void {
		if (StringTools.endsWith(path, ".ktx")) {
			var ktx = try Ktx.read(bytes) catch (e:Dynamic) return;
			if (!gpu.canSample(ktx.format))
				return;
			for (entry in loaded)
				if (entry.path == path)
					@:privateAccess entry.texture.replace(gpu, ktx.width, ktx.height, ktx.levels, ktx.format);
			return;
		}
		images.decode(bytes, decoded -> switch decoded {
			case Decoded(width, height, rgba):
				for (entry in loaded)
					if (entry.path == path)
						@:privateAccess entry.texture.replace(gpu, width, height, entry.mipmaps ? helix.graphics.Mipmaps.build(width, height, rgba) : [rgba],
							Rgba8);
			case _:
		});
	}

	/** Refuses new loads; the textures already loaded stay until released. */
	public function shutdown():Void
		live = false;
}
