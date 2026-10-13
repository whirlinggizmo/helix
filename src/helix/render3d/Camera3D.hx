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

	/** A camera at 0, 0, 10 looking at the origin, +y up, a quarter turn (pi/4) of vertical view, clipping at 0.1 and 1000, on a 1 x 1 viewport. */
	public function new()
		setView(0, 0, 10, 0, 0, 0);

	/** Looks from eye at target; up gives the roll. False, changing nothing, when the eye is at the target or up is parallel to the view. */
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

	/** World to clip space, for the viewport's shape: projection * view, recomputed by each call. */
	public function getViewProjection():Mat4 {
		if (orthographicHeight > 0)
			projection.setOrthographic(orthographicHeight, viewportWidth / viewportHeight, near, far);
		else
			projection.setPerspective(fovY, viewportWidth / viewportHeight, near, far);
		viewProjection.setProduct(projection, view);
		return viewProjection;
	}
}
