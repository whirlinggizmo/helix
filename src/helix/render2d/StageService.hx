package helix.render2d;

import helix.graphics.IGraphics;
import helix.host.Presentation;

/** The stage: the one thing the runner draws, after the app's update, every frame (docs/DISPLAY_MODEL.md). Its children are display objects
	(Node2D and its kinds), drawn in order, later over earlier, through a camera showing the app's design units (Screen: logical pixels unless
	a presentation mode says otherwise), cleared to its color first. Flash's stage: what a game adds to it shows, with nothing to draw by
	hand. Installed by its first use (Stage), so a program that never uses it carries none of it. */
@:build(helix.macro.Facade.record())
class StageService {
	var gpu:IGraphics;
	var presentation:Presentation;
	var tree = new Stage2D();
	var camera = new Camera2D();
	var batch:Null<Batch2D>;

	// The program's stage, made at its first use and drawn by the runner each frame (an optional part, helix.host.Part).

	@:allow(helix.render2d.Stage)
	static function install():StageService {
		return helix.host.Host.installPart(runner -> {
			var service = new StageService(helix.graphics.Graphics.instance, helix.host.Screen.instance);
			runner.install({
				draw: () -> service.draw(helix.time.Time.time),
				shutdown: () -> {
					service.destroy();
					Stage.bind(null);
				}
			});
			service;
		});
	}

	/** A stage drawn on gpu, its camera showing presentation's design units. */
	public function new(gpu:IGraphics, presentation:Presentation) {
		this.gpu = gpu;
		this.presentation = presentation;
	}

	/** What the frame is cleared to before the stage draws, 0xAARRGGBB (Flash's stage.color). Black to start. */
	public var color:Int = 0xff000000;

	/** Puts node on the stage over what's there (its last child), taking it from any parent it had; a child of the stage already moves to
		the top, as Flash's addChild does (Node2D.addChild). */
	public function addChild(node:Node2D):Void
		tree.add(node);

	/** Takes node off the stage. False, changing nothing, for a node that isn't one of its children. */
	public function removeChild(node:Node2D):Bool
		return tree.remove(node);

	/** How many children the stage has. */
	public var childCount(get, never):Int;

	function get_childCount():Int
		return tree.root.childCount;

	/** How many nodes the last frame drew, the ones outside the view skipped. */
	public var drawnNodeCount(get, never):Int;

	function get_drawnNodeCount():Int
		return tree.drawnNodeCount;

	/** Draws the frame: opens it, cleared to color, draws the stage's children through the presentation's camera, and closes it. The runner
		calls it once a frame after the app's update, with the game's clock in seconds (emitters advance by it); a program without one (a
		test) calls it itself. */
	public function draw(time:Float):Void {
		if (batch == null)
			batch = new Batch2D(gpu);
		presentation.apply(camera);
		tree.time = time;
		gpu.beginFrame(presentation.framebufferWidth, presentation.framebufferHeight, color);
		batch.begin(camera);
		tree.draw(batch, camera);
		batch.end();
		gpu.endFrame();
	}

	/** Frees its batch. */
	public function destroy():Void {
		if (batch != null)
			batch.destroy();
		batch = null;
	}
}
