package helix.graphics;

import haxe.io.Bytes;
import helix.assets.IExport;
import helix.graphics.IGraphics;

/** How a screenshot ended: where it was saved and its PNG file, or why it wasn't. */
enum ScreenshotResult {
	Saved(where:String, png:Bytes);
	Failed(message:String);
}

/** Screenshots, the same on every platform: the next frame the app ends is read back (IGraphics.readPixels), encoded as PNG (Png) and handed
	to the user (IExport: a download in a browser, a file natively). The Runner calls frameEnded after each of the app's frames. Encoding runs
	on the host thread, so the frame it's taken in is slower. */
class Screenshots {
	var graphics:IGraphics;
	var export:IExport;
	var prefix:String;
	var count = 0;
	var live = true;
	var pending:Array<{name:String, done:Null<ScreenshotResult->Void>}> = [];

	/** Reads frames from graphics and saves them through export, named prefix (the product's name, say) and the time. */
	public function new(graphics:IGraphics, export:IExport, prefix:String) {
		this.graphics = graphics;
		this.export = export;
		this.prefix = prefix;
	}

	/** Takes a screenshot of the next frame the app ends, saved as name (a plain file name ending .png; by default prefix, the date and time,
		and a count, as "asteroids-2026-10-14-153012-1.png"). done, when given, runs once on the host thread after that frame. Failed after
		shutdown. Throws for a name that isn't a plain .png file name. */
	public function take(?name:String, ?done:ScreenshotResult->Void):Void {
		if (name != null
			&& (!StringTools.endsWith(name, ".png") || name.indexOf("/") >= 0 || name.indexOf("\\") >= 0 || name.charAt(0) == "."))
			throw "Invalid screenshot name";
		if (!live) {
			if (done != null)
				done(Failed("Closed screenshots"));
			return;
		}
		count++;
		pending.push({name: name != null ? name : prefix + "-" + DateTools.format(Date.now(), "%Y-%m-%d-%H%M%S") + "-" + count + ".png", done: done});
	}

	/** After the app's frame: takes the screenshots asked for, from the frame it just ended. Nothing when none were asked for. */
	public function frameEnded():Void {
		if (pending.length == 0)
			return;
		var taking = pending;
		pending = [];
		graphics.readPixels(0, result -> switch result {
			case Read(width, height, rgba):
				var png = Png.encode(width, height, rgba);
				for (shot in taking)
					export.export(shot.name, "image/png", png, exported -> if (shot.done != null) shot.done(switch exported {
						case Exported(where): Saved(where, png);
						case Failed(message): Failed(message);
					}));
			case Failed(message):
				for (shot in taking)
					if (shot.done != null)
						shot.done(Failed(message));
		});
	}

	/** Fails what was asked for and refuses more. */
	public function shutdown():Void {
		live = false;
		var taking = pending;
		pending = [];
		for (shot in taking)
			if (shot.done != null)
				shot.done(Failed("Closed screenshots"));
	}
}
