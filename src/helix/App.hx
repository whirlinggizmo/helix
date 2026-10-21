package helix;

import helix.app.AppOptions;
import helix.app.IApp;
import helix.app.Springboard;
import helix.graphics.Screenshots;
import helix.host.Host;
import helix.host.Identity;
import helix.input.Input;
import helix.input.Key;

/** HeliX's entry point. A game is a class extending it, overriding init, frame and cleanup (the IApp contract), and its Main is
	`new Game()`: the constructor starts HeliX, picking the profile by the backend the build names (`-D helix-backend=webgl2`,
	`sokol-gl`, `sdl3-gl` or `sdl3-gpu`; a build naming none fails, naming the choices), so one Main serves every target: `class Game
	extends helix.App { override public function init():Void {...} override public function frame(dt:Float):Void {...} }` (init once,
	the services bound: Window, Input, Graphics and the others; frame once a display refresh, drawing between Graphics.beginFrame and
	endFrame), and `class Main { static function main() new Game(); }`.

	The object exists before HeliX does: a field initializer runs before the services are bound, so what needs them (a Batch2D, a
	texture) is made in init. Natively the constructor returns only when the window closes. Options (AppOptions: the identity, where the
	assets are, a manifest, the window, the development extras) are given to the constructor, `super(options)` or `new Game(options)`.

	Hot reload: the Runner reaches the app only through `@:hot` static springboards that helix.macro.AppBuild writes into the game's class
	(`hotApp`, the object; `hotInit`, `hotFrame`, `hotCleanup`), so a native reload re-points its calls and migrates the object (hotreload-hx:
	the main class is compiled once and never reloaded, and a call from code compiled before a reload reaches new code only through a
	`@:hot` static function); in the browser old classes forward, so it costs nothing. The game class is therefore not Main, which
	hotreload-hx never reloads and refuses `@:hot` in. */
@:autoBuild(helix.macro.AppBuild.build())
class App implements IApp {
	/** The options it started with. */
	public var options(default, null):AppOptions;

	/** Starts HeliX with this app, with options (the defaults when not given): the profile of the build's backend runs, binds the
		services, calls init once the game's config.json (if any) has come, then frame once a display refresh, and cleanup when the
		window closes (the page goes away). Throws for an identity (product, company) that isn't a file name. Natively returns when the
		window has closed. */
	public function new(?options:AppOptions) {
		this.options = options == null ? new AppOptions() : options;
		hotStart(new Identity(this.options.product, this.options.company), hotSpringboard());
	}

	public function init():Void {}

	public function frame(dt:Float):Void {}

	public function cleanup():Void {}

	// What the subclass's springboards call: the development extras (AppOptions) around the app's own callbacks. Final, so init, frame and
	// cleanup are the only overrides.
	final function runInit():Void
		init();

	final function runFrame(dt:Float):Void {
		if (options.devKeys && Input.isFramePressed(Key.F9))
			Screenshots.take(null, result -> switch result {
				case Saved(where, _): trace('Screenshot saved: $where');
				case Failed(message): trace('Screenshot failed: $message');
			});
		frame(dt);
		if (options.pageState)
			Host.instance.reportBusy(Host.busy);
	}

	// After a quit nothing loads (the shutdown cancelled it all), and no frame comes to say so.
	final function runCleanup():Void {
		cleanup();
		if (options.pageState)
			Host.instance.reportBusy(false);
	}

	// Written by helix.macro.AppBuild into every subclass: the Springboard over the class's @:hot statics, hotApp set to this ...
	function hotSpringboard():Springboard
		throw "helix.App: hotSpringboard is written by helix.macro.AppBuild into each subclass";

	// ... and the start on the profile of the backend the build names.
	function hotStart(identity:Identity, springboard:Springboard):Void
		throw "helix.App: hotStart is written by helix.macro.AppBuild into each subclass";
}
