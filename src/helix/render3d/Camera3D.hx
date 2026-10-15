package helix.render3d;

/** A 3D view, perspective or orthographic (setOrthographic): an eye looking at a target, right-handed with +y up by default, seen in a viewport that is the whole framebuffer or an
	area of it (setViewportArea), as Camera2D's. Distances are world units; angles radians. */
class Camera3D {
	var eyeX = 0.;
	var eyeY = 0.;
	var eyeZ = 10.;
	var targetX = 0.;
	var targetY = 0.;
	var targetZ = 0.;
	var upX = 0.;
	var upY = 1.;
	var upZ = 0.;
	var fovY = Math.PI / 4;
	var near = .1;
	var far = 1000.;
	// The orthographic view's height in world units; 0 for perspective.
	var orthographicHeight = 0.;
	var framebufferWidth = 1;
	var framebufferHeight = 1;
	var viewportX = 0;
	var viewportY = 0;
	var viewportWidth = 1;
	var viewportHeight = 1;
	var view = new Mat4();
	var projection = new Mat4();
	var viewProjection = new Mat4();
	var placed = new Mat4();

	/** The node placing it (Node.camera), or null: then its view is setView's. */
	@:allow(helix.render3d.Node)
	var node(default, null):Null<Node>;

	/** A camera at 0, 0, 10 looking at the origin, +y up, a quarter turn (pi/4) of vertical view, clipping at 0.1 and 1000, on a 1 x 1 viewport. */
	public function new()
		setView(0, 0, 10, 0, 0, 0);

	/** Looks from eye at target; up gives the roll. False, changing nothing, when the eye is at the target or up is parallel to the view. On a
		node, the node's place replaces it at the next draw. */
	public function setView(eyeX:Float, eyeY:Float, eyeZ:Float, targetX:Float, targetY:Float, targetZ:Float, upX = 0., upY = 1., upZ = 0.):Bool {
		if (!view.setLookAt(eyeX, eyeY, eyeZ, targetX, targetY, targetZ, upX, upY, upZ))
			return false;
		this.eyeX = eyeX;
		this.eyeY = eyeY;
		this.eyeZ = eyeZ;
		this.targetX = targetX;
		this.targetY = targetY;
		this.targetZ = targetZ;
		this.upX = upX;
		this.upY = upY;
		this.upZ = upZ;
		return true;
	}

	/** The eye's X. */
	public function getEyeX():Float
		return eyeX;

	/** The eye's Y. */
	public function getEyeY():Float
		return eyeY;

	/** The eye's Z. */
	public function getEyeZ():Float
		return eyeZ;

	/** The target's X. */
	public function getTargetX():Float
		return targetX;

	/** The target's Y. */
	public function getTargetY():Float
		return targetY;

	/** The target's Z. */
	public function getTargetZ():Float
		return targetZ;

	/** The up direction setView was given (the roll), x. */
	public function getUpX():Float
		return upX;

	/** The up direction's y. */
	public function getUpY():Float
		return upY;

	/** The up direction's z. */
	public function getUpZ():Float
		return upZ;

	/** The vertical field of view in radians. */
	public function getFovY():Float
		return fovY;

	/** The projection: fovY radians of vertical view, near and far the clip planes' distances. False, changing nothing, unless 0 < fovY < pi and
		0 < near < far. */
	public function setPerspective(fovY:Float, near:Float, far:Float):Bool {
		if (!(fovY > 0 && fovY < Math.PI && near > 0 && far > near))
			return false;
		this.fovY = fovY;
		this.near = near;
		this.far = far;
		orthographicHeight = 0;
		return true;
	}

	/** The near clip plane's distance from the eye. */
	public function getNear():Float
		return near;

	/** The far clip plane's distance from the eye. */
	public function getFar():Float
		return far;

	/** An orthographic projection's height in world units; 0 for a perspective one. */
	public function getOrthographicHeight():Float
		return orthographicHeight;

	/** Whether the projection is orthographic. */
	public function isOrthographic():Bool
		return orthographicHeight > 0;

	/** An orthographic projection, with no perspective: height world units seen top to bottom (the width by the viewport's shape), near and far
		the clip planes' distances from the eye (near may be 0 or less). setPerspective goes back. False, changing nothing, unless height > 0 and
		near < far. */
	public function setOrthographic(height:Float, near:Float, far:Float):Bool {
		if (!(height > 0 && far > near))
			return false;
		orthographicHeight = height;
		this.near = near;
		this.far = far;
		return true;
	}

