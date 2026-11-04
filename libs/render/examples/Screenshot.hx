import helix.platform.IGraphics;
import helix.platform.ISystem;

/** Saves an example's last frame as a PNG when it is run natively with `--screenshot=<file>`, so tools/render_checks.py checks a native
	run's pixels against its check.json as it checks the page's. In a page the browser takes the screenshot, so it does nothing there. */
class Screenshot {
	/** Saves the frame `endFrame` just ended to the file the `screenshot` option names, or does nothing without the option. It is called
		between `endFrame` and `present`.

		@param graphics  The graphics adapter the frame was drawn with.
		@param system  The system adapter, whose `screenshot` option names the file. */
	public static function save(graphics:IGraphics, system:ISystem):Void {
		#if sys
		var file = system.getOption("screenshot");
		if (file != null)
			graphics.readPixels(0, (pixels, width, height) -> sys.io.File.saveBytes(file, helix.formats.png.PngFile.write(width, height, 4, pixels)),
				why -> throw 'screenshot: $why');
		#end
	}
}
