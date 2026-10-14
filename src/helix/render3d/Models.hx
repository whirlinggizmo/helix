package helix.render3d;

import helix.assets.IAssets;
import helix.assets.IRequest;
import helix.assets.Request;
import helix.render2d.Textures;
import helix.render3d.ModelFile.ImageSource;

/** How a model load ended. */
enum ModelLoadResult {
	Ready(file:ModelFile);
	Failed(message:String);
	Cancelled;
}

/** Model files (glTF 2.0, GLB or .gltf) loaded through the assets into ModelFiles: the file read with the buffers it keeps beside it, its images
	decoded or loaded into textures (base color sRGB, normal maps linear), then complete. All of it Haxe, the same on every target; images decode through Textures. */
class Models {
	var assets:IAssets;
	var textures:Textures;

	/** Loads through assets, decoding images with textures. */
	public function new(assets:IAssets, textures:Textures) {
		this.assets = assets;
		this.textures = textures;
	}

	/** Loads path (a .glb or .gltf) into a ModelFile: the file, then any buffers it keeps in files beside it, then its images (decoded from the
		file, or loaded from files beside it through the textures, which reload them when they change). complete runs exactly once on the host
		thread: Ready once its images are in (one that fails leaves its material untextured, with a warning), Failed for a load failure, a buffer
		that won't load, or a file it can't read. */
	public function load(path:String, complete:ModelLoadResult->Void):IRequest {
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
							try
								gltf.setBuffer(buffer.index, data)
							catch (e:Dynamic) {
								failed(Std.string(e));
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
