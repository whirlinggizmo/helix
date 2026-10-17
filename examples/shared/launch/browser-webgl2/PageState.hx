import helix.app.IApp;
import helix.host.Services;

/** Around an example's app in a browser: says on the page's window whether its services are still loading (window.helixBusy, from
	Services.isBusy) after each frame, and not once it has quit, for the tools that capture the page once it has settled (tools/pages_shots.cjs). */
class PageState implements IApp {
	var app:IApp;

	/** app, its loading told to the page. */
	public function new(app:IApp)
		this.app = app;

	public function init():Void
		app.init();

	public function frame(dt:Float):Void {
		app.frame(dt);
		Reflect.setField(js.Browser.window, "helixBusy", Services.isBusy());
	}

	// After a quit nothing loads (the shutdown cancelled it all), and no frame comes to say so.
	public function cleanup():Void {
		app.cleanup();
		Reflect.setField(js.Browser.window, "helixBusy", false);
	}
}
