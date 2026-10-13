package helix.app;

/** Empty defaults: an app overrides only the callbacks it uses. One that can't extend this implements IApp directly. */
class BaseApp implements IApp {
	/** An app with no callbacks of its own. */
	public function new() {}

	public function init():Void {}

	public function frame(dt:Float):Void {}

	public function cleanup():Void {}
}
