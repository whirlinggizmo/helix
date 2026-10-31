package helix.math;

/** Represents a view of a 3D world: where it is and which way it looks (a `Transform3D`), and how it projects what it sees.

	It is steered by its transform as any object is: `transform.moveForward`, `yaw`, `pitch`, `orbit`, `lookAt`. Its scale is ignored,
	as a scaled view would stretch what it shows. The projection is perspective unless `orthographic` is set. The aspect, width over
	height, is passed to each call that projects rather than kept, since it changes with the window.

	```haxe
	var camera = new Camera3D();
	camera.transform.position.set(0, 2, 8);
	camera.transform.lookAt(0, 0, 0);
	var view = camera.computeViewMatrix(viewScratch);
	var projection = camera.computeProjectionMatrix(width / height, projectionScratch);
	``` */
class Camera3D {
	/** Gets where it is and which way it looks: down its -z, its +y up. */
	public final transform = new Transform3D();

	/** Gets or sets a value indicating whether it projects without perspective, things the same size however far; false until set. */
	public var orthographic = false;

	/** Gets or sets the field of view, top to bottom, in radians, for a perspective projection; pi / 4 until set. */
	public var fieldOfView = Math.PI / 4;

	/** Gets or sets how much it shows top to bottom, in world units, for an orthographic projection; 10 until set. */
	public var orthographicHeight = 10.;

	/** Gets or sets the nearest distance it shows, in world units; 0.1 until set. */
	public var near = .1;

	/** Gets or sets the farthest distance it shows, in world units; 1000 until set. */
	public var far = 1000.;

	/** Creates a camera at the origin looking down -z. */
	public function new() {}

	/** Sets this camera to another's transform and projection.

		@param other  The camera to copy.
		@return  This camera. */
	public function copyFrom(other:Camera3D):Camera3D {
		transform.copyFrom(other.transform);
		orthographic = other.orthographic;
		fieldOfView = other.fieldOfView;
		orthographicHeight = other.orthographicHeight;
		near = other.near;
		far = other.far;
		return this;
	}

	/** Returns the matrix that puts the world into the camera's space, its transform undone, its scale ignored.

		@param out  Optional. The matrix to write into; a new one when omitted.
		@return  The view matrix. */
	public function computeViewMatrix(?out:Matrix3D):Matrix3D {
		var position = transform.position,
			px = position.x,
			py = position.y,
			pz = position.z;
		var q = turned();
		// The rotation's transpose undoes it, and the position, turned back, moves the world the other way.
		var view = Matrix3D.fromQuaternion(q.x, q.y, q.z, q.w, out);
		view.transpose(view);
		var v = view.values;
		v[12] = -(v[0] * px + v[4] * py + v[8] * pz);
		v[13] = -(v[1] * px + v[5] * py + v[9] * pz);
		v[14] = -(v[2] * px + v[6] * py + v[10] * pz);
		return view;
	}

	/** Returns the matrix that projects the camera's space into GL's clip space (depth -1 to 1), which every helix-platform adapter takes.

		@param aspect  The view's width over its height.
		@param out  Optional. The matrix to write into; a new one when omitted.
		@return  The projection matrix. */
	public function computeProjectionMatrix(aspect:Float, ?out:Matrix3D):Matrix3D {
		if (!orthographic)
			return Matrix3D.fromPerspective(fieldOfView, aspect, near, far, out);
		var top = orthographicHeight / 2, right = top * aspect;
		return Matrix3D.fromOrthographic(-right, right, -top, top, near, far, out);
	}

	/** Returns what the camera sees, to test what is in view before drawing it.

		@param aspect  The view's width over its height.
		@param out  Optional. The frustum to write into; a new one when omitted.
		@return  The frustum, in world units. */
	public function computeFrustum(aspect:Float, ?out:Frustum3D):Frustum3D {
		var view = computeViewMatrix(shared());
		return Frustum3D.fromMatrix(view.append(computeProjectionMatrix(aspect, sharedProjection()), view), out);
	}

