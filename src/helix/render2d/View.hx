package helix.render2d;

import helix.graphics.IGraphics;
import helix.graphics.PostProcess;
import helix.scene.Node;

/** What View2D and View3D share (docs/DISPLAY_MODEL.md): a display object showing a tree of nodes through a camera, in a rectangle width x
	height of its own units from its position, scaled with it and not turned (a view is drawn upright; its rotation is ignored), or, with a
	width or height of 0, the whole area of whatever shows it (the stage's, or the view it's in). Placed like any node: on the stage, or in a
	tree another view shows (a minimap in a panel). A view is never drawn inside the tree it shows: one that would be (it shows a tree it's
	in, or one already being drawn above it) is skipped, and logged once. */
class View extends Node2D {
	/** A view width x height of its own units (0 for the whole area showing it). */
	function new(width:Float, height:Float) {
		super();
		this.width = width;
		this.height = height;
	}

	/** Its width in its own units; 0 or less for the whole area of what shows it. */
	public var width:Float;

	/** Its height in its own units; 0 or less for the whole area of what shows it. */
	public var height:Float;

	/** Screen effects over what it shows (a pixelated game under a sharp HUD, a blurred world behind a menu), or null for none. With a
		chain, what it shows is drawn into a texture before the frame opens, the chain run over it, and the result drawn where the view is,
		in the 2D's order like any 2D thing (so a 3D view with a chain sits between 2D things), a frame behind its rectangle: it's drawn at
		the size the view was last shown at, and nothing shows the first frame. */
	public var postProcess:Null<PostProcess>;

	// With a chain: what the chain gave, the size it was drawn at, and the GPU it's on.
	var output:Null<Texture2D>;
	var outputGpu:Null<IGraphics>;
	// A camera whose world unit is a framebuffer pixel from the top-left: what its clip and its texture are placed through.
	var pixels = new Camera2D();

	// The views with a chain the frame's walk reached, drawn into their textures before the next frame opens.
	@:allow(helix.render2d.StageService)
	static var textured:Array<View> = [];

	// Whether its refusal to draw inside itself has been logged.
	var cycleLogged = false;

	// Where it was last shown, in framebuffer pixels: what the pointer picks inside.
	var shownX = 0;
	var shownY = 0;
	var shownWidth = 0;
	var shownHeight = 0;

	// The 3D views a pick passed over the point in, the topmost last: tried once nothing 2D was hit, 3D drawing under the 2D.
	@:allow(helix.render2d.StageService)
	static var picked3D:Array<View> = [];

	// The trees being drawn, the outermost first: a view's tree among them is drawn inside itself.
	static var drawing:Array<Node> = [];

	// Whether the frame's 3D is drawn into an HDR scene (the stage's chain wants it): the 3D views write their light untone-mapped.
	@:allow(helix.render2d.StageService)
	static var hdr = false;

	// The 3D views reached by the frame's 2D walk, drawn under its 2D (View3D) before the batch ends, and the last frame's, whose shadows
	// are drawn before the next frame opens.
	@:allow(helix.render2d.StageService)
	static var deferred:Array<View> = [];

	/** The tree it shows. */
	function getContent():Node
		throw "View: a subclass shows a tree";

	// Draws what it shows into batch in framebuffer pixels x, y, w, h (from the top-left), at time, the walk's camera outer: a 2D view now,
	// a 3D one deferred.
	function show(batch:Batch2D, outer:Camera2D, x:Int, y:Int, w:Int, h:Int, time:Float):Void {}

	// Called by the 2D pick at this view: what it shows under framebuffer pixel x, y, if it was shown there (a 2D view's node, or a 3D
	// view noted for after the 2D, picked3D).

	@:allow(helix.render2d.Stage2D)
	function pickInside(x:Float, y:Float):Null<Node2D> {
		if (!(x >= shownX && x < shownX + shownWidth && y >= shownY && y < shownY + shownHeight))
			return null;
		return pickShown(x, y);
	}

	// What it shows under x, y, inside its rectangle.
	function pickShown(x:Float, y:Float):Null<Node2D>
		return null;

	// For a 3D view: the node under x, y in its tree, hit filled; null for none.

	@:allow(helix.render2d.StageService)
	function pick3D(x:Float, y:Float, hit:Any):Null<Node>
		return null;

	// For a 3D view: its shadows, before the frame opens.

	@:allow(helix.render2d.StageService)
	function prepare():Void {}

