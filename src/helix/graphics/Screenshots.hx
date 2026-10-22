package helix.graphics;

/** Screenshots of the frame, saved for the user (a download in a browser, a file natively; ScreenshotService). The program's one, a static class: each
	member forwards to instance, written by helix.macro.Facade from ScreenshotService's public members with their doc comments. */
@:build(helix.macro.Facade.build(helix.graphics.ScreenshotService, ["frameEnded", "shutdown"]))
class Screenshots {
	/** The screenshots forwarded to: the runner's from its init to its cleanup, null outside them. Kept across a hot reload (@:hot): set once by the runner, nothing would set it again. */
	@:hot @:allow(helix) static var instance(default, null):ScreenshotService;
}
