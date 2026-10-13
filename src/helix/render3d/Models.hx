package helix.render3d;

import helix.assets.IAssets;
import helix.assets.IRequest;
import helix.assets.Request;
import helix.render2d.Textures;

/** How a model load ended. */
enum ModelLoadResult {
	Ready(file:ModelFile);
	Failed(message:String);
	Cancelled;
}

/** Model files (glTF 2.0, as GLB) loaded through the assets into ModelFiles: the file read, its embedded images decoded into textures (base
	color sRGB, normal maps linear), then complete. All of it Haxe, the same on every target; images decode through Textures. */
class Models {
	var assets:IAssets;
	var textures:Textures;

	/** Loads through assets, decoding images with textures. */
	public function new(assets:IAssets, textures:Textures) {
		this.assets = assets;
		this.textures = textures;
	}

	/** Loads path (a .glb) into a ModelFile. complete runs exactly once on the host thread: Ready once its images are decoded (one that fails
		to decode leaves its material untextured, with a warning), Failed for a load failure or a file it can't read. */
	public function load(path:String, complete:ModelLoadResult->Void):IRequest {
		var children:Array<IRequest> = [], request:Request = null;
		request = new Request(() -> {
			for (child in children)
				child.cancel();
			complete(Cancelled);
		});
		assets.load(path, result -> switch result {
			case Loaded(bytes):
				if (request.isSettled())
					return;
				var file:ModelFile;
				try {
					file = new ModelFile(Gltf.readGlb(bytes));
				} catch (e:Dynamic) {
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
				for (image in images)
					children.push(textures.decode(file.gltfFile().viewBytes(image.view), image.linear, decoded -> {
						switch decoded {
							case Ready(texture):
								image.set(texture);
							case Failed(message):
								@:privateAccess file.warn('an image failed to decode: $message');
							case Cancelled:
								return;
						}
						waiting--;
						if (waiting == 0 && request.finish())
							complete(Ready(file));
					}));
			case Failed(message):
				if (request.finish()) complete(Failed('$path: $message'));
			case Cancelled:
		});
		return request;
	}
}
