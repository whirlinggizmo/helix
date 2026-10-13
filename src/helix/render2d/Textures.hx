package helix.render2d;

import haxe.io.Bytes;
import helix.assets.IAssets;
import helix.assets.IReloadable;
import helix.assets.IRequest;
import helix.assets.Request;
import helix.graphics.IGraphics;
import helix.graphics.IImages;

/** How a texture load ended. */
enum TextureLoadResult {
	Ready(texture:Texture2D);
	Failed(message:String);
	Cancelled;
}

/** Textures from image files (PNG, JPEG, BMP, TGA, GIF): loaded through the assets, decoded off the frame, uploaded, and replaced in place when a
	file changes during development. The host's textures service; the caller destroys what it loads. */
class Textures implements IReloadable {
	var assets:IAssets;
	var images:IImages;
	var gpu:IGraphics;
	var live = true;
	var loaded:Array<{path:String, texture:Texture2D, linear:Bool}> = [];

	/** Loads through assets, decodes with images and uploads to gpu; poll polls images, and shutdown shuts nothing down but this service. */
	public function new(assets:IAssets, images:IImages, gpu:IGraphics) {
		this.assets = assets;
		this.images = images;
		this.gpu = gpu;
	}

	/** Loads path into a texture: linear filters it smoothly, with mipmaps so it can be drawn smaller without shimmering; otherwise nearest, for
		pixel art. complete runs exactly once on the host thread; Failed for a closed service, a load or decode failure. */
	public function load(path:String, linear:Bool, complete:TextureLoadResult->Void):IRequest {
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
		assets.load(path, result -> switch result {
			case Loaded(bytes):
				if (request.isSettled())
					return;
				child = images.decode(bytes, decoded -> switch decoded {
					case Decoded(width, height, rgba):
						if (!request.finish())
							return;
						var texture = Texture2D.fromRgba(gpu, width, height, rgba, linear, -1, -1, linear);
						loaded.push({path: path, texture: texture, linear: linear});
						assets.subscribe(path, this);
						complete(Ready(texture));
					case Failed(message):
						if (request.finish()) complete(Failed('$path: $message'));
					case Cancelled:
				});
			case Failed(message):
				if (request.finish()) complete(Failed('$path: $message'));
			case Cancelled:
		});
		return request;
	}

	/** Frees a texture this service loaded, and stops reloading it. */
	public function release(texture:Texture2D):Void {
		for (entry in loaded.copy())
			if (entry.texture == texture) {
				loaded.remove(entry);
				texture.destroy(gpu);
				if (!Lambda.exists(loaded, e -> e.path == entry.path))
					assets.unsubscribe(entry.path, this);
			}
	}

	/** The file behind loaded textures changed: they're decoded and uploaded again, keeping their Texture2D objects, so what draws them shows the
		new image. A file that no longer decodes leaves them as they were. */
	public function reloaded(path:String, bytes:Bytes):Void
		images.decode(bytes, decoded -> switch decoded {
			case Decoded(width, height, rgba):
				for (entry in loaded)
					if (entry.path == path)
						@:privateAccess entry.texture.replace(gpu, width, height, rgba, entry.linear);
			case _:
		});

	/** Delivers finished decodes; the host calls it once a frame. */
	public function poll():Void
		images.poll();

	/** Refuses new loads; the textures already loaded stay until released. */
	public function shutdown():Void
		live = false;
}