	// For a 3D view: its tree, under the 2D, before the batch ends.

	@:allow(helix.render2d.StageService)
	function drawDeferred():Void {}

	// Called by the 2D walk at this view, its world transform current and outer the camera the walk draws through: its rectangle in
	// framebuffer pixels, clipped, then what it shows, unless that would draw it inside itself.

	@:allow(helix.render2d.Stage2D)
	function reach(batch:Batch2D, outer:Camera2D, time:Float):Void {
		var content = getContent();
		if (content == null)
			return;
		if (drawing.indexOf(content) >= 0 || isInside(content)) {
			if (!cycleLogged) {
				cycleLogged = true;
				trace('View: "$name" shows a tree it is drawn inside; skipped');
			}
			return;
		}
		var x0:Float, y0:Float, x1:Float, y1:Float;
		if (width > 0 && height > 0) {
			x0 = outer.worldToScreenX(wx);
			y0 = outer.worldToScreenY(wy);
			x1 = outer.worldToScreenX(wa * width + wc * height + wx);
			y1 = outer.worldToScreenY(wb * width + wd * height + wy);
		} else {
			x0 = outer.viewportX;
			y0 = outer.viewportY;
			x1 = outer.viewportX + outer.viewportWidth;
			y1 = outer.viewportY + outer.viewportHeight;
		}
		var left = Math.round(Math.min(x0, x1)),
			top = Math.round(Math.min(y0, y1)),
			right = Math.round(Math.max(x0, x1)),
			bottom = Math.round(Math.max(y0, y1));
		// Kept inside the framebuffer, as a viewport must be.
		left = left < 0 ? 0 : left;
		top = top < 0 ? 0 : top;
		right = right > outer.framebufferWidth ? outer.framebufferWidth : right;
		bottom = bottom > outer.framebufferHeight ? outer.framebufferHeight : bottom;
		if (right - left < 1 || bottom - top < 1)
			return;
		shownX = left;
		shownY = top;
		shownWidth = right - left;
		shownHeight = bottom - top;
		if (postProcess != null) {
			// Drawn into its texture before the next frame; this one shows what the last drew, where the view is.
			textured.push(this);
			if (output != null) {
				placePixels(batch, outer);
				batch.image(output, left, top, right - left, bottom - top);
				batch.camera = outer;
			}
			return;
		}
		drawing.push(content);
		show(batch, outer, left, top, right - left, bottom - top, time);
		drawing.pop();
	}

	// The batch seen through a camera of framebuffer pixels from the top-left, untransformed.
	function placePixels(batch:Batch2D, outer:Camera2D):Void {
		pixels.setViewport(outer.framebufferWidth, outer.framebufferHeight);
		pixels.setPosition(outer.framebufferWidth / 2, outer.framebufferHeight / 2);
		batch.resetTransform();
		batch.camera = pixels;
	}

	// With a chain, before the frame opens: what it shows drawn at the size it was last shown, through the chain, into its texture.

	@:allow(helix.render2d.StageService)
	function render(gpu:IGraphics, time:Float):Void {
		var chain = postProcess, w = shownWidth, h = shownHeight;
		if (chain == null || w < 1 || h < 1)
			return;
		if (output != null && (output.width != w || output.height != h || outputGpu != gpu)) {
			output.destroy(outputGpu);
			output = null;
		}
		if (output == null) {
			output = Texture2D.renderTarget(gpu, w, h, true, Rgba8, false);
			outputGpu = gpu;
		}
		// A 3D view's shadows first: passes into textures don't nest.
		prepare();
		chain.beginScene(w, h, 0x00000000);
		drawInto(gpu, w, h, chain.hdr, time);
		chain.endScene(time);
		gpu.beginTargetPass(output.handle, 0, 0, 0, 0);
		chain.present();
		gpu.endTargetPass();
	}

	// What it shows drawn into the open target pass, w x h pixels, in HDR when hdr.
	function drawInto(gpu:IGraphics, w:Int, h:Int, hdr:Bool, time:Float):Void {}

	/** Frees what it drew with (its texture for effects, its GPU buffers); the chain and the tree are the app's. */
	public function destroy():Void {
		if (output != null)
			output.destroy(outputGpu);
		output = null;
	}

	// Whether this view is content or under it.
	function isInside(content:Node):Bool {
		var node:Null<Node2D> = this;
		while (node != null) {
			if (node == content)
				return true;
			node = node.parent;
		}
		return false;
	}
}
