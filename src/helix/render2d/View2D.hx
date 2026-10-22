package helix.render2d;

import helix.scene.Node;

/** A 2D tree shown through a camera (docs/DISPLAY_MODEL.md): a display object, placed on the stage or in another tree, showing content's
	children through camera in its rectangle (View), clipped to it. The camera's position and zoom are the app's (framebuffer pixels per
	world unit, as a Camera2D's always are: Window.pixelRatio for logical pixels); the view sizes its viewport to the rectangle as it draws,
	so after a first frame the camera's viewport is the view's (what CameraFollow2D reads for its bounds). Several views can show one tree
	(a minimap of the world); a world's emitters advance once a frame however many show them. */
class View2D extends View {
	var tree:Stage2D;
	var pixels = new Camera2D();

	/** A view of content's children through camera (a new one at world 0, 0, zoom 1 unless given), width x height of its own units (0 for
		the whole area of what shows it). */
	public function new(content:Node2D, ?camera:Camera2D, width = 0., height = 0.) {
		super(width, height);
		this.content = content;
		this.camera = camera == null ? new Camera2D() : camera;
		tree = new Stage2D(content);
	}

	/** The tree whose children it shows. */
	public var content(default, null):Node2D;

	/** What it's seen through: its position and zoom the app's, its viewport the view's rectangle. */
	public var camera:Camera2D;

	override function getContent():Node
		return content;

	override function pickShown(x:Float, y:Float):Null<Node2D>
		return tree.pick(camera, x, y);

	override function show(batch:Batch2D, outer:Camera2D, x:Int, y:Int, w:Int, h:Int, time:Float):Void {
		camera.setViewport(outer.framebufferWidth, outer.framebufferHeight);
		camera.setViewportArea(x, y, w, h);
		// Clipped to its rectangle, given in framebuffer pixels through a camera whose world unit is one, from the top-left.
		pixels.setViewport(outer.framebufferWidth, outer.framebufferHeight);
		pixels.setPosition(outer.framebufferWidth / 2, outer.framebufferHeight / 2);
		batch.resetTransform();
		batch.camera = pixels;
		batch.pushClip(x, y, w, h);
		tree.time = time;
		tree.draw(batch, camera);
		batch.popClip();
		batch.camera = outer;
	}
}
