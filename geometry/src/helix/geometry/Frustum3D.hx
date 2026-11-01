package helix.geometry;

import helix.math.Bounds3D;
import helix.math.Matrix3D;

/** Represents what a view sees: six planes bounding a volume, from any view-projection matrix.

	It answers whether something is in view, so what isn't can be skipped before it is drawn: a camera's (`Camera3D.computeFrustum`), a
	light's that casts shadows, or a box dragged out to pick with. Each test errs toward "in view": something near a corner outside it may
	be counted in, but nothing in it is counted out.

	```haxe
	camera.computeFrustum(aspect, frustum);
	for (thing in things)
		if (frustum.intersectsBounds(thing.bounds))
			draw(thing);
	``` */
class Frustum3D {
	/** Gets the planes' 24 numbers: left, right, bottom, top, near and far, each a, b, c and d, where a point (x, y, z) is on the inside
		when a x + b y + c z + d is 0 or more. Each plane's (a, b, c) is of length 1, so that sum is the distance from it. */
	public final planes:Array<Float> = [for (_ in 0...24) 0.];

	/** Creates a frustum that holds everything until it is set from a matrix (`fromMatrix`). */
	public function new() {
		for (plane in 0...6)
			planes[plane * 4 + 3] = 1;
	}

	/** Returns the volume a view-projection matrix shows: what lands inside GL's clip space, -1 to 1 on each axis.

		@param viewProjection  The view matrix composed with the projection (`Matrix3D.compose(view, projection)`).
		@param out  Optional. The frustum to fill; a new one when omitted.
		@return  The frustum. */
	public static function fromMatrix(viewProjection:Matrix3D, ?out:Frustum3D):Frustum3D {
		var m = viewProjection.values;
		if (out == null)
			out = new Frustum3D();
		var p = out.planes;
		// Each plane is the matrix's last row plus or minus another (Gribb and Hartmann's): left and right x, bottom and top y, near and far z.
		for (plane in 0...6) {
			var row = plane >> 1, side = plane & 1 == 0 ? 1. : -1.;
			for (column in 0...4)
				p[plane * 4 + column] = real(m[column * 4 + 3]) + side * m[column * 4 + row];
			var a = p[plane * 4], b = p[plane * 4 + 1], c = p[plane * 4 + 2];
			var length = Math.sqrt(a * a + b * b + c * c);
			if (length > 0)
				for (column in 0...4)
					p[plane * 4 + column] /= length;
		}
		return out;
	}

	/** Sets this frustum to another's planes.

		@param other  The frustum to copy.
		@return  This frustum. */
	public function copyFrom(other:Frustum3D):Frustum3D {
		for (i in 0...24)
			planes[i] = other.planes[i];
		return this;
	}

	/** Returns whether a point is inside.

		@param x  The point's x, in the matrix's world units.
		@param y  The point's y.
		@param z  The point's z.
		@return  True when it is inside or on a plane. */
	public function contains(x:Float, y:Float, z:Float):Bool {
		return intersectsSphere(x, y, z, 0);
	}

	/** Returns whether a sphere is at least partly inside.

		@param x  The center's x, in the matrix's world units.
		@param y  The center's y.
		@param z  The center's z.
		@param radius  The radius.
		@return  True when some of it may be inside. */
	public function intersectsSphere(x:Float, y:Float, z:Float, radius:Float):Bool {
		var p = planes, x = real(x), y = real(y), z = real(z);
		for (plane in 0...6) {
			var i = plane * 4;
			if (p[i] * x + p[i + 1] * y + p[i + 2] * z + p[i + 3] < -radius)
				return false;
		}
		return true;
	}

	/** Returns whether a box is at least partly inside.

		An empty box is never inside.
		@param bounds  The box, in the matrix's world units.
		@return  True when some of it may be inside. */
	public function intersectsBounds(bounds:Bounds3D):Bool {
		if (bounds.isEmpty)
			return false;
		var p = planes;
		// Against each plane, the box's corner farthest inside it: when even that is outside, all of the box is.
		for (plane in 0...6) {
			var i = plane * 4, a = p[i], b = p[i + 1], c = p[i + 2];
			if (a * (a >= 0 ? bounds.maxX : bounds.minX)
				+ b * (b >= 0 ? bounds.maxY : bounds.minY)
				+ c * (c >= 0 ? bounds.maxZ : bounds.minZ)
				+ p[i + 3] < 0)
				return false;
		}
		return true;
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
