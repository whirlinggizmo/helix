package helix.ray.raylib;

#if !macro
import helix.ray.*;
import helix.ray.Raylib.*;
import helix.ray.Rlgl.*;
import helix.math.Matrix3D;
import helix.ray.internal.DefaultFont;
import helix.ray.internal.Models;
import helix.ray.internal.Runtime;
import helix.ray.internal.Textures;
import helix.ray.raylib.RCore.*;
import helix.ray.raylib.RShapes.*;
import helix.ray.raylib.RTextures.*;
import helix.ray.raylib.RText.*;
import helix.ray.raylib.RModels.*;
import helix.ray.raylib.RAudio.*;
import helix.ray.raylib.RMath.*;
import helix.ray.raylib.RAsync.*;
import helix.ray.raylib.RRlgl.*;
#end

/** Holds raylib's rlgl (the matrix stack, immediate drawing and render state), written here; `Rlgl` forwards to each
	(`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.ray)
class RRlgl {
	#if !macro
	// ---- Matrices ----

	/** Chooses the matrix the next matrix calls change: `RL_MODELVIEW`, the view (or, between `rlPushMatrix` and `rlPopMatrix`, the
		transform the next vertices are moved by), or `RL_PROJECTION`.

		@param mode  The matrix (`RL_MODELVIEW` or `RL_PROJECTION`; `RL_TEXTURE` changes nothing). */
	static function rlMatrixMode(mode:Int):Void {
		matrixMode = mode;
	}

	/** Saves the current matrix, to go back to with `rlPopMatrix`. In `RL_MODELVIEW`, the matrix calls until then move the vertices drawn
		after them.

		@throws String  More than 32 saved at once, as rlgl allows. */
	static function rlPushMatrix():Void {
		if (stack.length >= RL_MAX_MATRIX_STACK_SIZE)
			throw "rlPushMatrix: matrix stack overflow (RL_MAX_MATRIX_STACK_SIZE)";
		if (matrixMode == RL_MODELVIEW)
			pushed = true;
		stack.push(new Matrix3D().copyFrom(current()));
	}

	/** Goes back to the matrix last saved by `rlPushMatrix`. */
	static function rlPopMatrix():Void {
		if (stack.length > 0)
			set(stack.pop());
		if (stack.length == 0 && matrixMode == RL_MODELVIEW) {
			pushed = false;
			Runtime.frame.transform = null;
		}
	}

	/** Makes the current matrix the identity. */
	static function rlLoadIdentity():Void {
		set(new Matrix3D());
	}

	/** Moves by an offset before the current matrix.

		@param x  The x offset.
		@param y  The y offset.
		@param z  The z offset. */
	static function rlTranslatef(x:Float, y:Float, z:Float):Void {
		apply(new Matrix3D().makeTranslation(x, y, z));
	}

	/** Turns about an axis before the current matrix.

		@param angle  The angle, in degrees.
		@param x  The axis's x.
		@param y  Its y.
		@param z  Its z. */
	static function rlRotatef(angle:Float, x:Float, y:Float, z:Float):Void {
		apply(new Matrix3D().makeRotation(x, y, z, angle * DEG2RAD));
	}

	/** Scales before the current matrix.

		@param x  The x scale.
		@param y  The y scale.
		@param z  The z scale. */
	static function rlScalef(x:Float, y:Float, z:Float):Void {
		apply(new Matrix3D().makeScale(x, y, z));
	}

	/** Applies a matrix before the current one.

		@param matf  The matrix's 16 numbers, by columns, as raylib's `MatrixToFloat` gives them. */
	static function rlMultMatrixf(matf:Array<Float>):Void {
		var m = new Matrix3D();
		for (i in 0...16)
			m.values[i] = matf[i];
		apply(m);
	}

	/** Applies an orthographic projection before the current matrix.

		@param left  The left plane.
		@param right  The right plane.
		@param bottom  The bottom plane.
		@param top  The top plane.
		@param znear  The near plane.
		@param zfar  The far plane. */
	static function rlOrtho(left:Float, right:Float, bottom:Float, top:Float, znear:Float, zfar:Float):Void {
		apply(new Matrix3D().makeOrthographic(left, right, bottom, top, znear, zfar));
	}

	/** Applies a perspective projection before the current matrix, by its near plane's edges.

		@param left  The near plane's left edge.
		@param right  Its right edge.
		@param bottom  Its bottom edge.
		@param top  Its top edge.
		@param znear  The near plane.
		@param zfar  The far plane. */
	static function rlFrustum(left:Float, right:Float, bottom:Float, top:Float, znear:Float, zfar:Float):Void {
		apply(new Matrix3D().makeFrustum(left, right, bottom, top, znear, zfar));
	}

	/** Returns the view: the screen's, `BeginMode2D`'s or `BeginMode3D`'s.

		@return  The matrix. */
	static function rlGetMatrixModelview():Matrix {
		return toMatrix(Runtime.frame.view);
	}

	/** Returns the projection.

		@return  The matrix. */
	static function rlGetMatrixProjection():Matrix {
		return toMatrix(Runtime.frame.projection);
	}

	/** Returns the transform `rlPushMatrix` started: the identity when none is pushed.

		@return  The matrix. */
	static function rlGetMatrixTransform():Matrix {
		return toMatrix(pushed ? transform : new Matrix3D());
	}

	/** Sets the view.

		@param view  The matrix. */
	static function rlSetMatrixModelview(view:Matrix):Void {
		Runtime.frame.cut();
		Runtime.frame.view = toMatrix3D(view);
	}

	/** Sets the projection.

		@param proj  The matrix. */
	static function rlSetMatrixProjection(proj:Matrix):Void {
		Runtime.frame.cut();
		Runtime.frame.projection = toMatrix3D(proj);
	}

	/** Returns the near plane rlgl's cameras use, 0.01.

		@return  The distance. */
	static function rlGetCullDistanceNear():Float {
		return RL_CULL_DISTANCE_NEAR;
	}

	/** Returns the far plane rlgl's cameras use, 1000.

		@return  The distance. */
	static function rlGetCullDistanceFar():Float {
		return RL_CULL_DISTANCE_FAR;
	}

	// ---- Immediate drawing ----

	/** Starts vertices: each 2 a line, 3 a triangle or 4 a quad, until `rlEnd`.

		@param mode  `RL_LINES`, `RL_TRIANGLES` or `RL_QUADS`. */
	static function rlBegin(mode:Int):Void {
		drawMode = mode;
		quad.resize(0);
	}

	/** Ends the vertices `rlBegin` started; a shape left short of its vertices isn't drawn. */
	static function rlEnd():Void {
		quad.resize(0);
	}

	/** Adds a vertex, with the color, texture coordinate and normal set last.

		@param x  The x.
		@param y  The y. */
	static function rlVertex2i(x:Int, y:Int):Void {
		rlVertex3f(x, y, 0);
	}

	/** Adds a vertex, with the color, texture coordinate and normal set last.

		@param x  The x.
		@param y  The y. */
	static function rlVertex2f(x:Float, y:Float):Void {
		rlVertex3f(x, y, 0);
	}

	/** Adds a vertex, with the color, texture coordinate and normal set last.

		@param x  The x.
		@param y  The y.
		@param z  The z. */
	static function rlVertex3f(x:Float, y:Float, z:Float):Void {
		if (drawMode != RL_QUADS) {
			Runtime.frame.vertex(texture(), drawMode == RL_LINES, x, y, z, u, v, color);
			return;
		}
		// A quad as two triangles, its first, second and third corners, then its first, third and fourth.
		quad.push([x, y, z, u, v, color.r, color.g, color.b, color.a]);
		if (quad.length < 4)
			return;
		for (corner in [0, 1, 2, 0, 2, 3]) {
			var q = quad[corner];
			Runtime.frame.vertex(texture(), false, q[0], q[1], q[2], q[3], q[4], new Color(Std.int(q[5]), Std.int(q[6]), Std.int(q[7]), Std.int(q[8])));
		}
		quad.resize(0);
	}

	/** Sets the next vertices' texture coordinate.

		@param x  The u.
		@param y  The v. */
	static function rlTexCoord2f(x:Float, y:Float):Void {
		u = x;
		v = y;
	}

	/** Sets the next vertices' normal.

		@param x  The x.
		@param y  The y.
		@param z  The z. */
	static function rlNormal3f(x:Float, y:Float, z:Float):Void {
		Runtime.frame.nx = x;
		Runtime.frame.ny = y;
		Runtime.frame.nz = z;
	}

	/** Sets the next vertices' color.

		@param r  The red, 0 to 255.
		@param g  The green.
		@param b  The blue.
		@param a  The alpha. */
	static function rlColor4ub(r:Int, g:Int, b:Int, a:Int):Void {
		color = new Color(r, g, b, a);
	}

	/** Sets the next vertices' color, opaque.

		@param x  The red, 0 to 1.
		@param y  The green.
		@param z  The blue. */
	static function rlColor3f(x:Float, y:Float, z:Float):Void {
		rlColor4f(x, y, z, 1);
	}

	/** Sets the next vertices' color.

		@param x  The red, 0 to 1.
		@param y  The green.
		@param z  The blue.
		@param w  The alpha. */
	static function rlColor4f(x:Float, y:Float, z:Float, w:Float):Void {
		color = new Color(Std.int(x * 255), Std.int(y * 255), Std.int(z * 255), Std.int(w * 255));
	}

	/** Sets the texture the next vertices draw with.

		@param id  The texture's id (`Texture2D.id`), or 0 for none. */
	static function rlSetTexture(id:Int):Void {
		textureId = id;
	}

	// ---- State ----

	/** Sets how the next draws blend, as `BeginBlendMode` does.

		@param mode  The mode (`RL_BLEND_*`, the same as `BLEND_*`). */
	static function rlSetBlendMode(mode:Int):Void {
		BeginBlendMode(mode);
	}

	/** Draws what is drawn so far before what comes next. Draws here are kept in the order they are asked for, so it changes nothing that
		is seen. */
	static function rlDrawRenderBatchActive():Void {
		Runtime.frame.cut();
	}

	/** Returns whether the next vertices would overflow rlgl's batch, which it then draws first. Draws here have no such limit.

		@param vCount  The vertices.
		@return  False. */
	static function rlCheckRenderBatchLimit(vCount:Int):Bool {
		return false;
	}

	static var matrixMode = RL_MODELVIEW;
	static var pushed = false;
	static final transform = new Matrix3D();
	static final stack:Array<Matrix3D> = [];
	static var drawMode = RL_TRIANGLES;
	static final quad:Array<Array<Float>> = [];
	static var u = 0.;
	static var v = 0.;
	static var color = new Color(255, 255, 255, 255);
	static var textureId = 0;

	// The matrix the matrix calls change now.
	static function current():Matrix3D {
		return matrixMode == RL_PROJECTION ? Runtime.frame.projection : pushed ? transform : Runtime.frame.view;
	}

	// Replaces the current matrix: the view or projection after the draws asked for so far, the transform at the next vertex.
	static function set(m:Matrix3D):Void {
		if (matrixMode == RL_PROJECTION) {
			Runtime.frame.cut();
			Runtime.frame.projection = new Matrix3D().copyFrom(m);
		} else if (matrixMode == RL_MODELVIEW && pushed) {
			transform.copyFrom(m);
			Runtime.frame.transform = transform;
		} else if (matrixMode == RL_MODELVIEW) {
			Runtime.frame.cut();
			Runtime.frame.view = new Matrix3D().copyFrom(m);
		}
	}

	// Applies a matrix before the current one, as rlgl multiplies them.
	static function apply(m:Matrix3D):Void {
		set(new Matrix3D().compose(m, current()));
	}

	static function texture():Int {
		var handle = textureId == 0 ? 0 : Textures.handle(textureId);
		return handle == 0 ? Runtime.frame.white : handle;
	}
	#end
}
