import helix.app.IApp;
import helix.graphics.Screenshots;
import helix.input.Input;
import helix.input.Key;

/** The examples' development keys, around any example's app: F9 saves a screenshot of the frame (a download in a browser, a file in the
	user's pictures natively). Games choose their own keys; this is the examples' choice. */
class DevKeys implements IApp {
	var app:IApp;

	/** Keys for app. */
	public function new(app:IApp)
		this.app = app;

	public function init():Void
		app.init();

	public function frame(dt:Float):Void {
		if (Input.isFramePressed(Key.F9))
			Screenshots.take(null, result -> switch result {
				case Saved(where, _): trace('Screenshot saved: $where');
				case Failed(message): trace('Screenshot failed: $message');
			});
		app.frame(dt);
	}

	public function cleanup():Void
		app.cleanup();
}
