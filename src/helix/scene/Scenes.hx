package helix.scene;

import helix.graphics.Graphics;
import helix.host.Host;
import helix.host.Window;
import helix.input.IInput;
import helix.input.Input;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.time.Time;

/** A game's scenes as a stack: the top one runs; push puts one over it (the one under pauses: a pause menu over play), pop takes it off
	(the one under resumes), replace swaps the top (a title for a level). A transition handed to any of them draws over the frames while the
	scenes swap at its middle. A scene with a loader (Scene.loader) is shown the loading scene until its loads are done: the built-in
	Loading unless loadingScene gives another, or none. The window losing focus pauses the game's clock and the top scene (pauseOnBlur,
	on unless turned off); focus resumes them. Scenes read input through input (Input.instance, or what an autopilot gives through
	input). frame runs update then draw; an autopilot runs several updates a frame and one draw. A frame's update runs the top scene's
	behaviors pass (Scene.behaviors) and then its update, under the same gates (a transition's swap first; nothing while it loads or the
	window is unfocused); a scene's behaviors are cleared, each stopped, just before it exits. Quick (quick; on with the run option
	quick=1, a developer's) skips the built-in screens' waits and every transition: the game jumps in as soon as it's loaded. */
class Scenes {
	var stack:Array<Scene> = [];
	var waitScene:Null<LoadingScene>;
	var blurred = false;
	var pausedClock = false;
	// The transition under way: what it covers, how far, and the swap to make at its middle.
	var transition:Null<Transition>;
	var elapsed = 0.;
	var swapped = false;
	var swap:Null<Void->Void>;
	var batch:Null<Batch2D>;
	var camera = new Camera2D();
	// Whether the top scene was waiting on its loader last frame, so its loading scene is told once when the wait begins.
	var waiting:Null<Scene>;

	/** An empty stack with the built-in loading scene and the program's input. */
	public function new() {
		waitScene = new Loading();
		waitScene.scenes = this;
		input = Input.instance;
		quick = Host.running && Host.getOption("quick", "0") == "1";
	}

	/** Whether the built-in screens' waits and every transition are skipped (the run option quick=1 sets it). */
	public var quick:Bool = false;

	/** The scene on top, or null. */
	public var top(get, never):Null<Scene>;

	function get_top():Null<Scene>
		return stack.length == 0 ? null : stack[stack.length - 1];

	/** How many scenes are stacked. */
	public var count(get, never):Int;

	function get_count():Int
		return stack.length;

	/** The scenes, bottom first. */
	public var all(get, never):Array<Scene>;

	function get_all():Array<Scene>
		return stack.copy();

	/** What scenes read: Input.instance, or what was assigned instead (an autopilot's). */
	public var input:IInput;

	/** The scene shown while the top one's loads are pending, or null for none (the scene shows itself loading). */
	public var loadingScene(get, set):Null<LoadingScene>;

	function get_loadingScene():Null<LoadingScene>
		return waitScene;

	function set_loadingScene(value:Null<LoadingScene>):Null<LoadingScene> {
		waitScene = value;
		if (waitScene != null)
			waitScene.scenes = this;
		return value;
	}

	/** Whether the window losing focus pauses the game's clock and the top scene. */
	public var pauseOnBlur:Bool = true;

	/** Whether a transition is under way (input is still the scenes'). */
	public var transitioning(get, never):Bool;

	function get_transitioning():Bool
		return transition != null;

	/** Whether the loading scene is showing: the top scene's loads are pending, or the loading scene holds after them
		(LoadingScene.holding). */
	public var loading(get, never):Bool;

	function get_loading():Bool {
		var top = this.top;
		if (top == null)
			return false;
		var shown = loadingFor(top);
		if (shown == null)
			return false;
		var loader = top.loader;
		return loader != null && (!loader.done || (waiting == top && shown.holding));
	}

	// The loading scene for scene: its own, else the stack's, else none.
	function loadingFor(scene:Scene):Null<LoadingScene> {
		var own = scene.loadingScene;
		if (own != null) {
			own.scenes = this;
			return own;
		}
		return waitScene;
	}

	/** Puts scene on top: the one under pauses, scene enters. With transition, the swap comes at its middle. */
	public function push(scene:Scene, ?transition:Transition):Void
		change(transition, () -> {
			var below = this.top;
			if (below != null)
				below.pause();
			add(scene);
		});

