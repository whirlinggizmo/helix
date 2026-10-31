package helix.math;

/** Represents where an object is in 3 dimensions, which way it faces, and how large it is: a position, a rotation and a scale.

	Its own axes are its rotation's: -z is forward, +x right and +y up, as a camera looks down -z. Moving and turning are along and
	around those axes unless a method says otherwise, so a ship, a turret or a camera is steered the same way. The matrix that draws it
	scales, then rotates, then moves (`toMatrix`); a child's is its own composed with its parent's (`Matrix3D.compose`). It uses
	`Trig`, so a transform comes out the same on every target.

	```haxe
	var ship = new Transform3D();
	ship.position.set(0, 0, 10);
	ship.lookAt(0, 0, 0);
	ship.yaw(turnSpeed * dt);
	ship.moveForward(speed * dt);
	var model = ship.toMatrix(scratch);
	``` */
class Transform3D {
	/** Gets the position, in its parent's units; the origin until changed. */
	public final position = new Vector3D();

	/** Gets the rotation; the identity until changed. */
	public final rotation = new Quaternion3D();

	/** Gets the scale along its own axes; 1 on each until changed. */
	public final scale = new Vector3D(1, 1, 1);

	/** Creates a transform at the origin, facing -z, at scale 1. */
	public function new() {}

	/** Sets this transform to another's position, rotation and scale.

		@param other  The transform to copy.
		@return  This transform. */
	public function copyFrom(other:Transform3D):Transform3D {
		position.copyFrom(other.position);
		rotation.copyFrom(other.rotation);
		scale.copyFrom(other.scale);
		return this;
	}

	/** Puts it back at the origin, facing -z, at scale 1.

		@return  This transform. */
	public function makeIdentity():Transform3D {
		position.set(0, 0, 0);
		rotation.makeIdentity();
		scale.set(1, 1, 1);
		return this;
	}

	/** Returns the transform of a matrix: its position, rotation and scale.

		A matrix that shears gives the nearest rotation (its polar decomposition's) and the scale along that rotation's axes, the shear
		lost. One that mirrors gives an x scale less than 0, so the way it faces and its up are kept.
		@param matrix  The matrix.
		@param out  Optional. The transform to fill; a new one when omitted.
		@return  The transform. */
	public static function fromMatrix(matrix:Matrix3D, ?out:Transform3D):Transform3D {
		var v = matrix.values;
		var m = [for (i in [0, 1, 2, 4, 5, 6, 8, 9, 10]) real(v[i])];
		var u = nearestRotation(m);
		var rotationMatrix = shared(), r = rotationMatrix.values;
		for (column in 0...3)
			for (row in 0...3)
				r[column * 4 + row] = u[column * 3 + row];
		if (out == null)
			out = new Transform3D();
		out.position.set(v[12], v[13], v[14]);
		Quaternion3D.fromMatrix(rotationMatrix, out.rotation);
		out.scale.set(u[0] * m[0] + u[1] * m[1] + u[2] * m[2], u[3] * m[3] + u[4] * m[4] + u[5] * m[5], u[6] * m[6] + u[7] * m[7] + u[8] * m[8]);
		return out;
	}

	/** Returns the direction it faces, its -z, of length 1.

		@param out  Optional. The vector to write into; a new one when omitted.
		@return  The direction. */
	public function computeForward(?out:Vector3D):Vector3D {
		var forward = rotation.transformPoint(0, 0, -1, out);
		return forward.normalize(forward);
	}

	/** Returns its right, its +x, of length 1.

		@param out  Optional. The vector to write into; a new one when omitted.
		@return  The direction. */
	public function computeRight(?out:Vector3D):Vector3D {
		var right = rotation.transformPoint(1, 0, 0, out);
		return right.normalize(right);
	}

	/** Returns its up, its +y, of length 1.

		@param out  Optional. The vector to write into; a new one when omitted.
		@return  The direction. */
	public function computeUp(?out:Vector3D):Vector3D {
		var up = rotation.transformPoint(0, 1, 0, out);
		return up.normalize(up);
	}

	/** Moves it along the way it faces.

		@param distance  How far, in its parent's units; less than 0 moves it back.
		@param inWorldPlane  Optional. True to move along the ground, its forward with the height taken out, as a walking camera does;
			defaults to false.
		@return  This transform. */
	public function moveForward(distance:Float, inWorldPlane = false):Transform3D {
		var forward = computeForward(vector());
		if (inWorldPlane)
			forward.set(forward.x, 0, forward.z).normalize(forward);
		position.addScaled(forward, distance, position);
		return this;
	}

