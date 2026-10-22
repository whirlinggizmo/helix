package helix.render2d;

import helix.scene.Node;

/** A 2D tree shown through a camera (docs/DISPLAY_MODEL.md): a display object, placed on the stage or in another tree, showing content's
	children through camera in its rectangle (View), clipped to it. The camera's position and zoom are the app's (framebuffer pixels per
	world unit, as a Camera2D's always are: Window.pixelRatio for logical pixels); the view sizes its viewport to the rectangle as it draws,
	so after a first frame the camera's viewport is the view's (what CameraFollow2D reads for its bounds). Several views can show one tree
	(a minimap of the world); a world's emitters advance once a frame however many show them. */
class View2D extends View {
	var tree:Renderer2D;
	// With a chain: the batch its tree is drawn into its texture with, the GPU's own.
	var offscreen:Null<Batch2D>;
	// With a chain: the shadows of the 3D views its tree held when last drawn into its texture, drawn before it is again.
	var nestedShadows:Array<Void->Void> = [];

	/** A view of content's children through camera (a new one at world 0, 0, zoom 1 unless given), width x height of its own units (0 for
		the whole area of what shows it). */
	public function new(content:Node2D, ?camera:Camera2D, width = 0., height = 0.) {
		super(width, height);
		this.content = content;
		this.camera = camera == null ? new Camera2D() : camera;
		tree = new Renderer2D(content);
	}

	/** The tree whose children it shows. */
	public var content(default, null):Node2D;

	/** What it's seen through: its position and zoom the app's, its viewport the view's rectangle. */
	public var camera:Camera2D;

	/** How many nodes the last frame drew of its tree, the ones outside the camera's view skipped. */
	public var drawnNodeCount(get, never):Int;

	function get_drawnNodeCount():Int
		return tree.drawnNodeCount;

	override function getContent():Node
		return content;

	override function pickShown(x:Float, y:Float):Null<Node2D>
		return postProcess != null ? tree.pick(camera, x - shownX, y - shownY) : tree.pick(camera, x, y);

	override public function destroy():Void {
		super.destroy();
		if (offscreen != null)
			offscreen.destroy();
		offscreen = null;
	}

	override function drawInto(gpu:helix.graphics.IGraphics, w:Int, h:Int, hdr:Bool, time:Float):Void {
		if (offscreen == null)
			offscreen = new Batch2D(gpu);
		camera.setViewport(w, h);
		// The 3D views in its tree draw into its scene too, under its 2D, in its chain's HDR when it has one.
		var outerDraws = ViewFrame.drawsUnder,
			outerShadows = ViewFrame.shadows,
			outerHdr = ViewFrame.hdr;
		ViewFrame.drawsUnder = [];
		ViewFrame.shadows = [];
		ViewFrame.hdr = hdr;
		offscreen.begin(camera);
		tree.time = time;
		tree.draw(offscreen, camera);
		nestedShadows = ViewFrame.shadows;
		for (draw in ViewFrame.drawsUnder)
			draw();
		offscreen.end();
		ViewFrame.drawsUnder = outerDraws;
		ViewFrame.shadows = outerShadows;
		ViewFrame.hdr = outerHdr;
	}

	override function prepare():Void
		for (draw in nestedShadows)
			draw();

	override function show(batch:Batch2D, outer:Camera2D, x:Int, y:Int, w:Int, h:Int, time:Float):Void {
		camera.setViewport(outer.framebufferWidth, outer.framebufferHeight);
		camera.setViewportArea(x, y, w, h);
		// Clipped to its rectangle, given in framebuffer pixels.
		placePixels(batch, outer);
		batch.pushClip(x, y, w, h);
		tree.time = time;
		tree.draw(batch, camera);
		batch.popClip();
		batch.camera = outer;
	}
}