	/** The framebuffer width in pixels, from setViewport. */
	public function getFramebufferWidth():Int
		return framebufferWidth;

	/** The framebuffer height in pixels, from setViewport. */
	public function getFramebufferHeight():Int
		return framebufferHeight;

	/** The viewport's left edge in framebuffer pixels from the framebuffer's left. */
	public function getViewportX():Int
		return viewportX;

	/** The viewport's top edge in framebuffer pixels from the framebuffer's top. */
	public function getViewportY():Int
		return viewportY;

	/** The viewport width in framebuffer pixels. */
	public function getViewportWidth():Int
		return viewportWidth;

	/** The viewport height in framebuffer pixels. */
	public function getViewportHeight():Int
		return viewportHeight;

	/** The framebuffer it draws to, width x height pixels, all of it the viewport; a size under 1 clamps to 1. */
	public function setViewport(width:Int, height:Int):Void {
		framebufferWidth = viewportWidth = width < 1 ? 1 : width;
		framebufferHeight = viewportHeight = height < 1 ? 1 : height;
		viewportX = viewportY = 0;
	}

	/** Narrows the viewport to an area of the framebuffer last given to setViewport: x, y is its top-left in framebuffer pixels from the
		framebuffer's top-left. The next setViewport takes the whole framebuffer again. False, changing nothing, for a width or height under 1 or an
		area not inside the framebuffer. */
	public function setViewportArea(x:Int, y:Int, width:Int, height:Int):Bool {
		if (width < 1 || height < 1 || x < 0 || y < 0 || x + width > framebufferWidth || y + height > framebufferHeight)
			return false;
		viewportX = x;
		viewportY = y;
		viewportWidth = width;
		viewportHeight = height;
		return true;
	}

	/** The node placing it, or null. */
	public function getNode():Null<Node>
		return node;

	/** World to clip space, for the viewport's shape: projection * view, recomputed by each call (on a node, the view from where the node is
		now). */
	public function getViewProjection():Mat4 {
		if (node != null && node.getCamera() == this) {
			// Seeing from the node, down its -z, its +y up; its scale ignored.
			node.computeWorld(placed);
			var fx = -placed.get(8),
				fy = -placed.get(9),
				fz = -placed.get(10),
				fl = Math.sqrt(fx * fx + fy * fy + fz * fz);
			var ex = placed.get(12), ey = placed.get(13), ez = placed.get(14);
			if (fl > 0)
				setView(ex, ey, ez, ex + fx / fl, ey + fy / fl, ez + fz / fl, placed.get(4), placed.get(5), placed.get(6));
		}
		if (orthographicHeight > 0)
			projection.makeOrthographic(orthographicHeight, viewportWidth / viewportHeight, near, far);
		else
			projection.makePerspective(fovY, viewportWidth / viewportHeight, near, far);
		viewProjection.setProduct(projection, view);
		return viewProjection;
	}

	/** The ray through framebuffer pixel x, y (from the framebuffer's top-left, as the pointer is) into ray: from the near plane, away from the
		camera, through the same matrices the stage draws with (perspective or orthographic, the viewport's shape). False, leaving ray as it
		was, for a point outside the viewport area (a pointer off the window, -1, -1, among them). */
	public function computeRay(x:Float, y:Float, ray:Ray):Bool {
		if (!(x >= viewportX && x < viewportX + viewportWidth && y >= viewportY && y < viewportY + viewportHeight))
			return false;
		// Normalized device coordinates: -1 to 1 across the viewport, y up.
		var nx = (x - viewportX) / viewportWidth * 2 - 1,
			ny = 1 - (y - viewportY) / viewportHeight * 2;
		if (!inverse.setInverse(getViewProjection()))
			return false;
		var near = unproject(nx, ny, -1),
			nearX = near[0],
			nearY = near[1],
			nearZ = near[2];
		var far = unproject(nx, ny, 1);
		return ray.set(nearX, nearY, nearZ, far[0] - nearX, far[1] - nearY, far[2] - nearZ);
	}

	// Clip-space x, y, z through `inverse` to the world, divided by w.
	function unproject(x:Float, y:Float, z:Float):Array<Float> {
		var m = inverse, w = m.get(3) * x + m.get(7) * y + m.get(11) * z + m.get(15);
		for (r in 0...3)
			point[r] = (m.get(r) * x + m.get(4 + r) * y + m.get(8 + r) * z + m.get(12 + r)) / w;
		return point;
	}

	var inverse = new Mat4();
	var point = [0., 0, 0];
}