	/** Moves it to its right.

		@param distance  How far, in its parent's units; less than 0 moves it left.
		@param inWorldPlane  Optional. True to move along the ground, its right with the height taken out; defaults to false.
		@return  This transform. */
	public function moveRight(distance:Float, inWorldPlane = false):Transform3D {
		var right = computeRight(vector());
		if (inWorldPlane)
			right.set(right.x, 0, right.z).normalize(right);
		position.addScaled(right, distance, position);
		return this;
	}

	/** Moves it along its up.

		@param distance  How far, in its parent's units; less than 0 moves it down.
		@return  This transform. */
	public function moveUp(distance:Float):Transform3D {
		position.addScaled(computeUp(vector()), distance, position);
		return this;
	}

	/** Moves it toward a point or away from it, along the line between them, as a camera zooms on what it orbits.

		It stops short of the point rather than passing through it.
		@param x  The point's x.
		@param y  The point's y.
		@param z  The point's z.
		@param distance  How far nearer, in its parent's units; less than 0 moves it away.
		@param nearest  Optional. The least distance it keeps from the point; defaults to 0.001.
		@return  This transform. */
	public function moveToward(x:Float, y:Float, z:Float, distance:Float, nearest = .001):Transform3D {
		var dx = real(x) - position.x,
			dy = real(y) - position.y,
			dz = real(z) - position.z;
		var length = Math.sqrt(dx * dx + dy * dy + dz * dz);
		if (length == 0)
			return this;
		var step = distance;
		if (distance > 0) {
			if (step > length - nearest)
				step = length - nearest;
			if (step <= 0)
				return this;
		}
		position.set(position.x + dx / length * step, position.y + dy / length * step, position.z + dz / length * step);
		return this;
	}

	/** Turns it left or right, around its own up.

		@param radians  The angle; more than 0 turns it left.
		@return  This transform. */
	public function yaw(radians:Float):Transform3D {
		return turnOwn(0, 1, 0, radians);
	}

	/** Turns it to face higher or lower, around its own right.

		@param radians  The angle; more than 0 faces it higher.
		@param lock  Optional. True to stop 0.001 radians short of facing straight up or down, the world's +y or -y, as a camera's look
			stops, so it never turns over; defaults to false. Already past that, it turns only back toward level.
		@return  This transform. */
	public function pitch(radians:Float, lock = false):Transform3D {
		var angle = radians;
		if (lock)
			angle = lockedTurn(computeForward(vector()), computeRight(axis()), angle, Trig.cos(LOCK_MARGIN));
		return turnOwn(1, 0, 0, angle);
	}

	/** Tilts it around the way it faces.

		@param radians  The angle; more than 0 tilts it to the right.
		@return  This transform. */
	public function roll(radians:Float):Transform3D {
		return turnOwn(0, 0, -1, radians);
	}

	/** Turns it to face a point.

		A point at its position leaves it as it is.
		@param x  The point's x.
		@param y  The point's y.
		@param z  The point's z.
		@param upX  Optional. Which way up it is kept, x; defaults to 0.
		@param upY  Optional. Up's y; defaults to 1.
		@param upZ  Optional. Up's z; defaults to 0.
		@return  This transform. */
	public function lookAt(x:Float, y:Float, z:Float, upX = 0., upY = 1., upZ = 0.):Transform3D {
		var dx = real(x) - position.x,
			dy = real(y) - position.y,
			dz = real(z) - position.z;
		if (dx != 0 || dy != 0 || dz != 0)
			Quaternion3D.fromLookRotation(dx, dy, dz, upX, upY, upZ, rotation);
		return this;
	}

	/** Swings it around a point: its position and its rotation both, so whatever faced the point still does, as an orbiting camera
		moves.

		The yaw is around the world's up; the pitch around its own right.
		@param x  The point's x.
		@param y  The point's y.
		@param z  The point's z.
		@param yaw  The swing left or right, in radians; more than 0 turns it to the left, as `yaw` does, which carries it to its right
			around the point: counterclockwise seen from above.
		@param pitch  The swing up or down, in radians; more than 0 swings it upward.
		@param lock  Optional. True to stop 0.001 radians short of straight above or below the point, along the world's +y or -y, so it
			never turns over; defaults to false.
		@return  This transform. */
	public function orbit(x:Float, y:Float, z:Float, yaw:Float, pitch:Float, lock = false):Transform3D {
		var x = real(x), y = real(y), z = real(z);
		var offset = vector().set(position.x - x, position.y - y, position.z - z);
		// The yaw around the world's up, through the point: the offset and the rotation turned alike.
		var turn = Quaternion3D.fromAxisAngle(0, 1, 0, yaw, quaternion());
		turn.transformPoint(offset.x, offset.y, offset.z, offset);
		Quaternion3D.compose(rotation, turn, rotation);
		// The pitch around its own right: a swing upward turns the offset up and the transform down toward the point, a turn of -pitch.
		var right = computeRight(axis());
		var angle = -pitch;
		if (lock)
			angle = lockedTurn(offset, right, angle, Trig.cos(LOCK_MARGIN) * offset.length);
		Quaternion3D.fromAxisAngle(right.x, right.y, right.z, angle, turn);
		turn.transformPoint(offset.x, offset.y, offset.z, offset);
		Quaternion3D.compose(rotation, turn, rotation);
		rotation.normalize(rotation);
		position.set(x + offset.x, y + offset.y, z + offset.z);
		return this;
	}

