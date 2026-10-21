import helix.app.AppOptions;
import helix.app.Springboard;
import helix.macro.AppBuild;

/** A game as a user writes one: helix.App's build (helix.macro.AppBuild) writes its springboards into it. Never constructed here, since
	the constructor would start the backend's profile; made empty instead. */
class Game extends helix.App {
	public var inits = 0;
	public var frames = 0;
	public var cleanups = 0;
	public var lastDt = 0.;

	override public function init():Void
		inits++;

	override public function frame(dt:Float):Void {
		frames++;
		lastDt = dt;
	}

	override public function cleanup():Void
		cleanups++;
}

/** helix.App built with a backend named (-D helix-backend=webgl2, run on Node by tests/tools/app_test.py, which also checks the builds
	that must be refused): the springboards the build writes reach the app in hotApp, and another app once hotApp is re-pointed, as a native reload does;
	the backend table; AppOptions' defaults; a Springboard's three calls. */
@:access(helix.App)
class AppTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	// A Game without its constructor (which would start the profile), its counters at 0 (createEmptyInstance runs no initializer on JS).
	static function empty():Game {
		var game:Game = Type.createEmptyInstance(Game);
		game.inits = game.frames = game.cleanups = 0;
		game.lastDt = 0;
		return game;
	}

	static function main():Void {
		// The springboards: hotApp held as the Springboard is made, each call reaching the app's callbacks through App's run methods.
		var game = empty();
		game.options = new AppOptions();
		game.options.devKeys = false;
		game.options.pageState = false;
		check(Game.hotApp == null, "No app yet");
		var springboard = game.hotSpringboard();
		check(Game.hotApp == game, "Making the springboard holds the app in the class's hot static");
		springboard.init();
		check(game.inits == 1, "init reaches the app");
		springboard.frame(.5);
		check(game.frames == 1 && game.lastDt == .5, "frame reaches the app with its dt");
		springboard.cleanup();
		check(game.cleanups == 1, "cleanup reaches the app");
		// A native reload migrates the object held in hotApp and re-points the statics: the same springboard reaches the new object.
		var migrated = empty();
		migrated.options = game.options;
		@:privateAccess Game.hotApp = migrated;
		springboard.frame(.25);
		check(game.frames == 1 && migrated.frames == 1 && migrated.lastDt == .25, "The springboard reaches the app hotApp holds now");
		Game.hotInit();
		Game.hotFrame(1);
		Game.hotCleanup();
		check(migrated.inits == 1 && migrated.frames == 2 && migrated.cleanups == 1, "The statics the Runner's lambdas call by name");
		var statics = Type.getClassFields(Game);
		for (name in AppBuild.WRITTEN.slice(0, 4))
			check(statics.contains(name), 'The build wrote $name');

		// The backend table.
		check(AppBuild.BACKENDS.join(",") == "webgl2,sokol-gl,sdl3-gl,sdl3-gpu", "The four backends, the browser's first");
		check(AppBuild.profileOf("webgl2") == "helix.profiles.WebGL2Profile"
			&& AppBuild.profileOf("sokol-gl") == "helix.profiles.SokolGLProfile"
			&& AppBuild.profileOf("sdl3-gl") == "helix.profiles.Sdl3GLProfile"
			&& AppBuild.profileOf("sdl3-gpu") == "helix.profiles.Sdl3GpuProfile",
			"Each backend's profile");
		check(AppBuild.profileOf("gl") == null && AppBuild.profileOf("") == null, "A name not in the list has no profile");
		check(AppBuild.isBrowser("webgl2") && !AppBuild.isBrowser("sokol-gl") && !AppBuild.isBrowser("sdl3-gpu"), "Only webgl2 is the browser's");

		// The options' defaults.
		var options = new AppOptions();
		check(options.product == "Game" && options.company == "DefaultCompany", "A default identity");
		check(options.assets == null && options.manifest == null, "The assets beside the program, no manifest");
		check(options.window.msaaSamples == 4, "The window's defaults");
		var debug = #if debug true #else false #end;
		check(options.devKeys == debug && options.pageState == debug, "The development extras follow the build");

		// A Springboard calls what it was given, in order.
		var calls = [];
		var made = new Springboard(() -> calls.push("init"), dt -> calls.push('frame $dt'), () -> calls.push("cleanup"));
		made.init();
		made.frame(2);
		made.cleanup();
		check(calls.join(",") == "init,frame 2,cleanup", "A Springboard's three calls");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
