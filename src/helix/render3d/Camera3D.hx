package helix.render3d;

/** A 3D view, perspective or orthographic (setOrthographic), as a node: it sees from its world position down its -z, its +y up (its scale
	ignored), so one parented to what it should follow (a car's driver's seat) rides along, and setView places it to look from an eye at a
	target. Right-handed with +y up, seen in a viewport that is the whole framebuffer or an area of it (setViewportArea), as Camera2D's.
	Drawn through by Stage3D.draw and Batch3D.begin whether or not it is on a stage. Distances are world units; angles radians. */
class Camera3D extends Node3D {
	// The orthographic view's height in world units; 0 for perspective.
	// The narrowest shape the view keeps its width at; 0 for none.
	var view = new Mat4();
	var projection = new Mat4();
	var viewProjectionMatrix = new Mat4();
	var placed = new Mat4();
	// Where it is in the world and which way it looks, from placed: the eye, the unit forward (its -z) and up (its +y).
	var eye = [0., 0, 0];
	var forward = [0., 0, -1];
	var up = [0., 1, 0];

	/** A camera at 0, 0, 10 looking at the origin, +y up, a quarter turn (pi/4) of vertical view, clipping at 0.1 and 1000, on a 1 x 1 viewport. */
	public function new() {
		super();
		setView(0, 0, 10, 0, 0, 0);
	}

	/** Places it at eye and turns it to look at target, up giving the roll: positions relative to its parent (the world's, at the top). False,
		changing nothing, when the eye is at the target or up is along the view. */
	public function setView(eyeX:Float, eyeY:Float, eyeZ:Float, targetX:Float, targetY:Float, targetZ:Float, upX = 0., upY = 1., upZ = 0.):Bool {
		var x = px, y = py, z = pz;
		setPosition(eyeX, eyeY, eyeZ);
		if (lookAt(targetX, targetY, targetZ, upX, upY, upZ))
			return true;
		setPosition(x, y, z);
		return false;
	}

	// Its world matrix as it is now, and from it the eye, forward and up.
	function place():Void {
		computeWorld(placed);
		eye[0] = placed.get(12);
		eye[1] = placed.get(13);
		eye[2] = placed.get(14);
		unit(forward, -placed.get(8), -placed.get(9), -placed.get(10), 0, 0, -1);
		unit(up, placed.get(4), placed.get(5), placed.get(6), 0, 1, 0);
	}

	// x, y, z made a unit vector into out; the fallback for a zero one.
	static function unit(out:Array<Float>, x:Float, y:Float, z:Float, fx:Float, fy:Float, fz:Float):Void {
		var l = Math.sqrt(x * x + y * y + z * z);
		out[0] = l > 0 ? x / l : fx;
		out[1] = l > 0 ? y / l : fy;
		out[2] = l > 0 ? z / l : fz;
	}

	/** The eye's x: its world position. */
	public var eyeX(get, never):Float;

	function get_eyeX():Float {
		place();
		return eye[0];
	}

	/** The eye's y. */
	public var eyeY(get, never):Float;

	function get_eyeY():Float {
		place();
		return eye[1];
	}

	/** The eye's z. */
	public var eyeZ(get, never):Float;

	function get_eyeZ():Float {
		place();
		return eye[2];
	}

	/** Which way it looks, in the world, x: its -z, a unit vector. */
	public var forwardX(get, never):Float;

	function get_forwardX():Float {
		place();
		return forward[0];
	}

	/** Which way it looks, y. */
	public var forwardY(get, never):Float;

	function get_forwardY():Float {
		place();
		return forward[1];
	}

	/** Which way it looks, z. */
	public var forwardZ(get, never):Float;

	function get_forwardZ():Float {
		place();
		return forward[2];
	}

	/** Its up in the world, x: its +y, a unit vector square to the view. */
	public var upX(get, never):Float;

	function get_upX():Float {
		place();
		return up[0];
	}

	/** Its up, y. */
	public var upY(get, never):Float;

	function get_upY():Float {
		place();
		return up[1];
	}

	/** Its up, z. */
	public var upZ(get, never):Float;

	function get_upZ():Float {
		place();
		return up[2];
	}

	/** The vertical field of view in radians. */
	public var fovY(default, null):Float = Math.PI / 4;

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

	/** The narrowest viewport shape (width / height) the view keeps its width at: on a narrower viewport its vertical view
		(setPerspective's fovY, or an orthographic height) grows so it sees as far across as at this aspect. A scene framed for 16:9 (16 /
		9) shows all its width on a phone held upright, with more above and below (Godot's keep-width; Presentation's Expand, in 3D). 0,
		the default, for none; 0 or more (under 0, or NaN, is 0). */
	public var minAspect(default, set):Float = 0.;

	function set_minAspect(aspect:Float):Float {
		aspect = aspect >= 0 ? aspect : 0;
		minAspect = aspect;
		return aspect;
	}

	/** The vertical field of view drawn, in radians: fovY, widened on a viewport narrower than the minimum aspect (minAspect). */
	public var drawnFovY(get, never):Float;

	function get_drawnFovY():Float {
		var aspect = viewportWidth / viewportHeight;
		return aspect < minAspect ? 2 * Math.atan(Math.tan(fovY / 2) * minAspect / aspect) : fovY;
	}

	/** The orthographic height drawn, in world units: orthographicHeight, taller on a viewport narrower than the minimum aspect. */
	public var drawnHeight(get, never):Float;

	function get_drawnHeight():Float {
		var aspect = viewportWidth / viewportHeight;
		return aspect < minAspect ? orthographicHeight * minAspect / aspect : orthographicHeight;
	}

	/** The near clip plane's distance from the eye. */
	public var near(default, null):Float = .1;

	/** The far clip plane's distance from the eye. */
	public var far(default, null):Float = 1000.;

	/** An orthographic projection's height in world units; 0 for a perspective one. */
	public var orthographicHeight(default, null):Float = 0.;

	/** Whether the projection is orthographic. */
	public var orthographic(get, never):Bool;

	function get_orthographic():Bool
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
	public var framebufferWidth(default, null):Int = 1;

	/** The framebuffer height in pixels, from setViewport. */
	public var framebufferHeight(default, null):Int = 1;

	/** The viewport's left edge in framebuffer pixels from the framebuffer's left. */
	public var viewportX(default, null):Int = 0;

	/** The viewport's top edge in framebuffer pixels from the framebuffer's top. */
	public var viewportY(default, null):Int = 0;

	/** The viewport width in framebuffer pixels. */
	public var viewportWidth(default, null):Int = 1;

	/** The viewport height in framebuffer pixels. */
	public var viewportHeight(default, null):Int = 1;

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

	/** World to clip space, for the viewport's shape: projection * view, recomputed by each call, the view from where it is in the world now. */
	public var viewProjection(get, never):Mat4;

	function get_viewProjection():Mat4 {
		place();
		view.makeLookAt(eye[0], eye[1], eye[2], eye[0] + forward[0], eye[1] + forward[1], eye[2] + forward[2], up[0], up[1], up[2]);
		if (orthographicHeight > 0)
			projection.makeOrthographic(this.drawnHeight, viewportWidth / viewportHeight, near, far);
		else
			projection.makePerspective(this.drawnFovY, viewportWidth / viewportHeight, near, far);
		viewProjectionMatrix.makeProduct(projection, view);
		return viewProjectionMatrix;
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
		if (!inverse.makeInverse(this.viewProjection))
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
