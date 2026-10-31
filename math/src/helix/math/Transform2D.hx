package helix.math;

/** Represents where an object is in 2 dimensions, which way it faces, and how large it is: a position, a rotation and a scale.

	It faces along its own +x, so a rotation of 0 faces +x and a positive one turns toward +y, clockwise on screen where y grows downward.
	Moving and turning are along and around its own axes unless a method says otherwise, so a sprite, a turret or a 2D camera is steered
	the same way. The matrix that draws it scales, then rotates, then moves (`toMatrix`); a child's is its own composed with its parent's
	(`Matrix2D.compose`). It uses `Trig`, so a transform comes out the same on every target.

	```haxe
	var ship = new Transform2D();
	ship.position.set(100, 50);
	ship.lookAt(mouseX, mouseY);
	ship.moveForward(speed * dt);
	var model = ship.toMatrix(scratch);
	``` */
class Transform2D {
	/** Gets the position, in its parent's units; the origin until changed. */
	public final position = new Vector2D();

	/** Gets or sets the rotation in radians; 0, facing +x, until set. */
	public var rotation = 0.;

	/** Gets the scale along its own axes; 1 on each until changed. */
	public final scale = new Vector2D(1, 1);

	/** Creates a transform at the origin, facing +x, at scale 1. */
	public function new() {}

	/** Sets this transform to another's position, rotation and scale.

		@param other  The transform to copy.
		@return  This transform. */
	public function copyFrom(other:Transform2D):Transform2D {
		position.copyFrom(other.position);
		rotation = other.rotation;
		scale.copyFrom(other.scale);
		return this;
	}

	/** Puts it back at the origin, facing +x, at scale 1.

		@return  This transform. */
	public function makeIdentity():Transform2D {
		position.set(0, 0);
		rotation = 0.;
		scale.set(1, 1);
		return this;
	}

	/** Returns the transform a matrix places, scales and turns by.

		Its rotation and x scale are the matrix's x axis's, and its y scale what the y axis reaches across it, so a matrix that shears
		loses the shear, and one that mirrors gives a y scale less than 0.
		@param matrix  The matrix.
		@param out  Optional. The transform to write into; a new one when omitted.
		@return  The transform. */
	public static function fromMatrix(matrix:Matrix2D, ?out:Transform2D):Transform2D {
		var a = matrix.a, b = matrix.b, c = matrix.c, d = matrix.d;
		var scaleX = Math.sqrt(a * a + b * b);
		if (out == null)
			out = new Transform2D();
		out.position.set(matrix.tx, matrix.ty);
		if (scaleX == 0) {
			out.rotation = Trig.atan2(-c, d);
			out.scale.set(0, Math.sqrt(c * c + d * d));
		} else {
			out.rotation = Trig.atan2(b, a);
			out.scale.set(scaleX, (a * d - b * c) / scaleX);
		}
		return out;
	}

	/** Returns the direction it faces, of length 1.

		@param out  Optional. The vector to write into; a new one when omitted.
		@return  The direction. */
	public function computeForward(?out:Vector2D):Vector2D {
		return Vector2D.fromAngle(rotation, 1, out);
	}

	/** Returns its right, a quarter turn from forward toward +y, of length 1.

		@param out  Optional. The vector to write into; a new one when omitted.
		@return  The direction. */
	public function computeRight(?out:Vector2D):Vector2D {
		var cos = Trig.cos(rotation), sin = Trig.sin(rotation);
		return out == null ? new Vector2D(-sin, cos) : out.set(-sin, cos);
	}

	/** Moves it along the way it faces.

		@param distance  How far, in its parent's units; less than 0 moves it back.
		@return  This transform. */
	public function moveForward(distance:Float):Transform2D {
		position.set(position.x + Trig.cos(rotation) * distance, position.y + Trig.sin(rotation) * distance);
		return this;
	}

	/** Moves it to its right.

		@param distance  How far, in its parent's units; less than 0 moves it left.
		@return  This transform. */
	public function moveRight(distance:Float):Transform2D {
		position.set(position.x - Trig.sin(rotation) * distance, position.y + Trig.cos(rotation) * distance);
		return this;
	}

	/** Moves it toward a point or away from it, along the line between them.

		It stops short of the point rather than passing through it.
		@param x  The point's x.
		@param y  The point's y.
		@param distance  How far nearer, in its parent's units; less than 0 moves it away.
		@param nearest  Optional. The least distance it keeps from the point; defaults to 0.001.
		@return  This transform. */
	public function moveToward(x:Float, y:Float, distance:Float, nearest = .001):Transform2D {
		var dx = x - position.x, dy = y - position.y;
		var length = Math.sqrt(dx * dx + dy * dy);
		if (length == 0)
			return this;
		var step = distance;
		if (distance > 0) {
			if (step > length - nearest)
				step = length - nearest;
			if (step <= 0)
				return this;
		}
		position.set(position.x + dx / length * step, position.y + dy / length * step);
		return this;
	}

	/** Turns it.

		@param radians  The angle; more than 0 turns from +x toward +y.
		@return  This transform. */
	public function rotate(radians:Float):Transform2D {
		rotation += radians;
		return this;
	}

	/** Turns it to face a point.

		A point at its position leaves it as it is.
		@param x  The point's x.
		@param y  The point's y.
		@return  This transform. */
	public function lookAt(x:Float, y:Float):Transform2D {
		var dx = x - position.x, dy = y - position.y;
		if (dx != 0 || dy != 0)
			rotation = Trig.atan2(dy, dx);
		return this;
	}

	/** Swings it around a point: its position and its rotation both, so whatever faced the point still does.

		@param x  The point's x.
		@param y  The point's y.
		@param radians  The swing; more than 0 swings it from +x toward +y.
		@return  This transform. */
	public function orbit(x:Float, y:Float, radians:Float):Transform2D {
		var cos = Trig.cos(radians), sin = Trig.sin(radians);
		var dx = position.x - x, dy = position.y - y;
		position.set(x + dx * cos - dy * sin, y + dx * sin + dy * cos);
		rotation += radians;
		return this;
	}

	/** Returns a point in its own space put into its parent's: scaled, rotated, then moved.

		@param x  The point's x, in its own units.
		@param y  The point's y.
		@param out  Optional. The vector to write into; a new one when omitted.
		@return  The point, in its parent's units. */
	public function transformPoint(x:Float, y:Float, ?out:Vector2D):Vector2D {
		return toMatrix(shared()).transformPoint(x, y, out);
	}

	/** Returns the matrix that scales, rotates and then moves, to draw it with.

		@param out  Optional. The matrix to write into; a new one when omitted.
		@return  The matrix. */
	public function toMatrix(?out:Matrix2D):Matrix2D {
		var cos = Trig.cos(rotation),
			sin = Trig.sin(rotation),
			scaleX = scale.x,
			scaleY = scale.y;
		if (out == null)
			out = new Matrix2D();
		return out.set(cos * scaleX, sin * scaleX, -sin * scaleY, cos * scaleY, position.x, position.y);
	}

	// A matrix transformPoint goes through, reused.
	static var matrix:Null<Matrix2D> = null;

	static function shared():Matrix2D {
		if (matrix == null)
			matrix = new Matrix2D();
		return matrix;
	}
}
