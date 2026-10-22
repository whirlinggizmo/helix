package helix.hotreload;

/** Routes the Runner's calls into an App across a hot reload: three lambdas, each calling a `@:hot` static function of the app's class by name
	(hotreload-hx's springboards), which helix.macro.AppBuild writes for every App subclass. Natively a reload re-points those statics at
	the new module and migrates the app object held in the class's `@:hot static`, so the Runner, compiled once into the executable,
	reaches the newest code and the migrated object without knowing either; in the browser every call reaches the new code anyway, and the
	lambdas cost nothing. */
@:noCompletion
class AppRouter {
	final initCall:Void->Void;
	final updateCall:Float->Void;
	final cleanupCall:Void->Void;

	/** The three calls: each a lambda calling the class's `@:hot` static by name, `() -> Game.hotInit()`, never the function passed as a
		value (a bound method keeps its old code). */
	public function new(init:Void->Void, update:Float->Void, cleanup:Void->Void) {
		initCall = init;
		updateCall = update;
		cleanupCall = cleanup;
	}

	/** The app's init (App.init), through its class's hot static. */
	public function init():Void
		initCall();

	/** The app's update (App.update), through its class's hot static. */
	public function update(dt:Float):Void
		updateCall(dt);

	/** The app's cleanup (App.cleanup), through its class's hot static. */
	public function cleanup():Void
		cleanupCall();
}
