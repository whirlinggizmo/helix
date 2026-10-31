package helix.math;

import haxe.exceptions.NotImplementedException;

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
		throw new NotImplementedException();
	}

	/** Returns the volume a view-projection matrix shows: what lands inside GL's clip space, -1 to 1 on each axis.

		@param viewProjection  The view matrix composed with the projection (`Matrix3D.compose(view, projection)`).
		@param out  Optional. The frustum to fill; a new one when omitted.
		@return  The frustum. */
	public static function fromMatrix(viewProjection:Matrix3D, ?out:Frustum3D):Frustum3D {
		throw new NotImplementedException();
	}

	/** Sets this frustum to another's planes.

		@param other  The frustum to copy.
		@return  This frustum. */
	public function copyFrom(other:Frustum3D):Frustum3D {
		throw new NotImplementedException();
	}

	/** Returns whether a point is inside.

		@param x  The point's x, in the matrix's world units.
		@param y  The point's y.
		@param z  The point's z.
		@return  True when it is inside or on a plane. */
	public function contains(x:Float, y:Float, z:Float):Bool {
		throw new NotImplementedException();
	}

	/** Returns whether a sphere is at least partly inside.

		@param x  The center's x, in the matrix's world units.
		@param y  The center's y.
		@param z  The center's z.
		@param radius  The radius.
		@return  True when some of it may be inside. */
	public function intersectsSphere(x:Float, y:Float, z:Float, radius:Float):Bool {
		throw new NotImplementedException();
	}

	/** Returns whether a box is at least partly inside.

		An empty box is never inside.
		@param bounds  The box, in the matrix's world units.
		@return  True when some of it may be inside. */
	public function intersectsBounds(bounds:Bounds3D):Bool {
		throw new NotImplementedException();
	}
}
