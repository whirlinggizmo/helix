package helix.services.screenshots;

import helix.log.Log;
import helix.platform.IGraphics;
import helix.services.images.Image;

/** Captures frames as images: the next frame that ends is read back from the GPU, for a screenshot or a check.

	The program constructs one over its `IGraphics`, and calls `frameEnded` once a frame, between `IGraphics.endFrame` and `present`.
	A capture waits for the GPU, so the frame it's taken in is slower.

	```haxe
	var screenshots = new Screenshots(graphics);
	screenshots.captureFrame(image -> export.export("shot.png", "image/png", PngFile.write(image.width, image.height, 4, image.pixels), _ -> {},
		_ -> {}));
	// each frame:
	graphics.endFrame();
	screenshots.frameEnded();
	graphics.present();
	``` */
class Screenshots {
	final graphics:IGraphics;
	// The captures asked for since the last frame ended.
	var pending:Array<{captured:Image->Void, failed:Null<String->Void>}> = [];

	/** Creates the screenshots over the graphics whose frames they read.

		@param graphics  The graphics. */
	public function new(graphics:IGraphics) {
		this.graphics = graphics;
	}

	/** Captures the next frame that ends as an image, the size of the framebuffer.

		One of `captured` or `failed` is called once, as that frame ends or later, never during this call.
		@param captured  Receives the image.
		@param failed  Optional. Receives why the frame couldn't be read. When omitted, the failure is logged. */
	public function captureFrame(captured:Image->Void, ?failed:String->Void):Void {
		pending.push({captured: captured, failed: failed});
	}

	/** Reads the frame that just ended for the captures asked for. Call it once a frame, between `IGraphics.endFrame` and `present`. */
	public function frameEnded():Void {
		if (pending.length == 0)
			return;
		var captures = pending;
		pending = [];
		graphics.readPixels(0, (pixels, width, height) -> {
			for (i in 0...captures.length)
				// Each capture gets pixels of its own, as an image's pixels can be changed in place.
				captures[i].captured(new Image("", width, height, i == captures.length - 1 ? pixels : pixels.sub(0, pixels.length)));
		}, message -> {
			for (capture in captures)
				if (capture.failed != null)
					capture.failed(message);
				else
					Log.warn('Screenshot failed: $message', "screenshots");
		});
	}
}
