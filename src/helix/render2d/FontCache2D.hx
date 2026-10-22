package helix.render2d;

import haxe.io.Bytes;
import helix.assets.Failure;
import helix.assets.IAssets;
import helix.assets.IReloadable;
import helix.assets.IRequest;
import helix.assets.Request;
import helix.graphics.IGraphics;

/** TrueType fonts loaded through the assets into Font2Ds: read and baked into a distance-field texture in Haxe (Font2D.fromTrueType), the same
	on every target, and baked again in place when a file changes during development. The runner's is what the Fonts2D static forwards to;
	the caller releases what it loads. */
@:build(helix.macro.Facade.record())
class FontCache2D implements IReloadable {
	var assets:IAssets;
	var gpu:IGraphics;
	var entries:Array<{path:String, font:Font2D}> = [];
	var live = true;

	/** Loads through assets and uploads to gpu; shutdown shuts nothing down but this service. */
	public function new(assets:IAssets, gpu:IGraphics) {
		this.assets = assets;
		this.gpu = gpu;
	}

	/** Loads path (a .ttf) into a font. One of loaded or failed runs once on the host thread, and neither once the request is cancelled: loaded
		once it is baked; failed (else the log, with the path) for a load failure or a file it can't read. */
	public function load(path:String, loaded:Font2D->Void, ?failed:String->Void):IRequest {
		var loading:IRequest = null, request:Request = null;
		request = new Request(() -> if (loading != null) loading.cancel());
		loading = assets.load(path, bytes -> {
			if (request.settled || !live)
				return;
			var font = try Font2D.fromTrueType(bytes, gpu) catch (e:Dynamic) {
				if (request.finish())
					Failure.report(path, '$path: $e', failed);
				return;
			}
			if (!request.finish()) {
				font.destroy(gpu);
				return;
			}
			entries.push({path: path, font: font});
			assets.subscribe(path, this);
			loaded(font);
		},
			message -> if (request.finish()) Failure.report(path, Failure.named(path, message), failed));
		return request;
	}

	/** The file font was loaded from, or null for one this service didn't load. */
	public function getPath(font:Font2D):Null<String> {
		for (entry in entries)
			if (entry.font == font)
				return entry.path;
		return null;
	}

	/** Frees a font this service loaded, and stops reloading it. */
	public function release(font:Font2D):Void
		for (entry in entries.copy())
			if (entry.font == font) {
				entries.remove(entry);
				font.destroy(gpu);
				if (!Lambda.exists(entries, e -> e.path == entry.path))
					assets.unsubscribe(entry.path, this);
			}

	/** The file behind loaded fonts changed: they're baked again in place, keeping their Font2D objects. A file that no longer reads leaves them
		as they were. */
	public function reloaded(path:String, bytes:Bytes):Void
		for (entry in entries)
			if (entry.path == path)
				try
					entry.font.replaceTrueType(gpu, bytes)
				catch (e:Dynamic) {}

	/** Frees every font still loaded and takes no more loads: a load that lands after calls nothing. The runner's, at the program's end. */
	public function shutdown():Void {
		live = false;
		for (entry in entries) {
			entry.font.destroy(gpu);
			assets.unsubscribe(entry.path, this);
		}
		entries = [];
	}
}