	/** Returns a point in its own space put into its parent's: scaled, rotated, then moved.

		@param x  The point's x, in its own units.
		@param y  The point's y.
		@param z  The point's z.
		@param out  Optional. The vector to write into; a new one when omitted.
		@return  The point, in its parent's units. */
	public function transformPoint(x:Float, y:Float, z:Float, ?out:Vector3D):Vector3D {
		var px = position.x, py = position.y, pz = position.z;
		var point = rotation.transformPoint(real(x) * scale.x, real(y) * scale.y, real(z) * scale.z, out);
		return point.set(point.x + px, point.y + py, point.z + pz);
	}

	/** Returns the matrix that scales, rotates and then moves, to draw it with.

		@param out  Optional. The matrix to write into; a new one when omitted.
		@return  The matrix. */
	public function toMatrix(?out:Matrix3D):Matrix3D {
		var px = position.x, py = position.y, pz = position.z, sx = scale.x, sy = scale.y, sz = scale.z;
		var matrix = Matrix3D.fromQuaternion(rotation.x, rotation.y, rotation.z, rotation.w, out);
		var v = matrix.values;
		for (row in 0...3) {
			v[row] *= sx;
			v[4 + row] *= sy;
			v[8 + row] *= sz;
		}
		v[12] = px;
		v[13] = py;
		v[14] = pz;
		return matrix;
	}

	// How far short of straight up or down a locked pitch or orbit stops, in radians: rcamera's.
	static inline final LOCK_MARGIN = .001;

	// Turns it around one of its own axes.
	function turnOwn(axisX:Float, axisY:Float, axisZ:Float, radians:Float):Transform3D {
		Quaternion3D.compose(Quaternion3D.fromAxisAngle(axisX, axisY, axisZ, radians, quaternion()), rotation, rotation);
		rotation.normalize(rotation);
		return this;
	}

	// How far a turn of a vector around an axis of length 1 may go before its y passes a limit either way: the angle, or less. The
	// vector's y as it turns is base + a cos t + b sin t; where it crosses the limit going outward, the turn stops. One already past the
	// limit and going further doesn't turn.
	static function lockedTurn(vector:Vector3D, axis:Vector3D, angle:Float, limit:Float):Float {
		if (angle == 0)
			return 0;
		var along = axis.x * vector.x + axis.y * vector.y + axis.z * vector.z;
		var base = axis.y * along,
			a = vector.y - base,
			b = axis.z * vector.x - axis.x * vector.z;
		var sign = angle < 0 ? -1. : 1.;
		b *= sign;
		var amplitude = Math.sqrt(a * a + b * b);
		if (amplitude == 0)
			return angle;
		var start = base + a, phase = Trig.atan2(b, a), most = angle * sign;
		var high = (limit - base) / amplitude,
			low = (-limit - base) / amplitude;
		if (high < -1 || low > 1)
			return 0;
		if (high <= 1) {
			var crossing = start >= limit && b > 0 ? 0. : wrapped(phase - Trig.acos(high));
			if (crossing < most)
				most = crossing;
		}
		if (low >= -1) {
			var crossing = start <= -limit && b < 0 ? 0. : wrapped(phase + Trig.acos(low));
			if (crossing < most)
				most = crossing;
		}
		return most * sign;
	}

	// An angle put in 0 to 2 pi.
	static function wrapped(angle:Float):Float
		return angle - Math.floor(angle / (Math.PI * 2)) * Math.PI * 2;