	/** Takes the top scene off: it exits, the one under resumes. Nothing with an empty stack. */
	public function pop(?transition:Transition):Void
		change(transition, () -> {
			var top = stack.pop();
			if (top == null)
				return;
			leave(top);
			var below = this.top;
			if (below != null)
				below.resume();
		});

	/** Swaps the top scene for scene: the top exits, scene enters; the one under stays paused. */
	public function replace(scene:Scene, ?transition:Transition):Void
		change(transition, () -> {
			var top = stack.pop();
			if (top != null)
				leave(top);
			add(scene);
		});

	/** Takes every scene off, top first, each exiting. */
	public function clear():Void {
		while (stack.length > 0)
			leave(stack.pop());
		transition = null;
		swap = null;
	}

	/** A frame: update then draw. */
	public function frame(dt:Float):Void {
		update(dt);
		draw();
	}

	/** The frame's logic: the transition's time (the frames'), focus, then the top scene's behaviors and its update, or its loading scene's
		update while it loads. */
	public function update(dt:Float):Void {
		if (transition != null) {
			elapsed += Math.max(0, dt);
			if (!swapped && elapsed >= transition.seconds / 2) {
				swapped = true;
				var f = swap;
				swap = null;
				if (f != null)
					f();
			}
			if (elapsed >= transition.seconds)
				transition = null;
		}
		if (Window.instance != null)
			focus(Window.focused);
		var top = this.top;
		if (top == null)
			return;
		var loader = top.loader, shown = loadingFor(top);
		if (loader != null && shown != null && (!loader.done || (waiting == top && shown.holding))) {
			if (waiting != top) {
				waiting = top;
				shown.shownLoader = loader;
				shown.enter();
			}
			shown.update(dt);
			return;
		}
		if (waiting != null) {
			var was = loadingFor(waiting);
			if (was != null)
				was.exit();
			waiting = null;
		}
		if (!blurred) {
			top.behaviors.update(dt);
			top.update(dt);
		}
	}

	/** The frame's drawing: the top scene's (or its loading scene's), the transition over it, then the frame's end. */
	public function draw():Void {
		var top = this.top;
		if (top == null)
			return;
		if (waiting == top && this.loading)
			loadingFor(top).draw();
		else
			top.draw();
		if (transition != null) {
			var width = Window.framebufferWidth,
				height = Window.framebufferHeight;
			if (batch == null)
				batch = new Batch2D();
			camera.setViewport(width, height);
			camera.pixels(1);
			batch.begin(camera);
			transition.draw(batch, width, height, Math.min(1, elapsed / transition.seconds));
			batch.end();
		}
		Graphics.endFrame();
	}

	/** Frees what it made (the transition batch); the scenes are cleared first. */
	public function destroy():Void {
		clear();
		if (batch != null)
			batch.destroy();
		batch = null;
	}

	// The window's focus: lost, the clock and the top scene pause (if the stack pauses on blur); back, they resume.
	function focus(focused:Bool):Void {
		if (!pauseOnBlur)
			focused = true;
		if (!focused && !blurred) {
			blurred = true;
			if (Time.clock != null && !Time.clock.paused) {
				Time.clock.pause();
				pausedClock = true;
			}
			var top = this.top;
			if (top != null)
				top.pause();
		} else if (focused && blurred) {
			blurred = false;
			if (pausedClock && Time.clock != null)
				Time.clock.resume();
			pausedClock = false;
			var top = this.top;
			if (top != null)
				top.resume();
		}
	}

	function add(scene:Scene):Void {
		scene.scenes = this;
		stack.push(scene);
		scene.enter();
	}

	// A scene off the stack: its behaviors stopped, then its exit, which may free what they drove.
	function leave(scene:Scene):Void {
		scene.behaviors.clear();
		scene.exit();
		scene.scenes = null;
	}

	// A change now, or at the transition's middle. A change asked during a transition takes over: the new transition starts, its swap at its
	// own middle, and the old one's swap, if it hadn't come, is dropped with it (a scene that mustn't be interrupted asks transitioning).
	function change(next:Null<Transition>, f:Void->Void):Void {
		if (next == null || quick) {
			f();
			return;
		}
		transition = next;
		elapsed = 0;
		swapped = false;
		swap = f;
	}
}