	/** Returns where a point in the world lands in the view, from -1 to 1 across and up, with its depth.

		A point behind a perspective camera has a depth past 1. One level with its position, which lands nowhere, gives infinities or NaN.
		@param x  The point's x, in world units.
		@param y  The point's y.
		@param z  The point's z.
		@param aspect  The view's width over its height.
		@param out  Optional. The vector to write into: x and y from -1 (left, bottom) to 1, z the depth from -1 (near) to 1 (far); a new
			one when omitted.
		@return  The point; outside -1 to 1 when it isn't in view. */
	public function project(x:Float, y:Float, z:Float, aspect:Float, ?out:Vector3D):Vector3D {
		var x = real(x), y = real(y), z = real(z);
		var view = computeViewMatrix(shared());
		var m = view.append(computeProjectionMatrix(aspect, sharedProjection()), view).values;
		var w = m[3] * x + m[7] * y + m[11] * z + m[15];
		var px = (m[0] * x + m[4] * y + m[8] * z + m[12]) / w,
			py = (m[1] * x + m[5] * y + m[9] * z + m[13]) / w,
			pz = (m[2] * x + m[6] * y + m[10] * z + m[14]) / w;
		return out == null ? new Vector3D(px, py, pz) : out.set(px, py, pz);
	}

	/** Returns the direction from the camera through a point in the view, as a pointer's ray to pick with.

		@param viewX  The point across the view, from -1 (left) to 1 (right).
		@param viewY  The point up the view, from -1 (bottom) to 1 (top).
		@param aspect  The view's width over its height.
		@param out  Optional. The vector to write into: the direction, of length 1, in world units; a new one when omitted.
		@return  The direction. For a perspective camera the ray starts at its position; for an orthographic one at that point on its
			near plane (`unprojectOrigin`). */
	public function unprojectDirection(viewX:Float, viewY:Float, aspect:Float, ?out:Vector3D):Vector3D {
		var q = turned();
		if (orthographic) {
			var forward = q.transformPoint(0, 0, -1, out);
			return forward.normalize(forward);
		}
		var tan = Trig.tan(fieldOfView / 2);
		var direction = q.transformPoint(real(viewX) * tan * aspect, real(viewY) * tan, -1, out);
		return direction.normalize(direction);
	}

	/** Returns where the ray through a point in the view starts: the camera's position for a perspective camera, the point on its near
		plane for an orthographic one.

		@param viewX  The point across the view, from -1 (left) to 1 (right).
		@param viewY  The point up the view, from -1 (bottom) to 1 (top).
		@param aspect  The view's width over its height.
		@param out  Optional. The vector to write into, in world units; a new one when omitted.
		@return  The ray's start. */
	public function unprojectOrigin(viewX:Float, viewY:Float, aspect:Float, ?out:Vector3D):Vector3D {
		var position = transform.position,
			px = position.x,
			py = position.y,
			pz = position.z;
		if (!orthographic)
			return out == null ? new Vector3D(px, py, pz) : out.set(px, py, pz);
		var top = orthographicHeight / 2;
		var origin = turned().transformPoint(real(viewX) * top * aspect, real(viewY) * top, -near, out);
		return origin.set(origin.x + px, origin.y + py, origin.z + pz);
	}

	// Its rotation made length 1, so a rotation set by hand still gives a rigid view.
	function turned():Quaternion3D {
		if (rotation == null)
			rotation = new Quaternion3D();
		return transform.rotation.normalize(rotation);
	}

	// The matrices and the rotation the methods go through, reused.
	static var rotation:Null<Quaternion3D> = null;

	static var matrix:Null<Matrix3D> = null;

	static var projection:Null<Matrix3D> = null;

	static function shared():Matrix3D {
		if (matrix == null)
			matrix = new Matrix3D();
		return matrix;
	}

	static function sharedProjection():Matrix3D {
		if (projection == null)
			projection = new Matrix3D();
		return projection;
	}

	// The interpreter keeps an Int passed for a Float as an Int and multiplies two such as Ints, overflowing; dividing makes it a Float.
	static inline function real(value:Float):Float {
		#if eval
		return value / 1;
		#else
		return value;
		#end
	}
}
