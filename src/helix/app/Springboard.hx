package helix.app;

/** The Runner's way into an App across a hot reload: three lambdas, each calling a `@:hot` static function of the app's class by name
	(hotreload-hx's springboards), which helix.macro.AppBuild writes for every App subclass. Natively a reload re-points those statics at
	the new module and migrates the app object held in the class's `@:hot static`, so the Runner, compiled once into the executable,
	reaches the newest code and the migrated object without knowing either; in the browser every call reaches the new code anyway, and the
	lambdas cost nothing. */
class Springboard implements IApp {
	final initCall:Void->Void;
	final frameCall:Float->Void;
	final cleanupCall:Void->Void;

	/** The three calls: each a lambda calling the class's `@:hot` static by name, `() -> Game.hotInit()`, never the function passed as a
		value (a bound method keeps its old code). */
	public function new(init:Void->Void, frame:Float->Void, cleanup:Void->Void) {
		initCall = init;
		frameCall = frame;
		cleanupCall = cleanup;
	}

	public function init():Void
		initCall();

	public function frame(dt:Float):Void
		frameCall(dt);

	public function cleanup():Void
		cleanupCall();
}
