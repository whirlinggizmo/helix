import helix.app.IApp;
import helix.host.Services;
import helix.input.Key;

/** The examples' development keys, around any example's app: F9 saves a screenshot of the frame (a download in a browser, a file in the
	user's pictures natively). Games choose their own keys; this is the examples' choice. */
class DevKeys implements IApp {
	var services:Services;
	var app:IApp;

	/** Keys for app, read from services' input. */
	public function new(services:Services, app:IApp) {
		this.services = services;
		this.app = app;
	}

	public function init():Void
		app.init();

	public function frame(dt:Float):Void {
		if (services.input.isFramePressed(Key.F9))
			services.screenshots.take(null, result -> switch result {
				case Saved(where, _): trace('Screenshot saved: $where');
				case Failed(message): trace('Screenshot failed: $message');
			});
		app.frame(dt);
	}

	public function cleanup():Void
		app.cleanup();
}
