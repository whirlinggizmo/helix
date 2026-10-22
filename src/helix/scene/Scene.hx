package helix.scene;

import helix.behavior.BehaviorPass;

/** One screen of a game (a splash, a title, a level, a pause menu) on a Scenes stack, which calls it through the object (hooks are overrides,
	so a hot reload reaches them, DECISIONS 123): enter once it's pushed, update and draw each frame while it's on top, pause when another is
	pushed over it or the window loses focus, resume when that ends, exit when it's popped or replaced. A scene that loads first returns its
	Loader (loader) from enter on: the stack shows its loading scene until the loader is done, then runs this one. draw begins the frame
	(Graphics.beginFrame) and draws; the stack ends it, after any transition it draws over. Its behaviors (behaviors) are a pass of its own,
	which the stack updates just before update each frame this scene runs, and clears, stopping each, just before exit. */
class Scene {
	/** A scene not on a stack yet, its behaviors pass empty. */
	public function new() {
		behaviors = new BehaviorPass();
	}

	/** Its behaviors: the pass the stack updates before its update each frame it runs (not while it's under another scene, loading or the
		window is unfocused) and clears before its exit. What a scene file instantiated onto this scene attaches its behaviors to. */
	public var behaviors(default, null):BehaviorPass;

	/** Its name: the class's, without its package, unless overridden; what an autopilot's probe reports. */
	public var name(get, never):String;

	function get_name():String
		return Type.getClassName(Type.getClass(this)).split(".").pop();

	/** The stack it's on, or null. */
	@:allow(helix.scene.Scenes)
	public var scenes(default, null):Null<Scenes>;

	/** The loads it waits for before it runs, or null for none: made in enter. */
	public var loader(get, never):Null<Loader>;

	function get_loader():Null<Loader>
		return null;

	/** The loading scene shown while its loads are pending, or null for the stack's (Scenes.loadingScene): a level with its own picture
		and caption. */
	public var loadingScene(get, never):Null<LoadingScene>;

	function get_loadingScene():Null<LoadingScene>
		return null;

	/** Pushed onto the stack: make what it needs, start its loads. */
	public function enter():Void {}

	/** Popped or replaced: free what it made. */
	public function exit():Void {}

	/** Another scene pushed over it, or the window lost focus (Scenes.pauseOnBlur). */
	public function pause():Void {}

	/** On top again, or the window focused again. */
	public function resume():Void {}

	/** A frame's logic, dt seconds since the last (the game's clock's delta, or an autopilot's tick). */
	public function update(dt:Float):Void {}

	/** A frame's drawing: begins the frame and draws; the stack ends the frame. */
	public function draw():Void {}
}
