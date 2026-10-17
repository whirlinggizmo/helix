package helix.scene;

import helix.host.Services;
import helix.input.IInput;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;

/** A game's scenes as a stack: the top one runs; push puts one over it (the one under pauses: a pause menu over play), pop takes it off
	(the one under resumes), replace swaps the top (a title for a level). A transition handed to any of them draws over the frames while the
	scenes swap at its middle. A scene with a loader (Scene.getLoader) is shown the loading scene until its loads are done: the built-in
	Loading unless setLoadingScene gives another, or none. The window losing focus pauses the game's clock and the top scene (setPauseOnBlur,
	on unless turned off); focus resumes them. Scenes read input through getInput (Services.input, or what an autopilot gives through
	setInput). frame runs update then draw; an autopilot runs several updates a frame and one draw. */
class Scenes {
	var stack:Array<Scene> = [];
	var loading:Null<LoadingScene>;
	var input:IInput;
	var pauseOnBlur = true;
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
		loading = new Loading();
		input = Services.input;
	}

	/** The scene on top, or null. */
	public function getTop():Null<Scene>
		return stack.length == 0 ? null : stack[stack.length - 1];

	/** How many scenes are stacked. */
	public function getCount():Int
		return stack.length;

	/** The scenes, bottom first. */
	public function getAll():Array<Scene>
		return stack.copy();

	/** The input scenes read: Services.input, or what setInput gave. */
	public function getInput():IInput
		return input;

	/** What scenes read instead of Services.input: an autopilot's. */
	public function setInput(value:IInput):Void
		input = value;

	/** The scene shown while the top one's loads are pending, or null for none (the scene shows itself loading). */
	public function getLoadingScene():Null<LoadingScene>
		return loading;

	/** Sets the loading scene: the built-in Loading to start, any LoadingScene, or null to show none. */
	public function setLoadingScene(value:Null<LoadingScene>):Void {
		loading = value;
		if (loading != null)
			loading.scenes = this;
	}

	/** Whether the window losing focus pauses the game's clock and the top scene. */
	public function isPauseOnBlur():Bool
		return pauseOnBlur;

	/** Turns pausing on focus loss on or off. */
	public function setPauseOnBlur(value:Bool):Void
		pauseOnBlur = value;

	/** Whether a transition is under way (input is still the scenes'). */
	public function isTransitioning():Bool
		return transition != null;

	/** Puts scene on top: the one under pauses, scene enters. With transition, the swap comes at its middle. */
	public function push(scene:Scene, ?transition:Transition):Void
		change(transition, () -> {
			var below = getTop();
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
			top.exit();
			top.scenes = null;
			var below = getTop();
			if (below != null)
				below.resume();
		});

	/** Swaps the top scene for scene: the top exits, scene enters; the one under stays paused. */
	public function replace(scene:Scene, ?transition:Transition):Void
		change(transition, () -> {
			var top = stack.pop();
			if (top != null) {
				top.exit();
				top.scenes = null;
			}
			add(scene);
		});

	/** Takes every scene off, top first, each exiting. */
	public function clear():Void {
		while (stack.length > 0) {
			var top = stack.pop();
			top.exit();
			top.scenes = null;
		}
		transition = null;
		swap = null;
	}

	/** A frame: update then draw. */
	public function frame(dt:Float):Void {
		update(dt);
		draw();
	}

	/** The frame's logic: the transition's time (the frames'), focus, then the top scene's update, or its loading scene's while it loads. */
	public function update(dt:Float):Void {
		if (transition != null) {
			elapsed += Math.max(0, dt);
			if (!swapped && elapsed >= transition.getSeconds() / 2) {
				swapped = true;
				var f = swap;
				swap = null;
				if (f != null)
					f();
			}
			if (elapsed >= transition.getSeconds())
				transition = null;
		}
		if (Services.window != null)
			focus(Services.window.isFocused());
		var top = getTop();
		if (top == null)
			return;
		var loader = top.getLoader();
		if (loader != null && !loader.isDone()) {
			if (loading != null) {
				if (waiting != top) {
					waiting = top;
					loading.setLoader(loader);
					loading.enter();
				}
				loading.update(dt);
				return;
			}
		} else if (waiting != null) {
			if (loading != null)
				loading.exit();
			waiting = null;
		}
		if (!blurred)
			top.update(dt);
	}

	/** The frame's drawing: the top scene's (or its loading scene's), the transition over it, then the frame's end. */
	public function draw():Void {
		var top = getTop();
		if (top == null)
			return;
		var loader = top.getLoader();
		if (waiting == top && loader != null && !loader.isDone() && loading != null)
			loading.draw();
		else
			top.draw();
		if (transition != null) {
			var width = Services.window.getFramebufferWidth(),
				height = Services.window.getFramebufferHeight();
			if (batch == null)
				batch = new Batch2D(Services.graphics);
			camera.setViewport(width, height);
			camera.pixels(1);
			batch.begin(camera);
			transition.draw(batch, width, height, Math.min(1, elapsed / transition.getSeconds()));
			batch.end();
		}
		Services.graphics.endFrame();
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
			if (Services.clock != null && !Services.clock.isPaused()) {
				Services.clock.pause();
				pausedClock = true;
			}
			var top = getTop();
			if (top != null)
				top.pause();
		} else if (focused && blurred) {
			blurred = false;
			if (pausedClock && Services.clock != null)
				Services.clock.resume();
			pausedClock = false;
			var top = getTop();
			if (top != null)
				top.resume();
		}
	}

	function add(scene:Scene):Void {
		scene.scenes = this;
		stack.push(scene);
		scene.enter();
	}

	// A change now, or at the transition's middle. A change asked during a transition takes over: the new transition starts, its swap at its
	// own middle, and the old one's swap, if it hadn't come, is dropped with it (a scene that mustn't be interrupted asks isTransitioning).
	function change(next:Null<Transition>, f:Void->Void):Void {
		if (next == null) {
			f();
			return;
		}
		transition = next;
		elapsed = 0;
		swapped = false;
		swap = f;
	}
}
