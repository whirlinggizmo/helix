package helix.graphics;

import haxe.io.Bytes;
import helix.assets.IAssets;
import helix.assets.IReloadable;
import helix.assets.IRequest;
import helix.assets.Request;

/** How a shader load ended. */
enum ShaderLoadResult {
	Ready(shader:Shader);
	Failed(message:String);
	Cancelled;
}

/** Apps' shaders (.hxshader files, packed from GLSL by tools/pack_shader.py) loaded through the assets and built on the GPU, and built again in
	place when a file changes during development. The caller releases what it loads. */
class Shaders implements IReloadable {
	var assets:IAssets;
	var gpu:IGraphics;
	var loaded:Array<{path:String, shader:Shader}> = [];

	/** Loads through assets and builds on gpu. */
	public function new(assets:IAssets, gpu:IGraphics) {
		this.assets = assets;
		this.gpu = gpu;
	}

	/** Loads path (a .hxshader) into a shader. complete runs exactly once on the host thread: Ready once its program is built, Failed for a load
		failure, a file it can't read or a program that doesn't build (with the compiler's log). */
	public function load(path:String, complete:ShaderLoadResult->Void):IRequest {
		var request:Request = null;
		request = new Request(() -> complete(Cancelled));
		assets.load(path, result -> switch result {
			case Loaded(bytes):
				if (request.settled)
					return;
				var shader = try Shader.fromText(gpu, bytes.toString()) catch (e:Dynamic) {
					if (request.finish())
						complete(Failed('$path: $e'));
					return;
				}
				if (!request.finish()) {
					shader.destroy();
					return;
				}
				loaded.push({path: path, shader: shader});
				assets.subscribe(path, this);
				complete(Ready(shader));
			case Failed(message):
				if (request.finish()) complete(Failed('$path: $message'));
			case Cancelled:
		});
		return request;
	}

	/** Frees a shader this service loaded (after the pipelines made with it), and stops reloading it. */
	public function release(shader:Shader):Void
		for (entry in loaded.copy())
			if (entry.shader == shader) {
				loaded.remove(entry);
				shader.destroy();
				if (!Lambda.exists(loaded, e -> e.path == entry.path))
					assets.unsubscribe(entry.path, this);
			}

	/** The file behind loaded shaders changed: they're built again in place. One that no longer builds stays as it was, its log traced. */
	public function reloaded(path:String, bytes:Bytes):Void
		for (entry in loaded)
			if (entry.path == path)
				try
					@:privateAccess entry.shader.replace(bytes.toString())
				catch (e:Dynamic)
					trace('$path: $e');
}
