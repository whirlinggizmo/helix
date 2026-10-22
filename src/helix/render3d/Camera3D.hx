package helix.render3d;

/** A 3D view, perspective or orthographic (projection), as a node: it sees from its world position down its -z, its +y up (its scale
	ignored), so one parented to what it should follow (a car's driver's seat) rides along, and setView places it to look from an eye at a
	target. Right-handed with +y up, seen in a viewport that is the whole framebuffer or an area of it (setViewportArea), as Camera2D's.
	Drawn through by Renderer3D.draw and Batch3D.begin whether or not it is on a stage. Distances are world units; angles radians. Its
	values are properties that clamp (fovY, near, far, orthographicHeight, minAspect, lensShiftX and lensShiftY), each held to its range as its doc comment says. */
class Camera3D extends Node3D {
	// The least a clip distance is from 0 (perspective near) or from its partner (near from far), and the least orthographic height:
	// where a value lands when set at or past what it must stay under or over.
	static inline var LEAST = 1e-6;
	// The least fovY, and how far under pi the most is.
	static inline var LEAST_FOV = 1e-3;

	var view = new Mat4();
	var projectionMatrix = new Mat4();
	var viewProjectionMatrix = new Mat4();
	var placed = new Mat4();
	// Where it is in the world and which way it looks, from placed: the eye, the unit forward (its -z) and up (its +y).
	var eye = [0., 0, 0];
	var forward = [0., 0, -1];
	var up = [0., 1, 0];

	/** A camera at 0, 0, 10 looking at the origin, +y up, perspective with a quarter turn (pi/4) of vertical view (an orthographic height of 10
		kept for when projection says so), clipping at 0.1 and 1000, on a 1 x 1 viewport. */
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

	/** Which projection draws, Perspective to start: a perspective view sees fovY, an orthographic one orthographicHeight, both kept whichever
		draws, with near and far either way. Perspective holds near above 0: switching to it with a near of 0 or less raises near to 1e-6, and far
		to 2e-6 when it was no more. */
	public var projection(default, set):Projection3D = Perspective;

	function set_projection(value:Projection3D):Projection3D {
		projection = value;
		if (value == Perspective && !(near > 0)) {
			near = LEAST;
			if (!(far > near))
				far = near + LEAST;
		}
		return value;
	}

	/** The perspective view's vertical field of view in radians, pi/4 to start: held from 0.001 to pi - 0.001, a value outside landing on
		the nearer bound (NaN on the lower). Drawn when projection is Perspective; drawnFovY is what the viewport's shape makes of it. */
	public var fovY(default, set):Float = Math.PI / 4;

	function set_fovY(value:Float):Float {
		value = value >= LEAST_FOV ? (value <= Math.PI - LEAST_FOV ? value : Math.PI - LEAST_FOV) : LEAST_FOV;
		fovY = value;
		return value;
	}

	/** The narrowest viewport shape (width / height) the view keeps its width at: on a narrower viewport its vertical view
		(fovY, or orthographicHeight) grows so it sees as far across as at this aspect. A scene framed for 16:9 (16 /
		9) shows all its width on a phone held upright, with more above and below (Godot's keep-width; Presentation's Expand, in 3D). 0,
		the default, for none; 0 or more (under 0, or NaN, is 0). */
	public var minAspect(default, set):Float = 0.;

	function set_minAspect(aspect:Float):Float {
		aspect = aspect >= 0 ? aspect : 0;
		minAspect = aspect;
		return aspect;
	}

	/** How far right of the viewport's center the view's axis lands, in halves of the viewport's width: 0, the default, at the center; 1 at its
		right edge, -1 its left. A lens shift (a view camera's rise and fall): the picture slides across without turning the camera, so what it
		looks at sits off-center (beside a panel, say) seen square on, the view as wide as before. Any finite value; NaN or an infinity is 0. */
	public var lensShiftX(default, set):Float = 0.;

	function set_lensShiftX(value:Float):Float {
		value = Math.isFinite(value) ? value : 0;
		lensShiftX = value;
		return value;
	}

