package helix.render2d;

import haxe.io.Bytes;
import helix.assets.IAssets;
import helix.assets.IReloadable;
import helix.assets.IRequest;
import helix.assets.Request;
import helix.graphics.IGraphics;

/** How a font load ended. */
enum FontLoadResult {
	Ready(font:Font2D);
	Failed(message:String);
	Cancelled;
}

/** TrueType fonts loaded through the assets into Font2Ds: read and baked into a distance-field texture in Haxe (Font2D.fromTrueType), the same
	on every target, and baked again in place when a file changes during development. The caller releases what it loads. */
class Fonts implements IReloadable {
	var assets:IAssets;
	var gpu:IGraphics;
	var loaded:Array<{path:String, font:Font2D}> = [];

	/** Loads through assets and uploads to gpu. */
	public function new(assets:IAssets, gpu:IGraphics) {
		this.assets = assets;
		this.gpu = gpu;
	}

	/** Loads path (a .ttf) into a font. complete runs exactly once on the host thread: Ready once it is baked, Failed for a load failure or a
		file it can't read. */
	public function load(path:String, complete:FontLoadResult->Void):IRequest {
		var request:Request = null;
		request = new Request(() -> complete(Cancelled));
		assets.load(path, result -> switch result {
			case Loaded(bytes):
				if (request.settled)
					return;
				var font = try Font2D.fromTrueType(gpu, bytes) catch (e:Dynamic) {
					if (request.finish())
						complete(Failed('$path: $e'));
					return;
				}
				if (!request.finish()) {
					font.destroy(gpu);
					return;
				}
				loaded.push({path: path, font: font});
				assets.subscribe(path, this);
				complete(Ready(font));
			case Failed(message):
				if (request.finish()) complete(Failed('$path: $message'));
			case Cancelled:
		});
		return request;
	}

	/** Frees a font this service loaded, and stops reloading it. */
	public function release(font:Font2D):Void
		for (entry in loaded.copy())
			if (entry.font == font) {
				loaded.remove(entry);
				font.destroy(gpu);
				if (!Lambda.exists(loaded, e -> e.path == entry.path))
					assets.unsubscribe(entry.path, this);
			}

	/** The file behind loaded fonts changed: they're baked again in place, keeping their Font2D objects. A file that no longer reads leaves them
		as they were. */
	public function reloaded(path:String, bytes:Bytes):Void
		for (entry in loaded)
			if (entry.path == path)
				try
					entry.font.replaceTrueType(gpu, bytes)
				catch (e:Dynamic) {}
}
