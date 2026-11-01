package helix.geometry;

import helix.math.Bounds2D;
import helix.math.Matrix2D;
import helix.math.Transform2D;
import helix.math.Trig;
import helix.math.Vector2D;

/** Represents a view of a 2D world: where it looks and how it is turned (a `Transform2D`), how near it is, and where in the view the
	point it looks at shows.

	It is steered by its transform as any object is: `transform.moveForward`, `rotate`, `lookAt`. Turning it turns the world the other
	way in the view. Its transform's scale is ignored; `zoom` sizes what it shows. A view is measured in view units from its top left, y
	downward: the screen's pixels when it is drawn to the screen. The view matrix and the conversions use `Trig`, so they come out the
	same on every target, and `worldToView` and `viewToWorld` go through the view matrix, so a point picked is where it was drawn.

	raylib's `Camera2D` is one whose position is raylib's target, whose rotation is raylib's in radians and negated (raylib's turns the
	world, this one turns itself), and whose zoom and offset are raylib's.

	```haxe
	var camera = new Camera2D();
	camera.offset.set(width / 2, height / 2);
	camera.transform.position.copyFrom(player.position);
	camera.zoom = 2;
	var view = camera.computeViewMatrix(viewScratch);
	var shown = camera.computeBounds(width, height, boundsScratch);
	var pointed = camera.viewToWorld(mouseX, mouseY, pointerScratch);
	``` */
class Camera2D {
	/** Gets where it looks, in world units, and how it is turned, in radians; its scale is ignored. */
	public final transform = new Transform2D();

	/** Gets or sets how near it is: 1 until set. More than 1 shows less of the world, larger; less than 0 shows it turned half round.
		At 0 it shows nothing, and a point in the view has no place in the world (`viewToWorld`). */
	public var zoom = 1.;

	/** Gets where in the view its position shows, in view units from the view's top left; the top left until changed. Half the view's
		size centers it. */
	public final offset = new Vector2D();

	/** Creates a camera at the origin, unturned, at zoom 1, its position showing at the view's top left. */
	public function new() {}

	/** Sets this camera to another's transform, zoom and offset.

		@param other  The camera to copy.
		@return  This camera. */
	public function copyFrom(other:Camera2D):Camera2D {
		transform.copyFrom(other.transform);
		zoom = other.zoom;
		offset.copyFrom(other.offset);
		return this;
	}

	/** Returns the matrix that puts the world into the view: it moves the position to the origin, turns the world back by the rotation,
		scales it by the zoom, and moves it to the offset.

		@param out  Optional. The matrix to write into; a new one when omitted.
		@return  The view matrix, from world units to view units. */
	public function computeViewMatrix(?out:Matrix2D):Matrix2D {
		if (out == null)
			out = new Matrix2D();
		var position = transform.position;
		return Matrix2D.fromTranslation(-position.x, -position.y, out)
			.appendRotation(-transform.rotation, out)
			.appendScale(zoom, zoom, out)
			.appendTranslation(offset.x, offset.y, out);
	}

	/** Returns where a point in the world shows in the view.

		@param x  The point's x, in world units.
		@param y  The point's y.
		@param out  Optional. The vector to write into; a new one when omitted.
		@return  The point, in view units. */
	public function worldToView(x:Float, y:Float, ?out:Vector2D):Vector2D {
		return computeViewMatrix(shared()).transformPoint(x, y, out);
	}

	/** Returns where in the world a point in the view is, as a pointer picks.

		@param x  The point's x, in view units.
		@param y  The point's y.
		@param out  Optional. The vector to write into; a new one when omitted.
		@return  The point, in world units; null at zoom 0, where it has none, the out unchanged. */
	public function viewToWorld(x:Float, y:Float, ?out:Vector2D):Null<Vector2D> {
		var inverse = computeViewMatrix(shared()).invert(shared());
		return inverse == null ? null : inverse.transformPoint(x, y, out);
	}

	/** Returns the part of the world in a view of a size, to skip what is outside it before drawing.

		When the camera is turned, the box is the axis-aligned one that holds the turned view, so it holds a little more than is shown.
		@param viewWidth  The view's width, in view units.
		@param viewHeight  The view's height.
		@param out  Optional. The box to write into; a new one when omitted.
		@return  The box, in world units; empty at zoom 0, where nothing shows. */
	public function computeBounds(viewWidth:Float, viewHeight:Float, ?out:Bounds2D):Bounds2D {
		if (out == null)
			out = new Bounds2D();
		out.makeEmpty();
		var inverse = computeViewMatrix(shared()).invert(shared());
		if (inverse == null)
			return out;
		var a = inverse.a, b = inverse.b, c = inverse.c, d = inverse.d, tx = inverse.tx, ty = inverse.ty;
		return out.expand(tx, ty)
			.expand(a * viewWidth + tx, b * viewWidth + ty)
			.expand(c * viewHeight + tx, d * viewHeight + ty)
			.expand(a * viewWidth + c * viewHeight + tx, b * viewWidth + d * viewHeight + ty);
	}

	// A matrix the conversions and computeBounds go through, reused.
	static var matrix:Null<Matrix2D> = null;

	static function shared():Matrix2D {
		if (matrix == null)
			matrix = new Matrix2D();
		return matrix;
	}
}
