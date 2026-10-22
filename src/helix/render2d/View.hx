package helix.render2d;

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

	// Whether its refusal to draw inside itself has been logged.
	var cycleLogged = false;

	// The trees being drawn, the outermost first: a view's tree among them is drawn inside itself.
	static var drawing:Array<Node> = [];

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
		drawing.push(content);
		show(batch, outer, left, top, right - left, bottom - top, time);
		drawing.pop();
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