	/** How far above the viewport's center the view's axis lands, in halves of the viewport's height: 0, the default, at the center; 1 at its
		top edge. As lensShiftX, up and down. Any finite value; NaN or an infinity is 0. */
	public var lensShiftY(default, set):Float = 0.;

	function set_lensShiftY(value:Float):Float {
		value = Math.isFinite(value) ? value : 0;
		lensShiftY = value;
		return value;
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

	/** The near clip plane's distance from the eye, 0.1 to start: held below far, one at or past far (or NaN) landing 1e-6 under it; a
		perspective view (projection) holds it above 0 too, one of 0 or less landing on 1e-6. An orthographic view's near may be 0 or less. Set
		far first when the new pair lies past the old one. */
	public var near(default, set):Float = .1;

	function set_near(value:Float):Float {
		if (!(value < far))
			value = far - LEAST;
		if (projection == Perspective && !(value > 0))
			value = LEAST;
		near = value;
		return value;
	}

	/** The far clip plane's distance from the eye, 1000 to start: held above near, one at or under near (or NaN) landing 1e-6 over it. Set
		near first when the new pair lies under the old one. */
	public var far(default, set):Float = 1000.;

	function set_far(value:Float):Float {
		if (!(value > near))
			value = near + LEAST;
		far = value;
		return value;
	}

	/** The orthographic view's height in world units seen top to bottom (the width by the viewport's shape), 10 to start: held above 0, one of
		0 or less (or NaN) landing on 1e-6. Drawn when projection is Orthographic; drawnHeight is what the viewport's shape makes of it. */
	public var orthographicHeight(default, set):Float = 10.;

	function set_orthographicHeight(value:Float):Float {
		value = value >= LEAST ? value : LEAST;
		orthographicHeight = value;
		return value;
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

	/** World to clip space, for the viewport's shape: the projection's matrix (its lens shift applied) * view, recomputed by each call, the view
		from where it is in the world now. */
	public var viewProjection(get, never):Mat4;

	function get_viewProjection():Mat4 {
		place();
		view.makeLookAt(eye[0], eye[1], eye[2], eye[0] + forward[0], eye[1] + forward[1], eye[2] + forward[2], up[0], up[1], up[2]);
		if (projection == Orthographic) {
			projectionMatrix.makeOrthographic(this.drawnHeight, viewportWidth / viewportHeight, near, far);
			// The shift added to x and y after the divide by w, which is 1.
			projectionMatrix.set(12, lensShiftX);
			projectionMatrix.set(13, lensShiftY);
		} else {
			projectionMatrix.makePerspective(this.drawnFovY, viewportWidth / viewportHeight, near, far);
			// The shift times w (-z in view space), so it holds after the divide at every depth.
			projectionMatrix.set(8, -lensShiftX);
			projectionMatrix.set(9, -lensShiftY);
		}
		viewProjectionMatrix.makeProduct(projectionMatrix, view);
		return viewProjectionMatrix;
	}

	/** The ray through framebuffer pixel x, y (from the framebuffer's top-left, as the pointer is) into out (a new one when not given),
		returned: from the near plane, away from the camera, through the same matrices the stage draws with (perspective or orthographic, the
		viewport's shape). Null, leaving out as it was, for a point outside the viewport area (a pointer off the window, -1, -1, among them).
		Given out, it allocates nothing. */
	public function computeRay(x:Float, y:Float, ?out:Ray3D):Null<Ray3D> {
		if (!(x >= viewportX && x < viewportX + viewportWidth && y >= viewportY && y < viewportY + viewportHeight))
			return null;
		// Normalized device coordinates: -1 to 1 across the viewport, y up.
		var nx = (x - viewportX) / viewportWidth * 2 - 1,
			ny = 1 - (y - viewportY) / viewportHeight * 2;
		if (!inverse.makeInverse(this.viewProjection))
			return null;
		var near = unproject(nx, ny, -1),
			nearX = near[0],
			nearY = near[1],
			nearZ = near[2];
		var far = unproject(nx, ny, 1);
		var ray = out != null ? out : new Ray3D();
		return ray.set(nearX, nearY, nearZ, far[0] - nearX, far[1] - nearY, far[2] - nearZ) ? ray : null;
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
