package helix.render3d;

import helix.graphics.IGraphics;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.View;
import helix.scene.Node;

/** A 3D tree shown through a camera (docs/DISPLAY_MODEL.md): a display object, placed on the stage or in a 2D tree, showing content's
	children through camera in its rectangle (View). It holds the photography: the camera, the exposure and the tone mapping. Drawn under
	every 2D thing in the frame, as Flash's Stage3D content was under its display list: the 2D batch sends its draws once, at the frame's
	end. The view sizes the camera's viewport to its rectangle as it draws. Several views can show one tree (split screen); each draws it
	for itself. */
class View3D extends View {
	var gpu:Null<IGraphics>;
	var world:Null<Stage3D>;
	// Its rectangle in framebuffer pixels, as the walk gave it.
	var areaX = 0;
	var areaY = 0;
	var areaWidth = 1;
	var areaHeight = 1;
	var framebufferWidth = 1;
	var framebufferHeight = 1;
	var time = 0.;

	/** A view of content's children through camera (a new one unless given), width x height of its own units (0 for the whole area of what
		shows it), drawn on gpu (the program's, Graphics.instance, unless given). */
	public function new(content:Node3D, ?camera:Camera3D, width = 0., height = 0., ?gpu:IGraphics) {
		super(width, height);
		this.content = content;
		this.camera = camera == null ? new Camera3D() : camera;
		this.gpu = gpu;
	}

	/** The tree whose children it shows. */
	public var content(default, null):Node3D;

	/** What it's seen through: its eye, projection and lens the app's, its viewport the view's rectangle. */
	public var camera:Camera3D;

	/** How lit color comes into the screen's 0..1 after the exposure (Khronos PBR Neutral to start). */
	public var tonemap:Tonemap = Tonemap.Neutral;

	/** The exposure in stops (EV): each one doubles the light before the tone mapping; 0 to start. An exposure that isn't finite is 0. */
	public var exposure(default, set):Float = 0.;

	function set_exposure(value:Float):Float {
		exposure = Math.isFinite(value) ? value : 0;
		return exposure;
	}

	/** How many models the last frame drew, the ones outside the camera's view culled. */
	public var drawnNodeCount(get, never):Int;

	function get_drawnNodeCount():Int
		return world == null ? 0 : world.drawnNodeCount;

	override function getContent():Node
		return content;

	// Deferred: drawn under the 2D before the batch ends (drawDeferred), in the rectangle the walk gave.
	override function show(batch:Batch2D, outer:Camera2D, x:Int, y:Int, w:Int, h:Int, time:Float):Void {
		areaX = x;
		areaY = y;
		areaWidth = w;
		areaHeight = h;
		framebufferWidth = outer.framebufferWidth;
		framebufferHeight = outer.framebufferHeight;
		this.time = time;
		View.deferred.push(this);
	}

	override function prepare():Void
		if (world != null)
			world.drawShadows(camera);

	override function drawDeferred():Void {
		if (world == null)
			world = new Stage3D(gpu, content);
		camera.setViewport(framebufferWidth, framebufferHeight);
		camera.setViewportArea(areaX, areaY, areaWidth, areaHeight);
		world.tonemap = tonemap;
		world.exposure = exposure;
		world.time = time;
		world.draw(camera);
	}

	/** Frees what it drew with (its GPU buffers); the tree is the app's. */
	public function destroy():Void {
		if (world != null)
			world.destroy();
		world = null;
	}
}
