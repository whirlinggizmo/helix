package helix.geometry;

import helix.math.Matrix4;
import helix.math.Quaternion;
import helix.math.Transform3D;
import helix.math.Trig;
import helix.math.Vector3;

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
	public function computeViewMatrix(?out:Matrix4):Matrix4 {
		var position = transform.position,
			px = position.x,
			py = position.y,
			pz = position.z;
		var q = turned();
		// The rotation's transpose undoes it, and the position, turned back, moves the world the other way.
		var view = Matrix4.fromQuaternion(q.x, q.y, q.z, q.w, out);
		view.transpose(view);
		view.m12 = -(view.m0 * px + view.m4 * py + view.m8 * pz);
		view.m13 = -(view.m1 * px + view.m5 * py + view.m9 * pz);
		view.m14 = -(view.m2 * px + view.m6 * py + view.m10 * pz);
		return view;
	}

	/** Returns the matrix that projects the camera's space into GL's clip space (depth -1 to 1), which every helix-platform adapter uses.

		@param aspect  The view's width over its height.
		@param out  Optional. The matrix to write into; a new one when omitted.
		@return  The projection matrix. */
	public function computeProjectionMatrix(aspect:Float, ?out:Matrix4):Matrix4 {
		if (!orthographic)
			return Matrix4.fromPerspective(fieldOfView, aspect, near, far, out);
		var top = orthographicHeight / 2, right = top * aspect;
		return Matrix4.fromOrthographic(-right, right, -top, top, near, far, out);
	}

	/** Returns what the camera sees, to test what is in view before drawing it.

		@param aspect  The view's width over its height.
		@param out  Optional. The frustum to write into; a new one when omitted.
		@return  The frustum, in world units. */
	public function computeFrustum(aspect:Float, ?out:Frustum):Frustum {
		var view = computeViewMatrix(shared());
		return Frustum.fromMatrix(view.append(computeProjectionMatrix(aspect, sharedProjection()), view), out);
	}

	/** Returns where a point in the world lands in the view, from -1 to 1 across and up, with its depth.

		A point behind a perspective camera has a depth past 1. One level with its position, which lands nowhere, has infinities or NaN.
		@param x  The point's x, in world units.
		@param y  The point's y.
		@param z  The point's z.
		@param aspect  The view's width over its height.
		@param out  Optional. The vector to write into: x and y from -1 (left, bottom) to 1, z the depth from -1 (near) to 1 (far); a new
			one when omitted.
		@return  The point; outside -1 to 1 when it isn't in view. */
	public function project(x:Float, y:Float, z:Float, aspect:Float, ?out:Vector3):Vector3 {
		var x = real(x), y = real(y), z = real(z);
		var view = computeViewMatrix(shared());
		var m = view.append(computeProjectionMatrix(aspect, sharedProjection()), view);
		var w = m.m3 * x + m.m7 * y + m.m11 * z + m.m15;
		var px = (m.m0 * x + m.m4 * y + m.m8 * z + m.m12) / w,
			py = (m.m1 * x + m.m5 * y + m.m9 * z + m.m13) / w,
			pz = (m.m2 * x + m.m6 * y + m.m10 * z + m.m14) / w;
		return out == null ? new Vector3(px, py, pz) : out.set(px, py, pz);
	}

	/** Returns the ray from the camera through a point of its view, for picking: from the camera's position for a perspective camera,
		and from the point on its near plane, along its forward, for an orthographic one.

		@param viewX  The point's x, -1 at the view's left to 1 at its right.
		@param viewY  Its y, -1 at the bottom to 1 at the top.
		@param aspect  The view's width over its height.
		@param out  Optional. Set to the ray.
		@return  The ray, its direction of length 1. */
	public function computeRay(viewX:Float, viewY:Float, aspect:Float, ?out:Ray3D):Ray3D {
		if (out == null)
			out = new Ray3D();
		var q = turned(), position = transform.position, origin = out.origin, direction = out.direction;
		var px = position.x, py = position.y, pz = position.z;
		if (orthographic) {
			var top = orthographicHeight / 2;
			q.transformPoint(real(viewX) * top * aspect, real(viewY) * top, -near, origin);
			origin.set(origin.x + px, origin.y + py, origin.z + pz);
			q.transformPoint(0, 0, -1, direction);
		} else {
			origin.set(px, py, pz);
			var tan = Trig.tan(fieldOfView / 2);
			q.transformPoint(real(viewX) * tan * aspect, real(viewY) * tan, -1, direction);
		}
		direction.normalize(direction);
		return out;
	}

	// Its rotation made length 1, so a rotation set by hand still makes a rigid view.
	function turned():Quaternion {
		if (rotation == null)
			rotation = new Quaternion();
		return transform.rotation.normalize(rotation);
	}

	// The matrices and the rotation the methods go through, reused.
	static var rotation:Null<Quaternion> = null;

	static var matrix:Null<Matrix4> = null;

	static var projection:Null<Matrix4> = null;

	static function shared():Matrix4 {
		if (matrix == null)
			matrix = new Matrix4();
		return matrix;
	}

	static function sharedProjection():Matrix4 {
		if (projection == null)
			projection = new Matrix4();
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