	// The rotation nearest a 3 x 3 matrix, by columns, as 9 numbers by columns: its polar decomposition, by Newton's iteration (scaled,
	// so a matrix scaled very unevenly takes few steps), a mirror taken out of its x axis. A matrix that flattens has none of its own,
	// so its columns are made square to one another, longest first, and an axis it lacks is the cross product of the others.
	static function nearestRotation(m:Array<Float>):Array<Float> {
		var u = m.copy();
		var determinant = cofactors(u, cofactor);
		var flat = determinant == 0 || !Math.isFinite(determinant);
		if (!flat) {
			for (_ in 0...100) {
				var size = 0., inverseSize = 0.;
				for (i in 0...9) {
					size += u[i] * u[i];
					inverseSize += cofactor[i] * cofactor[i];
				}
				var gamma = Math.sqrt(Math.sqrt(inverseSize) / Math.abs(determinant) / Math.sqrt(size));
				var change = 0.;
				for (i in 0...9) {
					var next = (gamma * u[i] + cofactor[i] / (gamma * determinant)) / 2;
					change = Math.max(change, Math.abs(next - u[i]));
					u[i] = next;
				}
				if (change < 1e-15)
					break;
				determinant = cofactors(u, cofactor);
				if (determinant == 0 || !Math.isFinite(determinant)) {
					flat = true;
					break;
				}
			}
			if (!flat
				&& (m[0] * (m[4] * m[8] - m[5] * m[7]) - m[3] * (m[1] * m[8] - m[2] * m[7]) + m[6] * (m[1] * m[5] - m[2] * m[4])) < 0)
				for (i in 0...3)
					u[i] = -u[i];
		}
		if (flat) {
			u = m.copy();
			var lengths = [
				for (c in 0...3)
					Math.sqrt(u[c * 3] * u[c * 3] + u[c * 3 + 1] * u[c * 3 + 1] + u[c * 3 + 2] * u[c * 3 + 2])
			];
			var order = [0, 1, 2];
			order.sort((p, q) -> lengths[p] > lengths[q] ? -1 : lengths[p] < lengths[q] ? 1 : p - q);
			var first = order[0] * 3, second = order[1] * 3, third = order[2];
			if (lengths[order[0]] == 0) {
				u = [1., 0., 0., 0., 1., 0., 0., 0., 1.];
				return u;
			}
			for (i in 0...3)
				u[first + i] /= lengths[order[0]];
			var dot = u[first] * u[second] + u[first + 1] * u[second + 1] + u[first + 2] * u[second + 2];
			for (i in 0...3)
				u[second + i] -= dot * u[first + i];
			var length = Math.sqrt(u[second] * u[second] + u[second + 1] * u[second + 1] + u[second + 2] * u[second + 2]);
			if (length < 1e-12) {
				// Square to the first: the world axis it lies least along, its part along the first taken out.
				var ax = Math.abs(u[first]),
					ay = Math.abs(u[first + 1]),
					az = Math.abs(u[first + 2]);
				var pick = ax <= ay && ax <= az ? 0 : ay <= az ? 1 : 2;
				for (i in 0...3)
					u[second + i] = (i == pick ? 1 : 0) - u[first + pick] * u[first + i];
				length = Math.sqrt(u[second] * u[second] + u[second + 1] * u[second + 1] + u[second + 2] * u[second + 2]);
			}
			for (i in 0...3)
				u[second + i] /= length;
			// Right-handed: each axis the cross product of the next two.
			var p = ((third + 1) % 3) * 3, q = ((third + 2) % 3) * 3, r = third * 3;
			u[r] = u[p + 1] * u[q + 2] - u[p + 2] * u[q + 1];
			u[r + 1] = u[p + 2] * u[q] - u[p] * u[q + 2];
			u[r + 2] = u[p] * u[q + 1] - u[p + 1] * u[q];
		}
		return u;
	}

	// The matrix's inverse transposed times its determinant, into out: each column the cross product of the other two. Returns the
	// determinant.
	static function cofactors(u:Array<Float>, out:Array<Float>):Float {
		for (c in 0...3) {
			var p = ((c + 1) % 3) * 3, q = ((c + 2) % 3) * 3;
			out[c * 3] = u[p + 1] * u[q + 2] - u[p + 2] * u[q + 1];
			out[c * 3 + 1] = u[p + 2] * u[q] - u[p] * u[q + 2];
			out[c * 3 + 2] = u[p] * u[q + 1] - u[p + 1] * u[q];
		}
		return u[0] * out[0] + u[1] * out[1] + u[2] * out[2];
	}

	static final cofactor:Array<Float> = [for (_ in 0...9) 0.];

	// A matrix, a rotation and two vectors the methods go through, reused.
	static var matrix:Null<Matrix3D> = null;

	static var turn:Null<Quaternion3D> = null;

	static var scratch:Null<Vector3D> = null;

	static var scratchAxis:Null<Vector3D> = null;

	static function shared():Matrix3D {
		if (matrix == null)
			matrix = new Matrix3D();
		return matrix;
	}

	static function quaternion():Quaternion3D {
		if (turn == null)
			turn = new Quaternion3D();
		return turn;
	}

	static function vector():Vector3D {
		if (scratch == null)
			scratch = new Vector3D();
		return scratch;
	}

	static function axis():Vector3D {
		if (scratchAxis == null)
			scratchAxis = new Vector3D();
		return scratchAxis;
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
