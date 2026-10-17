package helix.render3d;

import helix.assets.IAssets;
import helix.assets.IRequest;
import helix.assets.Request;
import helix.render2d.TextureCache;
import helix.render3d.ModelFile.ImageSource;

/** How a model load ended. */
enum ModelLoadResult {
	Ready(file:ModelFile);
	Failed(message:String);
	Cancelled;
}

/** Model files (glTF 2.0, GLB or .gltf) loaded through the assets into ModelFiles: the file read with the buffers it keeps beside it, its images
	decoded or loaded into textures (base color sRGB, normal maps linear), then complete. All of it Haxe, the same on every target; images decode
	through a TextureCache. A file loads once and is shared: a path asked for again is the file already loaded (or its failure, remembered), and asking
	while it loads joins the load. Each caller instantiates its own copy of the file's nodes, so copies share meshes, materials and textures. The runner's is what the Models static forwards to. */
@:build(helix.macro.Facade.record())
class ModelCache {
	var assets:IAssets;
	var textures:TextureCache;
	var files:Map<String, ModelFile> = [];
	var failures:Map<String, String> = [];
	var waiting:Map<String, Array<{request:Request, complete:ModelLoadResult->Void}>> = [];
	var loads:Map<String, IRequest> = [];

	/** Loads through assets, decoding images with textures. */
	public function new(assets:IAssets, textures:TextureCache) {
		this.assets = assets;
		this.textures = textures;
	}

	/** Loads path (a .glb or .gltf) into a ModelFile: the file, then any buffers it keeps in files beside it, then its images (decoded from the
		file, or loaded from files beside it through the textures, which reload them when they change). complete runs exactly once: during this
		call when the file is loaded already (or failed before; forget clears a failure), else on the host thread when its load ends: Ready once its
		images are in (one that fails leaves its material untextured, with a warning), Failed for a load failure, a buffer that won't load, or a
		file it can't read, Cancelled when the request is (the shared load goes on for the others) or the service shuts down. */
	public function load(path:String, complete:ModelLoadResult->Void):IRequest {
		var settled = new Request(() -> {});
		if (files.exists(path)) {
			settled.finish();
			complete(Ready(files[path]));
			return settled;
		}
		if (failures.exists(path)) {
			settled.finish();
			complete(Failed(failures[path]));
			return settled;
		}
		var request:Request = null;
		request = new Request(() -> {
			var callers = waiting[path];
			if (callers != null)
				for (caller in callers.copy())
					if (caller.request == request)
						callers.remove(caller);
			complete(Cancelled);
		});
		if (waiting.exists(path)) {
			waiting[path].push({request: request, complete: complete});
			return request;
		}
		waiting[path] = [{request: request, complete: complete}];
		loads[path] = read(path, result -> {
			loads.remove(path);
			switch result {
				case Ready(file): files[path] = file;
				case Failed(message): failures[path] = message;
				case Cancelled:
			}
			var callers = waiting[path];
			waiting.remove(path);
			if (callers != null)
				for (caller in callers)
					if (caller.request.finish())
						caller.complete(result);
		});
		return request;
	}

	/** The file at path if it's loaded, else null. */
	public function find(path:String):Null<ModelFile>
		return files[path];

	/** Whether path is loaded. */
	public function isLoaded(path:String):Bool
		return files.exists(path);

	/** Whether path is loading. */
	public function isLoading(path:String):Bool
		return waiting.exists(path);

	/** How many files are loading. */
	public function getLoadingCount():Int {
		var n = 0;
		for (_ in waiting)
			n++;
		return n;
	}

	/** Adds a file loaded some other way under path, as if loaded from there (a test's, a generated one). */
	public function put(path:String, file:ModelFile):Void {
		files[path] = file;
		failures.remove(path);
	}

	/** Forgets path: its file (the copies instantiated from it stay) or its failure, so it's loaded again when next asked for. */
	public function forget(path:String):Void {
		files.remove(path);
		failures.remove(path);
	}

	/** Cancels every load (each caller waiting gets Cancelled) and forgets every file. */
	public function shutdown():Void {
		for (load in [for (l in loads) l])
			load.cancel();
		files.clear();
		failures.clear();
	}

	// One load of path, unshared: the file, its buffers, its images.
	function read(path:String, complete:ModelLoadResult->Void):IRequest {
		var children:Array<IRequest> = [], request:Request = null;
		request = new Request(() -> {
			for (child in children)
				child.cancel();
			complete(Cancelled);
		});
		function failed(message:String):Void
			if (request.finish())
				complete(Failed('$path: $message'));
		assets.load(path, result -> switch result {
			case Loaded(bytes):
				if (request.isSettled())
					return;
				var gltf = try Gltf.read(bytes) catch (e:Dynamic) {
					failed(Std.string(e));
					return;
				}
				var missing = gltf.getMissingBuffers(),
					waiting = missing.length;
				if (waiting == 0)
					build(path, gltf, request, children, complete);
				for (buffer in missing) {
					var file = Gltf.resolve(path, buffer.uri);
					if (file == null) {
						failed('buffer ${buffer.index}\'s uri ${buffer.uri} isn\'t a file beside the model');
						return;
					}
					assets.load(file, loaded -> switch loaded {
						case Loaded(data):
							if (request.isSettled())
								return;
							if (!gltf.setBuffer(buffer.index, data)) {
								failed('$file is shorter than buffer ${buffer.index}\'s byteLength');
								return;
							}
							if (--waiting == 0) build(path, gltf, request, children, complete);
						case Failed(message):
							failed('$file: $message');
						case Cancelled:
					});
				}
			case Failed(message):
				failed(message);
			case Cancelled:
		});
		return request;
	}

	// The file read, its buffers all in: the ModelFile, then its images.
	function build(path:String, gltf:Gltf, request:Request, children:Array<IRequest>, complete:ModelLoadResult->Void):Void {
		var file = try new ModelFile(gltf) catch (e:Dynamic) {
			if (request.finish())
				complete(Failed('$path: $e'));
			return;
		}
		var images = file.images(), waiting = images.length;
		if (waiting == 0) {
			if (request.finish())
				complete(Ready(file));
			return;
		}
		for (image in images) {
			function done(result:TextureLoadResult):Void {
				switch result {
					case Ready(texture):
						texture.setSampling(image.sampling);
						for (set in image.set)
							set(texture);
					case Failed(message):
						@:privateAccess file.warn('an image failed to load: $message');
					case Cancelled:
						return;
				}
				waiting--;
				if (waiting == 0 && request.finish())
					complete(Ready(file));
			}
			var linear = image.sampling.isLinear();
			switch image.source {
				case InView(view):
					children.push(textures.decode(gltf.viewBytes(view), linear, done));
				case Inline(bytes):
					children.push(textures.decode(bytes, linear, done));
				case File(uri):
					var resolved = Gltf.resolve(path, uri);
					if (resolved == null)
						done(Failed('its uri $uri isn\'t a file beside the model'));
					else
						children.push(textures.load(resolved, linear, done));
			}
		}
	}
}
