package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Rlgl.*;
import helix.math.Matrix3D;
import helix.raylib.internal.DefaultFont;
import helix.raylib.internal.Models;
import helix.raylib.internal.Runtime;
import helix.raylib.internal.Textures;
import helix.raylib.modules.RCore.*;
import helix.raylib.modules.RShapes.*;
import helix.raylib.modules.RTextures.*;
import helix.raylib.modules.RText.*;
import helix.raylib.modules.RModels.*;
import helix.raylib.modules.RAudio.*;
import helix.raylib.modules.RMath.*;
import helix.raylib.modules.RRlgl.*;
#end

/** Provides raylib's rlgl: the matrix stack, immediate drawing and render state.

	`Rlgl` forwards to each function, written by `tools/gen_raylib.py`. */
@:noCompletion
@:allow(helix.raylib)
class RRlgl {
	// The quads added here draw as sprites: the frame given its sprite shader as the module starts.
	static function __init__():Void {
		helix.raylib.internal.Sprites.register();
	}

	#if !macro
	// ---- Matrices ----

	/** Chooses the matrix the next matrix calls change.

		`RL_MODELVIEW` is the view, or between `rlPushMatrix` and `rlPopMatrix` the transform the next vertices are moved by.

		`RL_PROJECTION` is the projection.

		@param mode  The matrix, `RL_MODELVIEW` or `RL_PROJECTION`. `RL_TEXTURE` changes nothing. */
	static function rlMatrixMode(mode:Int):Void {
		matrixMode = mode;
	}

	/** Saves the current matrix, to go back to with `rlPopMatrix`.

		In `RL_MODELVIEW`, the matrix calls until `rlPopMatrix` move the vertices drawn after them.

		At most 32 are saved at once. A push past them saves nothing, changes nothing and logs an error. */
	static function rlPushMatrix():Void {
		if (stack.length >= RL_MAX_MATRIX_STACK_SIZE) {
			Runtime.log(LOG_ERROR, "RLGL: Matrix stack overflow (RL_MAX_MATRIX_STACK_SIZE)");
			return;
		}
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
		apply(Matrix3D.fromTranslation(x, y, z));
	}

	/** Turns about an axis before the current matrix.

		@param angle  The angle, in degrees.
		@param x  The axis's x.
		@param y  Its y.
		@param z  Its z. */
	static function rlRotatef(angle:Float, x:Float, y:Float, z:Float):Void {
		apply(Matrix3D.fromRotation(x, y, z, angle * DEG2RAD));
	}

	/** Scales before the current matrix.

		@param x  The x scale.
		@param y  The y scale.
		@param z  The z scale. */
	static function rlScalef(x:Float, y:Float, z:Float):Void {
		apply(Matrix3D.fromScale(x, y, z));
	}

	/** Applies a matrix before the current one.

		@param matf  The matrix's 16 numbers, by columns, as `MatrixToFloatV` gives them. */
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
		apply(Matrix3D.fromOrthographic(left, right, bottom, top, znear, zfar));
	}

	/** Applies a perspective projection before the current matrix, by its near plane's edges.

		@param left  The near plane's left edge.
		@param right  Its right edge.
		@param bottom  Its bottom edge.
		@param top  Its top edge.
		@param znear  The near plane.
		@param zfar  The far plane. */
	static function rlFrustum(left:Float, right:Float, bottom:Float, top:Float, znear:Float, zfar:Float):Void {
		apply(Matrix3D.fromFrustum(left, right, bottom, top, znear, zfar));
	}

	/** Returns the view, which is the screen's, `BeginMode2D`'s or `BeginMode3D`'s.

		@return  The matrix. */
	static function rlGetMatrixModelview():Matrix {
		return toMatrix(Runtime.frame.view);
	}

	/** Returns the projection.

		@return  The matrix. */
	static function rlGetMatrixProjection():Matrix {
		return toMatrix(Runtime.frame.projection);
	}

	/** Returns the transform `rlPushMatrix` started, or the identity when none is pushed.

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

	/** Returns the near distance cameras see from, 0.01 until `rlSetClipPlanes` sets it.

		@return  The distance. */
	static function rlGetCullDistanceNear():Float {
		return cullNear;
	}

	/** Returns the far distance cameras see to, 1000 until `rlSetClipPlanes` sets it.

		@return  The distance. */
	static function rlGetCullDistanceFar():Float {
		return cullFar;
	}

	// ---- Immediate drawing ----

	/** Starts adding vertices until `rlEnd`, each 2 a line, 3 a triangle or 4 a quad.

		A mode other than the last one's starts a new draw call, which takes the texture `rlSetTexture` last set and sets the white
		texture for the next. A second change of mode without another `rlSetTexture` then draws untextured.

		The same mode again keeps the draw call and its texture.

		@param mode  `RL_LINES`, `RL_TRIANGLES` or `RL_QUADS`. */
	static function rlBegin(mode:Int):Void {
		var f = Runtime.frame;
		if (f.drawMode != mode) {
			f.drawMode = mode;
			f.drawTexture = textureId;
			textureId = 0;
		}
		dropShortQuad();
	}

	/** Ends the vertices `rlBegin` started.

		A shape left short of its vertices isn't drawn. */
	static function rlEnd():Void {
		dropShortQuad();
	}

	// Removes the corners of a quad left short of four.
	static function dropShortQuad():Void {
		if (quadCorners > 0)
			Runtime.frame.dropVertices(quadCorners);
		quadCorners = 0;
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
		var mode = Runtime.frame.drawMode;
		// rlgl's modes are Frame's.
		Runtime.frame.vertex(texture(), mode, x, y, z, u, v, color);
		if (mode == RL_QUADS)
			quadCorners = (quadCorners + 1) % 4;
	}

	/** Sets the next vertices' texture coordinate.

		@param x  The u.
		@param y  The v. */
	static function rlTexCoord2f(x:Float, y:Float):Void {
		u = x;
		v = y;
	}

	/** Sets the next vertices' normal, made length 1.

		The transform `rlPushMatrix` started, when there is one, turns the normal.

		@param x  The x.
		@param y  The y.
		@param z  The z. */
	static function rlNormal3f(x:Float, y:Float, z:Float):Void {
		var nx = x, ny = y, nz = z;
		if (pushed) {
			var m = transform.values;
			nx = m[0] * x + m[4] * y + m[8] * z;
			ny = m[1] * x + m[5] * y + m[9] * z;
			nz = m[2] * x + m[6] * y + m[10] * z;
		}
		var length = Math.sqrt(nx * nx + ny * ny + nz * nz);
		if (length != 0) {
			var ilength = 1 / length;
			nx *= ilength;
			ny *= ilength;
			nz *= ilength;
		}
		Runtime.frame.nx = nx;
		Runtime.frame.ny = ny;
		Runtime.frame.nz = nz;
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

		The draw call the next change of mode (`rlBegin`) starts also draws with the texture.

		0 keeps the texture the next vertices have, and the next change of mode starts with the white texture.

		@param id  The texture's id (`Texture2D.id`), or 0 to keep the texture the next vertices have. */
	static function rlSetTexture(id:Int):Void {
		textureId = id;
		if (id != 0)
			Runtime.frame.drawTexture = id;
	}

	// ---- State ----

	/** Sets how the next draws blend, as `BeginBlendMode` does.

		@param mode  The mode (`RL_BLEND_*`, the same as `BLEND_*`). */
	static function rlSetBlendMode(mode:Int):Void {
		BeginBlendMode(mode);
	}

	/** Sets the GL factors and equation `RL_BLEND_CUSTOM` blends by, red, green, blue and alpha alike, as `glBlendFunc` and
		`glBlendEquation` take them. See `rlSetBlendFactorsSeparate` for blending color apart from alpha.

		The factors take effect at the next `rlSetBlendMode(RL_BLEND_CUSTOM)`, even in that mode already.

		A value GL doesn't have leaves the factors, or the equation, unchanged.

		raylib sets no blend color, so `RL_CONSTANT_COLOR` and `RL_CONSTANT_ALPHA` are 0 and their `RL_ONE_MINUS_` forms 1.

		@param glSrcFactor  The source's factor (`RL_ZERO`, `RL_ONE`, `RL_SRC_COLOR`, ...).
		@param glDstFactor  The destination's factor.
		@param glEquation  How they combine (`RL_FUNC_ADD`, `RL_FUNC_SUBTRACT`, `RL_FUNC_REVERSE_SUBTRACT`, `RL_MIN`, `RL_MAX`). */
	static function rlSetBlendFactors(glSrcFactor:Int, glDstFactor:Int, glEquation:Int):Void {
		var gl = Runtime.frame.customBlend;
		if (gl[0] == glSrcFactor && gl[1] == glDstFactor && gl[2] == glEquation)
			return;
		gl[0] = glSrcFactor;
		gl[1] = glDstFactor;
		gl[2] = glEquation;
		Runtime.frame.customBlendChanged = true;
	}

	/** Sets the GL factors and equations `RL_BLEND_CUSTOM_SEPARATE` blends by, for red, green and blue apart from alpha, as
		`glBlendFuncSeparate` and `glBlendEquationSeparate` take them. See `rlSetBlendFactors` for blending every channel alike.

		The factors take effect at the next `rlSetBlendMode(RL_BLEND_CUSTOM_SEPARATE)`, even in that mode already.

		@param glSrcRGB  The source color's factor.
		@param glDstRGB  The destination color's factor.
		@param glSrcAlpha  The source alpha's factor.
		@param glDstAlpha  The destination alpha's factor.
		@param glEqRGB  How the colors combine.
		@param glEqAlpha  How the alphas combine. */
	static function rlSetBlendFactorsSeparate(glSrcRGB:Int, glDstRGB:Int, glSrcAlpha:Int, glDstAlpha:Int, glEqRGB:Int, glEqAlpha:Int):Void {
		var gl = Runtime.frame.customBlend, given = [glSrcRGB, glDstRGB, glSrcAlpha, glDstAlpha, glEqRGB, glEqAlpha], same = true;
		for (i in 0...6)
			if (gl[3 + i] != given[i])
				same = false;
		if (same)
			return;
		for (i in 0...6)
			gl[3 + i] = given[i];
		Runtime.frame.customBlendChanged = true;
	}

	/** Sets which color channels the next draws write, as `glColorMask` does.

		The batch isn't drawn first, so the vertices waiting in it are masked too.

		`ClearBackground` clears every channel whatever the mask.

		@param r  Whether red is written.
		@param g  Whether green is written.
		@param b  Whether blue is written.
		@param a  Whether alpha is written. */
	static function rlColorMask(r:Bool, g:Bool, b:Bool, a:Bool):Void {
		state().colorMask = cast((r ? 1 : 0) | (g ? 2 : 0) | (b ? 4 : 0) | (a ? 8 : 0));
	}

	/** Draws the vertices waiting in rlgl's batch now, with the state as it is.

		rlgl's state calls don't draw the batch, so a program calls this before and after changing one for the shapes between.

		A change of mode, shader, blending, scissor or pass also draws the batch. */
	static function rlDrawRenderBatchActive():Void {
		Runtime.frame.cut();
	}

	/** Returns whether the next vertices would overflow rlgl's batch, which is never.

		The batch has no such limit and is drawn only as it is flushed (`rlDrawRenderBatchActive`).

		@param vCount  The vertices.
		@return  False. */
	static function rlCheckRenderBatchLimit(vCount:Int):Bool {
		return false;
	}

	/** Blends the next draws by the blend mode.

		On when raylib starts.

		The batch isn't drawn first, so the vertices waiting in it change too. See `rlDrawRenderBatchActive` for drawing them first. */
	static function rlEnableColorBlend():Void {
		state().colorBlend = true;
	}

	/** Stops blending the next draws, so they replace what is drawn there.

		The batch isn't drawn first, so the vertices waiting in it change too. See `rlDrawRenderBatchActive` for drawing them first. */
	static function rlDisableColorBlend():Void {
		state().colorBlend = false;
	}

	/** Tests the next draws' depth, keeping only what is as near as or nearer than what is drawn there.

		`BeginMode3D` turns the test on.

		The batch isn't drawn first, so the vertices waiting in it change too. See `rlDrawRenderBatchActive` for drawing them first. */
	static function rlEnableDepthTest():Void {
		state().depthTest = true;
	}

	/** Stops testing the next draws' depth.

		Off when raylib starts, and `EndMode3D` turns the test off.

		The batch isn't drawn first, so the vertices waiting in it change too. See `rlDrawRenderBatchActive` for drawing them first. */
	static function rlDisableDepthTest():Void {
		state().depthTest = false;
	}

	/** Lets the next draws that test depth write it.

		On when raylib starts.

		The batch isn't drawn first, so the vertices waiting in it change too. See `rlDrawRenderBatchActive` for drawing them first. */
	static function rlEnableDepthMask():Void {
		state().depthMask = true;
	}

	/** Stops the next draws writing depth, so what is drawn after isn't hidden by them.

		Used for drawing something see-through.

		The batch isn't drawn first, so the vertices waiting in it change too. See `rlDrawRenderBatchActive` for drawing them first. */
	static function rlDisableDepthMask():Void {
		state().depthMask = false;
	}

	/** Leaves out the backs of the next triangles, or the fronts by `rlSetCullFace`.

		On when raylib starts.

		A triangle's front is the side from which its corners run counterclockwise.

		The batch isn't drawn first, so the vertices waiting in it change too. See `rlDrawRenderBatchActive` for drawing them first. */
	static function rlEnableBackfaceCulling():Void {
		state().cull = true;
	}

	/** Draws both sides of the next triangles.

		The batch isn't drawn first, so the vertices waiting in it change too. See `rlDrawRenderBatchActive` for drawing them first. */
	static function rlDisableBackfaceCulling():Void {
		state().cull = false;
	}

	/** Chooses which side of triangles culling leaves out.

		The batch isn't drawn first, so the vertices waiting in it change too. See `rlDrawRenderBatchActive` for drawing them first.

		@param mode  The side, `RL_CULL_FACE_BACK` (the default) or `RL_CULL_FACE_FRONT`. */
	static function rlSetCullFace(mode:Int):Void {
		state().cullFront = mode == RL_CULL_FACE_FRONT;
	}

	/** Draws triangles as their edges from now on, as GL's line mode does. See `rlEnablePointMode` for drawing their corners.

		A model drawn after the call is drawn so at once, and the shapes in rlgl's batch when the batch is next drawn
		(`rlDrawRenderBatchActive`).

		Culling still leaves out the triangles GL would cull, by their facing on the screen. That facing ignores a shader that moves
		the vertices.

		Ends point mode.

		The batch isn't drawn first, so the vertices waiting in it change too. See `rlDrawRenderBatchActive` for drawing them first. */
	static function rlEnableWireMode():Void {
		var f = state();
		f.wire = true;
		f.pointRun = null;
		f.pointMesh = null;
	}

	/** Draws triangles as their corners from now on, one pixel each, as desktop GL's point mode does. See `rlEnableWireMode` for
		drawing their edges.

		A model drawn after the call is drawn so at once, each index of its triangles or, without indices, each vertex of its whole
		triangles. The triangles in rlgl's batch are drawn so when the batch is next drawn.

		Drawn as points on every backend.

		Lines are still drawn as lines.

		Culling still leaves out the triangles GL would cull, by their facing on the screen.

		A shader's own `gl_PointSize` is ignored. Every point is one pixel, the size every backend draws.

		`rlDisableWireMode` ends point mode, and `rlEnableWireMode` replaces it.

		The batch isn't drawn first, so the vertices waiting in it change too. See `rlDrawRenderBatchActive` for drawing them first. */
	static function rlEnablePointMode():Void {
		var f = state();
		f.wire = false;
		f.pointRun = f.pointsOfRun;
		f.pointMesh = f.pointsOfMesh;
	}

	/** Draws the next triangles filled, ending wire mode or point mode.

		Filled when raylib starts.

		The batch isn't drawn first, so the vertices waiting in it change too. See `rlDrawRenderBatchActive` for drawing them first. */
	static function rlDisableWireMode():Void {
		var f = state();
		f.wire = false;
		f.pointRun = null;
		f.pointMesh = null;
	}

	/** Clips the next draws to the rectangle `rlScissor` last set, or to the whole pass until one is set. */
	static function rlEnableScissorTest():Void {
		var f = state();
		if (scissorBox == null) {
			f.scissor = [0, 0, f.width, f.height];
			return;
		}
		// rlgl's box is in framebuffer pixels from the bottom left; the frame's in the pass's pixels from its top left.
		var b = scissorBox,
			sx = f.inTarget ? 1 : GetRenderWidth() / f.width,
			sy = f.inTarget ? 1 : GetRenderHeight() / f.height;
		f.scissor = [b[0] / sx, f.height - (b[1] + b[3]) / sy, b[2] / sx, b[3] / sy];
	}

	/** Stops clipping the next draws, as `EndScissorMode` does. */
	static function rlDisableScissorTest():Void {
		state().scissor = null;
	}

	/** Sets the rectangle that clips the next draws while the scissor test is on, in the framebuffer's pixels from its bottom left, as
		GL takes it. See `BeginScissorMode` for setting one from the top left in the screen's pixels.

		@param x  Its left edge.
		@param y  Its bottom edge, from the bottom.
		@param width  Its width.
		@param height  Its height. */
	static function rlScissor(x:Int, y:Int, width:Int, height:Int):Void {
		scissorBox = [x, y, width, height];
		if (Runtime.frame.scissor != null)
			rlEnableScissorTest();
	}

	/** Sets the rectangle the next draws fill, as GL takes it, until the next pass begins.

		The next pass (`BeginDrawing`, `BeginTextureMode`, `EndTextureMode`) fills the whole framebuffer again.

		The projection is unchanged, so what is drawn is squeezed into the rectangle.

		@param x  Its left edge, in framebuffer pixels.
		@param y  Its bottom edge, from the bottom.
		@param width  Its width.
		@param height  Its height. */
	static function rlViewport(x:Int, y:Int, width:Int, height:Int):Void {
		state().viewport = [x, y, width, height];
	}

	/** Sets the near and far distances for `BeginMode3D`'s cameras, and for the rays and projections of cameras after the call.

		@param nearPlane  The near distance, 0.01 until set.
		@param farPlane  The far distance, 1000 until set. */
	static function rlSetClipPlanes(nearPlane:Float, farPlane:Float):Void {
		cullNear = nearPlane;
		cullFar = farPlane;
	}

	/** Sets the color `rlClearScreenBuffers` clears to.

		@param r  Red, 0 to 255.
		@param g  Green.
		@param b  Blue.
		@param a  Alpha. */
	static function rlClearColor(r:Int, g:Int, b:Int, a:Int):Void {
		clearColor = (a & 255) << 24 | (r & 255) << 16 | (g & 255) << 8 | (b & 255);
	}

	/** Clears the color and depth of what is drawn into, the color to `rlClearColor`'s, black until set. See `ClearBackground` for
		clearing to a given color. */
	static function rlClearScreenBuffers():Void {
		Runtime.frame.clear(clearColor);
	}

	/** Sets the line width, which only `rlGetLineWidth` reads.

		Lines stay 1 pixel wide on every target, the only width GL 3.3's core profile and WebGL draw.

		@param width  The width, in pixels. */
	static function rlSetLineWidth(width:Float):Void {
		lineWidth = width;
	}

	/** Returns the width `rlSetLineWidth` last set, 1 until then.

		@return  The width. */
	static function rlGetLineWidth():Float {
		return lineWidth;
	}

	/** Asks for smoothed lines, which changes nothing on any target. See `FLAG_MSAA_4X_HINT` for smoothing every edge.

		GL 3.3's core profile and WebGL don't smooth lines. */
	static function rlEnableSmoothLines():Void {}

	/** Stops asking for smoothed lines, which changes nothing on any target. */
	static function rlDisableSmoothLines():Void {}

	/** Sets the width rlgl records for the framebuffer drawn into, until the next pass begins.

		Only `rlGetFramebufferWidth` reads the width. Drawing ignores it.

		`BeginTextureMode` and `EndTextureMode` set it too.

		@param width  The width, in pixels. */
	static function rlSetFramebufferWidth(width:Int):Void {
		framebufferWidth = width;
		framebufferPass = Runtime.frame.passCount;
	}

	/** Returns the width of what is drawn into, or the width `rlSetFramebufferWidth` set since this pass began.

		In `BeginTextureMode` the width is the render texture's. Otherwise it is the screen's, in framebuffer pixels.

		@return  The width. */
	static function rlGetFramebufferWidth():Int {
		var f = Runtime.frame;
		return framebufferPass == f.passCount ? framebufferWidth : f.inTarget ? Std.int(f.width) : GetRenderWidth();
	}

	/** Sets the height rlgl records for the framebuffer drawn into, until the next pass begins.

		Only `rlGetFramebufferHeight` reads the height. Drawing ignores it.

		@param height  The height, in pixels. */
	static function rlSetFramebufferHeight(height:Int):Void {
		framebufferHeight = height;
		framebufferPass = Runtime.frame.passCount;
	}

	/** Returns the height of what is drawn into, or the height `rlSetFramebufferHeight` set since this pass began, as
		`rlGetFramebufferWidth` returns the width.

		@return  The height. */
	static function rlGetFramebufferHeight():Int {
		var f = Runtime.frame;
		return framebufferPass == f.passCount ? framebufferHeight : f.inTarget ? Std.int(f.height) : GetRenderHeight();
	}

	/** Returns a pixel format's name as rlgl writes it in its log, such as "R8G8B8A8" for `RL_PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`.

		@param format  The format (`RL_PIXELFORMAT_*`).
		@return  The name, or "UNKNOWN" for another number. */
	static function rlGetPixelFormatName(format:Int):String {
		var names = [
			"GRAYSCALE",
			"GRAY_ALPHA",
			"R5G6B5",
			"R8G8B8",
			"R5G5B5A1",
			"R4G4B4A4",
			"R8G8B8A8",
			"R32",
			"R32G32B32",
			"R32G32B32A32",
			"R16",
			"R16G16B16",
			"R16G16B16A16",
			"DXT1_RGB",
			"DXT1_RGBA",
			"DXT3_RGBA",
			"DXT5_RGBA",
			"ETC1_RGB",
			"ETC2_RGB",
			"ETC2_RGBA",
			"PVRT_RGB",
			"PVRT_RGBA",
			"ASTC_4x4_RGBA",
			"ASTC_8x8_RGBA"
		];
		return format >= 1 && format <= names.length ? names[format - 1] : "UNKNOWN";
	}

	// ---- Stereo rendering ----

	/** Turns stereo rendering on, drawing each flush of the batch and each mesh twice, once for each eye. See `BeginVrStereoMode` for
		turning stereo on with a config's matrices.

		Starts at the next flush of the batch, the vertices already waiting in it included, and at the next mesh drawn.

		Eye 0 is drawn in the left half of what is drawn into, through its view offset and projection (`rlSetMatrixViewOffsetStereo`,
		`rlSetMatrixProjectionStereo`). Eye 1 is drawn in the right half.

		After the batch the viewport is the whole again. After a mesh the viewport stays the right half. */
	static function rlEnableStereoRender():Void {
		helix.raylib.internal.Stereo.enable(true);
	}

	/** Turns stereo rendering off, from the next flush of the batch and the next mesh drawn. */
	static function rlDisableStereoRender():Void {
		helix.raylib.internal.Stereo.enable(false);
	}

	/** Returns whether stereo rendering is on (`rlEnableStereoRender`).

		@return  True when it is. */
	static function rlIsStereoRenderEnabled():Bool {
		return helix.raylib.internal.Stereo.enabled;
	}

	/** Returns an eye's projection in stereo rendering, as `rlSetMatrixProjectionStereo` set it.

		Zero until set, and for an eye other than 0 or 1.

		@param eye  The eye: 0, drawn in the left half, or 1.
		@return  The matrix. */
	static function rlGetMatrixProjectionStereo(eye:Int):Matrix {
		return eye == 0 || eye == 1 ? toMatrix(helix.raylib.internal.Stereo.projections[eye]) : new Matrix();
	}

	/** Returns an eye's view offset in stereo rendering, as `rlSetMatrixViewOffsetStereo` set it.

		Zero until set, and for an eye other than 0 or 1.

		@param eye  The eye: 0, drawn in the left half, or 1.
		@return  The matrix. */
	static function rlGetMatrixViewOffsetStereo(eye:Int):Matrix {
		return eye == 0 || eye == 1 ? toMatrix(helix.raylib.internal.Stereo.offsets[eye]) : new Matrix();
	}

	/** Sets each eye's projection in stereo rendering, used in place of the projection from the batch's next flush.

		A mesh's mvp takes the eye's projection, while its `matProjection` stays the projection.

		@param right  Eye 0's projection, drawn in the left half (raylib names it the right).
		@param left  Eye 1's, drawn in the right half. */
	static function rlSetMatrixProjectionStereo(right:Matrix, left:Matrix):Void {
		helix.raylib.internal.Stereo.projections[0].copyFrom(toMatrix3D(right));
		helix.raylib.internal.Stereo.projections[1].copyFrom(toMatrix3D(left));
	}

	/** Sets each eye's view offset in stereo rendering, applied after the view from the batch's next flush and in a mesh's mvp.

		@param right  Eye 0's offset, drawn in the left half (raylib names it the right).
		@param left  Eye 1's, drawn in the right half. */
	static function rlSetMatrixViewOffsetStereo(right:Matrix, left:Matrix):Void {
		helix.raylib.internal.Stereo.offsets[0].copyFrom(toMatrix3D(right));
		helix.raylib.internal.Stereo.offsets[1].copyFrom(toMatrix3D(left));
	}

	// ---- rlgl's GL objects and GL itself, which helix-raylib draws without: each refuses to compile, saying what to use ----

	/** Refuses to compile on every target, replacing rlgl's `rlEnableVertexArray` (enabling a vertex array). See `UploadMesh` for
		uploading a mesh and `DrawMesh` for drawing one.

		@param vaoId  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlEnableVertexArray: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlEnableVertexArray(vaoId:Int):Bool {
		throw "rlEnableVertexArray is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlDisableVertexArray` (disabling a vertex array). See `UploadMesh` for
		uploading a mesh and `DrawMesh` for drawing one. */
	@:unsupported("rlDisableVertexArray: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlDisableVertexArray():Void {
		throw "rlDisableVertexArray is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlEnableVertexBuffer` (enabling a vertex buffer). See `UploadMesh` for
		uploading a mesh and `DrawMesh` for drawing one.

		@param id  As rlgl takes it. */
	@:unsupported("rlEnableVertexBuffer: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlEnableVertexBuffer(id:Int):Void {
		throw "rlEnableVertexBuffer is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlDisableVertexBuffer` (disabling a vertex buffer). See `UploadMesh` for
		uploading a mesh and `DrawMesh` for drawing one. */
	@:unsupported("rlDisableVertexBuffer: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlDisableVertexBuffer():Void {
		throw "rlDisableVertexBuffer is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlEnableVertexBufferElement` (enabling an element buffer). See
		`UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.

		@param id  As rlgl takes it. */
	@:unsupported("rlEnableVertexBufferElement: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlEnableVertexBufferElement(id:Int):Void {
		throw "rlEnableVertexBufferElement is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlDisableVertexBufferElement` (disabling an element buffer). See
		`UploadMesh` for uploading a mesh and `DrawMesh` for drawing one. */
	@:unsupported("rlDisableVertexBufferElement: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlDisableVertexBufferElement():Void {
		throw "rlDisableVertexBufferElement is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlEnableVertexAttribute` (enabling a vertex attribute). See `UploadMesh`
		for uploading a mesh and `DrawMesh` for drawing one.

		@param index  As rlgl takes it. */
	@:unsupported("rlEnableVertexAttribute: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlEnableVertexAttribute(index:Int):Void {
		throw "rlEnableVertexAttribute is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlDisableVertexAttribute` (disabling a vertex attribute). See
		`UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.

		@param index  As rlgl takes it. */
	@:unsupported("rlDisableVertexAttribute: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlDisableVertexAttribute(index:Int):Void {
		throw "rlDisableVertexAttribute is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlEnableStatePointer` (enabling an attribute state pointer). See
		`UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.

		@param vertexAttribType  As rlgl takes it.
		@param buffer  As rlgl takes it. */
	@:unsupported("rlEnableStatePointer: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlEnableStatePointer(vertexAttribType:Int, buffer:Dynamic):Void {
		throw "rlEnableStatePointer is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlDisableStatePointer` (disabling an attribute state pointer). See
		`UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.

		@param vertexAttribType  As rlgl takes it. */
	@:unsupported("rlDisableStatePointer: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlDisableStatePointer(vertexAttribType:Int):Void {
		throw "rlDisableStatePointer is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlActiveTextureSlot` (choosing a texture slot). See
		`LoadTextureFromImage` for making a texture and `rlSetTexture` for drawing vertices with one.

		@param slot  As rlgl takes it. */
	@:unsupported("rlActiveTextureSlot: Not supported: helix-raylib has no GL texture ids; a Texture2D is made with LoadTextureAsync,, or LoadTextureFromImage, set up with SetTextureFilter, and drawn with rlSetTexture or the drawing functions.")
	static function rlActiveTextureSlot(slot:Int):Void {
		throw "rlActiveTextureSlot is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlEnableTexture` (binding a texture). See `LoadTextureFromImage` for
		making a texture and `rlSetTexture` for drawing vertices with one.

		@param id  As rlgl takes it. */
	@:unsupported("rlEnableTexture: Not supported: helix-raylib has no GL texture ids; a Texture2D is made with LoadTextureAsync,, or LoadTextureFromImage, set up with SetTextureFilter, and drawn with rlSetTexture or the drawing functions.")
	static function rlEnableTexture(id:Int):Void {
		throw "rlEnableTexture is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlDisableTexture` (unbinding the texture). See `LoadTextureFromImage` for
		making a texture and `rlSetTexture` for drawing vertices with one. */
	@:unsupported("rlDisableTexture: Not supported: helix-raylib has no GL texture ids; a Texture2D is made with LoadTextureAsync,, or LoadTextureFromImage, set up with SetTextureFilter, and drawn with rlSetTexture or the drawing functions.")
	static function rlDisableTexture():Void {
		throw "rlDisableTexture is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlEnableTextureCubemap` (binding a cubemap). See `LoadTextureFromImage`
		for making a texture and `rlSetTexture` for drawing vertices with one.

		@param id  As rlgl takes it. */
	@:unsupported("rlEnableTextureCubemap: Not supported: helix-raylib has no GL texture ids; a Texture2D is made with LoadTextureAsync,, or LoadTextureFromImage, set up with SetTextureFilter, and drawn with rlSetTexture or the drawing functions.")
	static function rlEnableTextureCubemap(id:Int):Void {
		throw "rlEnableTextureCubemap is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlDisableTextureCubemap` (unbinding the cubemap). See
		`LoadTextureFromImage` for making a texture and `rlSetTexture` for drawing vertices with one. */
	@:unsupported("rlDisableTextureCubemap: Not supported: helix-raylib has no GL texture ids; a Texture2D is made with LoadTextureAsync,, or LoadTextureFromImage, set up with SetTextureFilter, and drawn with rlSetTexture or the drawing functions.")
	static function rlDisableTextureCubemap():Void {
		throw "rlDisableTextureCubemap is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlTextureParameters` (setting a texture's filter or wrap). See
		`LoadTextureFromImage` for making a texture and `rlSetTexture` for drawing vertices with one.

		@param id  As rlgl takes it.
		@param param  As rlgl takes it.
		@param value  As rlgl takes it. */
	@:unsupported("rlTextureParameters: Not supported: helix-raylib has no GL texture ids; a Texture2D is made with LoadTextureAsync,, or LoadTextureFromImage, set up with SetTextureFilter, and drawn with rlSetTexture or the drawing functions.")
	static function rlTextureParameters(id:Int, param:Int, value:Int):Void {
		throw "rlTextureParameters is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlCubemapParameters` (setting a cubemap's filter or wrap). See
		`LoadTextureFromImage` for making a texture and `rlSetTexture` for drawing vertices with one.

		@param id  As rlgl takes it.
		@param param  As rlgl takes it.
		@param value  As rlgl takes it. */
	@:unsupported("rlCubemapParameters: Not supported: helix-raylib has no GL texture ids; a Texture2D is made with LoadTextureAsync,, or LoadTextureFromImage, set up with SetTextureFilter, and drawn with rlSetTexture or the drawing functions.")
	static function rlCubemapParameters(id:Int, param:Int, value:Int):Void {
		throw "rlCubemapParameters is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlEnableShader` (binding a shader program). See `LoadCompiledShader` for making a
		shader and `BeginShaderMode` for drawing with one.

		@param id  As rlgl takes it. */
	@:unsupported("rlEnableShader: Not supported: helix-raylib has no GL shader ids; a Shader is compiled ahead of time and loaded by LoadCompiledShader, set with SetShaderValue, and used between BeginShaderMode and EndShaderMode.")
	static function rlEnableShader(id:Int):Void {
		throw "rlEnableShader is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlDisableShader` (unbinding the shader program). See `LoadCompiledShader` for
		making a shader and `BeginShaderMode` for drawing with one. */
	@:unsupported("rlDisableShader: Not supported: helix-raylib has no GL shader ids; a Shader is compiled ahead of time and loaded by LoadCompiledShader, set with SetShaderValue, and used between BeginShaderMode and EndShaderMode.")
	static function rlDisableShader():Void {
		throw "rlDisableShader is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlEnableFramebuffer` (binding a framebuffer). See `LoadRenderTexture` for
		making a render texture and `BeginTextureMode` for drawing into one.

		@param id  As rlgl takes it. */
	@:unsupported("rlEnableFramebuffer: Not supported: helix-raylib has no GL framebuffers; a RenderTexture2D is made with LoadRenderTexture and drawn into between BeginTextureMode and EndTextureMode.")
	static function rlEnableFramebuffer(id:Int):Void {
		throw "rlEnableFramebuffer is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlDisableFramebuffer` (going back to the default framebuffer). See
		`LoadRenderTexture` for making a render texture and `BeginTextureMode` for drawing into one. */
	@:unsupported("rlDisableFramebuffer: Not supported: helix-raylib has no GL framebuffers; a RenderTexture2D is made with LoadRenderTexture and drawn into between BeginTextureMode and EndTextureMode.")
	static function rlDisableFramebuffer():Void {
		throw "rlDisableFramebuffer is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlGetActiveFramebuffer` (getting the bound framebuffer). See
		`LoadRenderTexture` for making a render texture and `BeginTextureMode` for drawing into one.

		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlGetActiveFramebuffer: Not supported: helix-raylib has no GL framebuffers; a RenderTexture2D is made with LoadRenderTexture and drawn into between BeginTextureMode and EndTextureMode.")
	static function rlGetActiveFramebuffer():Int {
		throw "rlGetActiveFramebuffer is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlActiveDrawBuffers` (choosing several color buffers to draw into). See
		`LoadRenderTexture` for making a render texture and `BeginTextureMode` for drawing into one.

		@param count  As rlgl takes it. */
	@:unsupported("rlActiveDrawBuffers: Not supported: helix-raylib has no GL framebuffers; a RenderTexture2D is made with LoadRenderTexture and drawn into between BeginTextureMode and EndTextureMode.")
	static function rlActiveDrawBuffers(count:Int):Void {
		throw "rlActiveDrawBuffers is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlBlitFramebuffer` (copying the bound framebuffer to the main one). See
		`LoadRenderTexture` for making a render texture and `BeginTextureMode` for drawing into one.

		@param srcX  As rlgl takes it.
		@param srcY  As rlgl takes it.
		@param srcWidth  As rlgl takes it.
		@param srcHeight  As rlgl takes it.
		@param dstX  As rlgl takes it.
		@param dstY  As rlgl takes it.
		@param dstWidth  As rlgl takes it.
		@param dstHeight  As rlgl takes it.
		@param bufferMask  As rlgl takes it. */
	@:unsupported("rlBlitFramebuffer: Not supported: helix-raylib has no GL framebuffers; a RenderTexture2D is made with LoadRenderTexture and drawn into between BeginTextureMode and EndTextureMode.")
	static function rlBlitFramebuffer(srcX:Int, srcY:Int, srcWidth:Int, srcHeight:Int, dstX:Int, dstY:Int, dstWidth:Int, dstHeight:Int, bufferMask:Int):Void {
		throw "rlBlitFramebuffer is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlBindFramebuffer` (binding a framebuffer to a target). See
		`LoadRenderTexture` for making a render texture and `BeginTextureMode` for drawing into one.

		@param target  As rlgl takes it.
		@param framebuffer  As rlgl takes it. */
	@:unsupported("rlBindFramebuffer: Not supported: helix-raylib has no GL framebuffers; a RenderTexture2D is made with LoadRenderTexture and drawn into between BeginTextureMode and EndTextureMode.")
	static function rlBindFramebuffer(target:Int, framebuffer:Int):Void {
		throw "rlBindFramebuffer is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlCheckErrors` (logging OpenGL's error codes). See `InitWindow` for
		setting up what helix-raylib draws with. */
	@:unsupported("rlCheckErrors: Not supported: helix-raylib has no GL of its own: InitWindow and CloseWindow set up and close what it draws with.")
	static function rlCheckErrors():Void {
		throw "rlCheckErrors is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlglInit` (setting up rlgl's buffers, shaders, textures and state). See
		`InitWindow` for setting up what helix-raylib draws with.

		@param width  As rlgl takes it.
		@param height  As rlgl takes it. */
	@:unsupported("rlglInit: Not supported: helix-raylib has no GL of its own: InitWindow and CloseWindow set up and close what it draws with.")
	static function rlglInit(width:Int, height:Int):Void {
		throw "rlglInit is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlglClose` (closing rlgl's buffers, shaders and textures). See
		`InitWindow` for setting up what helix-raylib draws with. */
	@:unsupported("rlglClose: Not supported: helix-raylib has no GL of its own: InitWindow and CloseWindow set up and close what it draws with.")
	static function rlglClose():Void {
		throw "rlglClose is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlLoadExtensions` (loading OpenGL's extensions). See `InitWindow` for
		setting up what helix-raylib draws with.

		@param loader  As rlgl takes it. */
	@:unsupported("rlLoadExtensions: Not supported: helix-raylib has no GL of its own: InitWindow and CloseWindow set up and close what it draws with.")
	static function rlLoadExtensions(loader:Dynamic):Void {
		throw "rlLoadExtensions is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlGetVersion` (getting the OpenGL version). See `InitWindow` for setting
		up what helix-raylib draws with.

		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlGetVersion: Not supported: helix-raylib has no GL of its own: InitWindow and CloseWindow set up and close what it draws with.")
	static function rlGetVersion():Int {
		throw "rlGetVersion is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlGetTextureIdDefault` (getting the default texture's id). See
		`LoadTextureFromImage` for making a texture and `rlSetTexture` for drawing vertices with one.

		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlGetTextureIdDefault: Not supported: helix-raylib has no GL texture ids; a Texture2D is made with LoadTextureAsync,, or LoadTextureFromImage, set up with SetTextureFilter, and drawn with rlSetTexture or the drawing functions.")
	static function rlGetTextureIdDefault():Int {
		throw "rlGetTextureIdDefault is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlGetShaderIdDefault` (getting the default shader's id). See `LoadCompiledShader`
		for making a shader and `BeginShaderMode` for drawing with one.

		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlGetShaderIdDefault: Not supported: helix-raylib has no GL shader ids; a Shader is compiled ahead of time and loaded by LoadCompiledShader, set with SetShaderValue, and used between BeginShaderMode and EndShaderMode.")
	static function rlGetShaderIdDefault():Int {
		throw "rlGetShaderIdDefault is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlGetShaderLocsDefault` (getting the default shader's locations). See
		`LoadShader` for making a shader and `BeginShaderMode` for drawing with one.

		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlGetShaderLocsDefault: Not supported: helix-raylib has no GL shader ids; a Shader is compiled ahead of time and loaded by LoadCompiledShader, set with SetShaderValue, and used between BeginShaderMode and EndShaderMode.")
	static function rlGetShaderLocsDefault():Array<Int> {
		throw "rlGetShaderLocsDefault is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlLoadRenderBatch` (making a render batch). See `rlDrawRenderBatchActive`
		for drawing the frame's one batch.

		@param numBuffers  As rlgl takes it.
		@param bufferElements  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlLoadRenderBatch: Not supported: helix-raylib has no render batches of rlgl's; its frame keeps one batch, as rlgl's default one, drawn by rlDrawRenderBatchActive.")
	static function rlLoadRenderBatch(numBuffers:Int, bufferElements:Int):Dynamic {
		throw "rlLoadRenderBatch is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlUnloadRenderBatch` (unloading a render batch). See
		`rlDrawRenderBatchActive` for drawing the frame's one batch.

		@param batch  As rlgl takes it. */
	@:unsupported("rlUnloadRenderBatch: Not supported: helix-raylib has no render batches of rlgl's; its frame keeps one batch, as rlgl's default one, drawn by rlDrawRenderBatchActive.")
	static function rlUnloadRenderBatch(batch:Dynamic):Void {
		throw "rlUnloadRenderBatch is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlDrawRenderBatch` (drawing a render batch). See
		`rlDrawRenderBatchActive` for drawing the frame's one batch.

		@param batch  As rlgl takes it. */
	@:unsupported("rlDrawRenderBatch: Not supported: helix-raylib has no render batches of rlgl's; its frame keeps one batch, as rlgl's default one, drawn by rlDrawRenderBatchActive.")
	static function rlDrawRenderBatch(batch:Dynamic):Void {
		throw "rlDrawRenderBatch is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlSetRenderBatchActive` (choosing the render batch rlgl adds to). See
		`rlDrawRenderBatchActive` for drawing the frame's one batch.

		@param batch  As rlgl takes it. */
	@:unsupported("rlSetRenderBatchActive: Not supported: helix-raylib has no render batches of rlgl's; its frame keeps one batch, as rlgl's default one, drawn by rlDrawRenderBatchActive.")
	static function rlSetRenderBatchActive(batch:Dynamic):Void {
		throw "rlSetRenderBatchActive is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlLoadVertexArray` (making a vertex array). See `UploadMesh` for
		uploading a mesh and `DrawMesh` for drawing one.

		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlLoadVertexArray: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlLoadVertexArray():Int {
		throw "rlLoadVertexArray is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlLoadVertexBuffer` (making a vertex buffer). See `UploadMesh` for
		uploading a mesh and `DrawMesh` for drawing one.

		@param buffer  As rlgl takes it.
		@param size  As rlgl takes it.
		@param isDynamic  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlLoadVertexBuffer: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlLoadVertexBuffer(buffer:Dynamic, size:Int, isDynamic:Bool):Int {
		throw "rlLoadVertexBuffer is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlLoadVertexBufferElement` (making an element buffer). See `UploadMesh`
		for uploading a mesh and `DrawMesh` for drawing one.

		@param buffer  As rlgl takes it.
		@param size  As rlgl takes it.
		@param isDynamic  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlLoadVertexBufferElement: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlLoadVertexBufferElement(buffer:Dynamic, size:Int, isDynamic:Bool):Int {
		throw "rlLoadVertexBufferElement is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlUpdateVertexBuffer` (updating a vertex buffer's data). See `UploadMesh`
		for uploading a mesh and `DrawMesh` for drawing one.

		@param bufferId  As rlgl takes it.
		@param data  As rlgl takes it.
		@param dataSize  As rlgl takes it.
		@param offset  As rlgl takes it. */
	@:unsupported("rlUpdateVertexBuffer: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlUpdateVertexBuffer(bufferId:Int, data:Dynamic, dataSize:Int, offset:Int):Void {
		throw "rlUpdateVertexBuffer is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlUpdateVertexBufferElements` (updating an element buffer's data). See
		`UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.

		@param id  As rlgl takes it.
		@param data  As rlgl takes it.
		@param dataSize  As rlgl takes it.
		@param offset  As rlgl takes it. */
	@:unsupported("rlUpdateVertexBufferElements: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlUpdateVertexBufferElements(id:Int, data:Dynamic, dataSize:Int, offset:Int):Void {
		throw "rlUpdateVertexBufferElements is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlUnloadVertexArray` (unloading a vertex array). See `UploadMesh` for
		uploading a mesh and `DrawMesh` for drawing one.

		@param vaoId  As rlgl takes it. */
	@:unsupported("rlUnloadVertexArray: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlUnloadVertexArray(vaoId:Int):Void {
		throw "rlUnloadVertexArray is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlUnloadVertexBuffer` (unloading a vertex buffer). See `UploadMesh` for
		uploading a mesh and `DrawMesh` for drawing one.

		@param vboId  As rlgl takes it. */
	@:unsupported("rlUnloadVertexBuffer: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlUnloadVertexBuffer(vboId:Int):Void {
		throw "rlUnloadVertexBuffer is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlSetVertexAttribute` (setting a vertex attribute's layout). See
		`UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.

		@param index  As rlgl takes it.
		@param compSize  As rlgl takes it.
		@param type  As rlgl takes it.
		@param normalized  As rlgl takes it.
		@param stride  As rlgl takes it.
		@param offset  As rlgl takes it. */
	@:unsupported("rlSetVertexAttribute: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlSetVertexAttribute(index:Int, compSize:Int, type:Int, normalized:Bool, stride:Int, offset:Int):Void {
		throw "rlSetVertexAttribute is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlSetVertexAttributeDivisor` (setting a vertex attribute's divisor). See
		`UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.

		@param index  As rlgl takes it.
		@param divisor  As rlgl takes it. */
	@:unsupported("rlSetVertexAttributeDivisor: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlSetVertexAttributeDivisor(index:Int, divisor:Int):Void {
		throw "rlSetVertexAttributeDivisor is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlSetVertexAttributeDefault` (setting a vertex attribute's default
		value). See `UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.

		@param locIndex  As rlgl takes it.
		@param value  As rlgl takes it.
		@param attribType  As rlgl takes it.
		@param count  As rlgl takes it. */
	@:unsupported("rlSetVertexAttributeDefault: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlSetVertexAttributeDefault(locIndex:Int, value:Dynamic, attribType:Int, count:Int):Void {
		throw "rlSetVertexAttributeDefault is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlDrawVertexArray` (drawing the bound vertex array). See `UploadMesh` for
		uploading a mesh and `DrawMesh` for drawing one.

		@param offset  As rlgl takes it.
		@param count  As rlgl takes it. */
	@:unsupported("rlDrawVertexArray: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlDrawVertexArray(offset:Int, count:Int):Void {
		throw "rlDrawVertexArray is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlDrawVertexArrayElements` (drawing the bound vertex array's elements).
		See `UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.

		@param offset  As rlgl takes it.
		@param count  As rlgl takes it.
		@param buffer  As rlgl takes it. */
	@:unsupported("rlDrawVertexArrayElements: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlDrawVertexArrayElements(offset:Int, count:Int, buffer:Dynamic):Void {
		throw "rlDrawVertexArrayElements is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlDrawVertexArrayInstanced` (drawing instances of the bound vertex
		array). See `UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.

		@param offset  As rlgl takes it.
		@param count  As rlgl takes it.
		@param instances  As rlgl takes it. */
	@:unsupported("rlDrawVertexArrayInstanced: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlDrawVertexArrayInstanced(offset:Int, count:Int, instances:Int):Void {
		throw "rlDrawVertexArrayInstanced is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlDrawVertexArrayElementsInstanced` (drawing instances of the bound
		vertex array's elements). See `UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.

		@param offset  As rlgl takes it.
		@param count  As rlgl takes it.
		@param buffer  As rlgl takes it.
		@param instances  As rlgl takes it. */
	@:unsupported("rlDrawVertexArrayElementsInstanced: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlDrawVertexArrayElementsInstanced(offset:Int, count:Int, buffer:Dynamic, instances:Int):Void {
		throw "rlDrawVertexArrayElementsInstanced is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlLoadTexture` (making a texture from data). See `LoadTextureFromImage`
		for making a texture and `rlSetTexture` for drawing vertices with one.

		@param data  As rlgl takes it.
		@param width  As rlgl takes it.
		@param height  As rlgl takes it.
		@param format  As rlgl takes it.
		@param mipmapCount  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlLoadTexture: Not supported: helix-raylib has no GL texture ids; a Texture2D is made with LoadTextureAsync,, or LoadTextureFromImage, set up with SetTextureFilter, and drawn with rlSetTexture or the drawing functions.")
	static function rlLoadTexture(data:Dynamic, width:Int, height:Int, format:Int, mipmapCount:Int):Int {
		throw "rlLoadTexture is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlLoadTextureDepth` (making a depth texture or renderbuffer). See
		`LoadTextureFromImage` for making a texture and `rlSetTexture` for drawing vertices with one.

		@param width  As rlgl takes it.
		@param height  As rlgl takes it.
		@param useRenderBuffer  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlLoadTextureDepth: Not supported: helix-raylib has no GL texture ids; a Texture2D is made with LoadTextureAsync,, or LoadTextureFromImage, set up with SetTextureFilter, and drawn with rlSetTexture or the drawing functions.")
	static function rlLoadTextureDepth(width:Int, height:Int, useRenderBuffer:Bool):Int {
		throw "rlLoadTextureDepth is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlLoadTextureCubemap` (making a cubemap from data). See
		`LoadTextureFromImage` for making a texture and `rlSetTexture` for drawing vertices with one.

		@param data  As rlgl takes it.
		@param size  As rlgl takes it.
		@param format  As rlgl takes it.
		@param mipmapCount  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlLoadTextureCubemap: Not supported: helix-raylib has no GL texture ids; a Texture2D is made with LoadTextureAsync,, or LoadTextureFromImage, set up with SetTextureFilter, and drawn with rlSetTexture or the drawing functions.")
	static function rlLoadTextureCubemap(data:Dynamic, size:Int, format:Int, mipmapCount:Int):Int {
		throw "rlLoadTextureCubemap is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlUpdateTexture` (updating a texture's pixels). See
		`LoadTextureFromImage` for making a texture and `rlSetTexture` for drawing vertices with one.

		@param id  As rlgl takes it.
		@param offsetX  As rlgl takes it.
		@param offsetY  As rlgl takes it.
		@param width  As rlgl takes it.
		@param height  As rlgl takes it.
		@param format  As rlgl takes it.
		@param data  As rlgl takes it. */
	@:unsupported("rlUpdateTexture: Not supported: helix-raylib has no GL texture ids; a Texture2D is made with LoadTextureAsync,, or LoadTextureFromImage, set up with SetTextureFilter, and drawn with rlSetTexture or the drawing functions.")
	static function rlUpdateTexture(id:Int, offsetX:Int, offsetY:Int, width:Int, height:Int, format:Int, data:Dynamic):Void {
		throw "rlUpdateTexture is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlGetGlTextureFormats` (getting a format's OpenGL formats). See
		`LoadTextureFromImage` for making a texture and `rlSetTexture` for drawing vertices with one.

		@param format  As rlgl takes it.
		@param glInternalFormat  As rlgl takes it.
		@param glFormat  As rlgl takes it.
		@param glType  As rlgl takes it. */
	@:unsupported("rlGetGlTextureFormats: Not supported: helix-raylib has no GL texture ids; a Texture2D is made with LoadTextureAsync,, or LoadTextureFromImage, set up with SetTextureFilter, and drawn with rlSetTexture or the drawing functions.")
	static function rlGetGlTextureFormats(format:Int, glInternalFormat:Array<Int>, glFormat:Array<Int>, glType:Array<Int>):Void {
		throw "rlGetGlTextureFormats is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlUnloadTexture` (unloading a texture). See `LoadTextureFromImage` for
		making a texture and `rlSetTexture` for drawing vertices with one.

		@param id  As rlgl takes it. */
	@:unsupported("rlUnloadTexture: Not supported: helix-raylib has no GL texture ids; a Texture2D is made with LoadTextureAsync,, or LoadTextureFromImage, set up with SetTextureFilter, and drawn with rlSetTexture or the drawing functions.")
	static function rlUnloadTexture(id:Int):Void {
		throw "rlUnloadTexture is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlGenTextureMipmaps` (making a texture's mipmaps). See
		`LoadTextureFromImage` for making a texture and `rlSetTexture` for drawing vertices with one.

		@param id  As rlgl takes it.
		@param width  As rlgl takes it.
		@param height  As rlgl takes it.
		@param format  As rlgl takes it.
		@param mipmaps  As rlgl takes it. */
	@:unsupported("rlGenTextureMipmaps: Not supported: helix-raylib has no GL texture ids; a Texture2D is made with LoadTextureAsync,, or LoadTextureFromImage, set up with SetTextureFilter, and drawn with rlSetTexture or the drawing functions.")
	static function rlGenTextureMipmaps(id:Int, width:Int, height:Int, format:Int, mipmaps:Array<Int>):Void {
		throw "rlGenTextureMipmaps is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlReadTexturePixels` (reading a texture's pixels). See
		`LoadTextureFromImage` for making a texture and `rlSetTexture` for drawing vertices with one.

		@param id  As rlgl takes it.
		@param width  As rlgl takes it.
		@param height  As rlgl takes it.
		@param format  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlReadTexturePixels: Not supported: helix-raylib has no GL texture ids; a Texture2D is made with LoadTextureAsync,, or LoadTextureFromImage, set up with SetTextureFilter, and drawn with rlSetTexture or the drawing functions.")
	static function rlReadTexturePixels(id:Int, width:Int, height:Int, format:Int):Dynamic {
		throw "rlReadTexturePixels is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlReadScreenPixels` (reading the screen's pixels). See
		`LoadRenderTexture` for making a render texture and `BeginTextureMode` for drawing into one.

		@param width  As rlgl takes it.
		@param height  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlReadScreenPixels: Not supported: helix-raylib has no GL framebuffers; a RenderTexture2D is made with LoadRenderTexture and drawn into between BeginTextureMode and EndTextureMode.")
	static function rlReadScreenPixels(width:Int, height:Int):haxe.io.Bytes {
		throw "rlReadScreenPixels is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlLoadFramebuffer` (making an empty framebuffer). See `LoadRenderTexture`
		for making a render texture and `BeginTextureMode` for drawing into one.

		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlLoadFramebuffer: Not supported: helix-raylib has no GL framebuffers; a RenderTexture2D is made with LoadRenderTexture and drawn into between BeginTextureMode and EndTextureMode.")
	static function rlLoadFramebuffer():Int {
		throw "rlLoadFramebuffer is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlFramebufferAttach` (attaching a texture or renderbuffer to a
		framebuffer). See `LoadRenderTexture` for making a render texture and `BeginTextureMode` for drawing into one.

		@param fboId  As rlgl takes it.
		@param texId  As rlgl takes it.
		@param attachType  As rlgl takes it.
		@param texType  As rlgl takes it.
		@param mipLevel  As rlgl takes it. */
	@:unsupported("rlFramebufferAttach: Not supported: helix-raylib has no GL framebuffers; a RenderTexture2D is made with LoadRenderTexture and drawn into between BeginTextureMode and EndTextureMode.")
	static function rlFramebufferAttach(fboId:Int, texId:Int, attachType:Int, texType:Int, mipLevel:Int):Void {
		throw "rlFramebufferAttach is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlFramebufferComplete` (checking whether a framebuffer is complete). See
		`LoadRenderTexture` for making a render texture and `BeginTextureMode` for drawing into one.

		@param id  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlFramebufferComplete: Not supported: helix-raylib has no GL framebuffers; a RenderTexture2D is made with LoadRenderTexture and drawn into between BeginTextureMode and EndTextureMode.")
	static function rlFramebufferComplete(id:Int):Bool {
		throw "rlFramebufferComplete is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlUnloadFramebuffer` (unloading a framebuffer). See `LoadRenderTexture`
		for making a render texture and `BeginTextureMode` for drawing into one.

		@param id  As rlgl takes it. */
	@:unsupported("rlUnloadFramebuffer: Not supported: helix-raylib has no GL framebuffers; a RenderTexture2D is made with LoadRenderTexture and drawn into between BeginTextureMode and EndTextureMode.")
	static function rlUnloadFramebuffer(id:Int):Void {
		throw "rlUnloadFramebuffer is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlLoadShaderCode` (making a shader from source). See `LoadCompiledShader` for
		making a shader and `BeginShaderMode` for drawing with one.

		@param vsCode  As rlgl takes it.
		@param fsCode  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlLoadShaderCode: Not supported: helix-raylib has no GL shader ids; a Shader is compiled ahead of time and loaded by LoadCompiledShader, set with SetShaderValue, and used between BeginShaderMode and EndShaderMode.")
	static function rlLoadShaderCode(vsCode:String, fsCode:String):Int {
		throw "rlLoadShaderCode is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlCompileShader` (compiling one stage of a shader). See `LoadCompiledShader` for
		making a shader and `BeginShaderMode` for drawing with one.

		@param shaderCode  As rlgl takes it.
		@param type  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlCompileShader: Not supported: helix-raylib has no GL shader ids; a Shader is compiled ahead of time and loaded by LoadCompiledShader, set with SetShaderValue, and used between BeginShaderMode and EndShaderMode.")
	static function rlCompileShader(shaderCode:String, type:Int):Int {
		throw "rlCompileShader is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlLoadShaderProgram` (linking a shader program). See `LoadCompiledShader` for
		making a shader and `BeginShaderMode` for drawing with one.

		@param vShaderId  As rlgl takes it.
		@param fShaderId  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlLoadShaderProgram: Not supported: helix-raylib has no GL shader ids; a Shader is compiled ahead of time and loaded by LoadCompiledShader, set with SetShaderValue, and used between BeginShaderMode and EndShaderMode.")
	static function rlLoadShaderProgram(vShaderId:Int, fShaderId:Int):Int {
		throw "rlLoadShaderProgram is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlUnloadShaderProgram` (unloading a shader program). See `LoadCompiledShader` for
		making a shader and `BeginShaderMode` for drawing with one.

		@param id  As rlgl takes it. */
	@:unsupported("rlUnloadShaderProgram: Not supported: helix-raylib has no GL shader ids; a Shader is compiled ahead of time and loaded by LoadCompiledShader, set with SetShaderValue, and used between BeginShaderMode and EndShaderMode.")
	static function rlUnloadShaderProgram(id:Int):Void {
		throw "rlUnloadShaderProgram is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlGetLocationUniform` (finding a uniform's location). See `LoadCompiledShader`
		for making a shader and `BeginShaderMode` for drawing with one.

		@param shaderId  As rlgl takes it.
		@param uniformName  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlGetLocationUniform: Not supported: helix-raylib has no GL shader ids; a Shader is compiled ahead of time and loaded by LoadCompiledShader, set with SetShaderValue, and used between BeginShaderMode and EndShaderMode.")
	static function rlGetLocationUniform(shaderId:Int, uniformName:String):Int {
		throw "rlGetLocationUniform is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlGetLocationAttrib` (finding an attribute's location). See `LoadCompiledShader`
		for making a shader and `BeginShaderMode` for drawing with one.

		@param shaderId  As rlgl takes it.
		@param attribName  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlGetLocationAttrib: Not supported: helix-raylib has no GL shader ids; a Shader is compiled ahead of time and loaded by LoadCompiledShader, set with SetShaderValue, and used between BeginShaderMode and EndShaderMode.")
	static function rlGetLocationAttrib(shaderId:Int, attribName:String):Int {
		throw "rlGetLocationAttrib is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlSetUniform` (setting a uniform's value). See `LoadCompiledShader` for making a
		shader and `BeginShaderMode` for drawing with one.

		@param locIndex  As rlgl takes it.
		@param value  As rlgl takes it.
		@param uniformType  As rlgl takes it.
		@param count  As rlgl takes it. */
	@:unsupported("rlSetUniform: Not supported: helix-raylib has no GL shader ids; a Shader is compiled ahead of time and loaded by LoadCompiledShader, set with SetShaderValue, and used between BeginShaderMode and EndShaderMode.")
	static function rlSetUniform(locIndex:Int, value:Dynamic, uniformType:Int, count:Int):Void {
		throw "rlSetUniform is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlSetUniformMatrix` (setting a matrix uniform). See `LoadCompiledShader` for
		making a shader and `BeginShaderMode` for drawing with one.

		@param locIndex  As rlgl takes it.
		@param mat  As rlgl takes it. */
	@:unsupported("rlSetUniformMatrix: Not supported: helix-raylib has no GL shader ids; a Shader is compiled ahead of time and loaded by LoadCompiledShader, set with SetShaderValue, and used between BeginShaderMode and EndShaderMode.")
	static function rlSetUniformMatrix(locIndex:Int, mat:Matrix):Void {
		throw "rlSetUniformMatrix is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlSetUniformMatrices` (setting an array of matrix uniforms). See
		`LoadShader` for making a shader and `BeginShaderMode` for drawing with one.

		@param locIndex  As rlgl takes it.
		@param mat  As rlgl takes it.
		@param count  As rlgl takes it. */
	@:unsupported("rlSetUniformMatrices: Not supported: helix-raylib has no GL shader ids; a Shader is compiled ahead of time and loaded by LoadCompiledShader, set with SetShaderValue, and used between BeginShaderMode and EndShaderMode.")
	static function rlSetUniformMatrices(locIndex:Int, mat:Array<Matrix>, count:Int):Void {
		throw "rlSetUniformMatrices is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlSetUniformSampler` (setting a sampler uniform). See `LoadCompiledShader` for
		making a shader and `BeginShaderMode` for drawing with one.

		@param locIndex  As rlgl takes it.
		@param textureId  As rlgl takes it. */
	@:unsupported("rlSetUniformSampler: Not supported: helix-raylib has no GL shader ids; a Shader is compiled ahead of time and loaded by LoadCompiledShader, set with SetShaderValue, and used between BeginShaderMode and EndShaderMode.")
	static function rlSetUniformSampler(locIndex:Int, textureId:Int):Void {
		throw "rlSetUniformSampler is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlSetShader` (choosing the shader rlgl draws with). See `LoadCompiledShader` for
		making a shader and `BeginShaderMode` for drawing with one.

		@param id  As rlgl takes it.
		@param locs  As rlgl takes it. */
	@:unsupported("rlSetShader: Not supported: helix-raylib has no GL shader ids; a Shader is compiled ahead of time and loaded by LoadCompiledShader, set with SetShaderValue, and used between BeginShaderMode and EndShaderMode.")
	static function rlSetShader(id:Int, locs:Array<Int>):Void {
		throw "rlSetShader is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlLoadComputeShaderProgram` (making a compute shader program).

		No target has compute shaders or shader storage buffers, as WebGL2 has none.

		@param shaderId  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlLoadComputeShaderProgram: Not supported: helix-raylib has no compute shaders or shader storage buffers, as WebGL2 has none.")
	static function rlLoadComputeShaderProgram(shaderId:Int):Int {
		throw "rlLoadComputeShaderProgram is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlComputeShaderDispatch` (running a compute shader).

		No target has compute shaders or shader storage buffers, as WebGL2 has none.

		@param groupX  As rlgl takes it.
		@param groupY  As rlgl takes it.
		@param groupZ  As rlgl takes it. */
	@:unsupported("rlComputeShaderDispatch: Not supported: helix-raylib has no compute shaders or shader storage buffers, as WebGL2 has none.")
	static function rlComputeShaderDispatch(groupX:Int, groupY:Int, groupZ:Int):Void {
		throw "rlComputeShaderDispatch is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlLoadShaderBuffer` (making a shader storage buffer).

		No target has compute shaders or shader storage buffers, as WebGL2 has none.

		@param size  As rlgl takes it.
		@param data  As rlgl takes it.
		@param usageHint  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlLoadShaderBuffer: Not supported: helix-raylib has no compute shaders or shader storage buffers, as WebGL2 has none.")
	static function rlLoadShaderBuffer(size:Int, data:Dynamic, usageHint:Int):Int {
		throw "rlLoadShaderBuffer is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlUnloadShaderBuffer` (unloading a shader storage buffer).

		No target has compute shaders or shader storage buffers, as WebGL2 has none.

		@param ssboId  As rlgl takes it. */
	@:unsupported("rlUnloadShaderBuffer: Not supported: helix-raylib has no compute shaders or shader storage buffers, as WebGL2 has none.")
	static function rlUnloadShaderBuffer(ssboId:Int):Void {
		throw "rlUnloadShaderBuffer is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlUpdateShaderBuffer` (updating a shader storage buffer's data).

		No target has compute shaders or shader storage buffers, as WebGL2 has none.

		@param id  As rlgl takes it.
		@param data  As rlgl takes it.
		@param dataSize  As rlgl takes it.
		@param offset  As rlgl takes it. */
	@:unsupported("rlUpdateShaderBuffer: Not supported: helix-raylib has no compute shaders or shader storage buffers, as WebGL2 has none.")
	static function rlUpdateShaderBuffer(id:Int, data:Dynamic, dataSize:Int, offset:Int):Void {
		throw "rlUpdateShaderBuffer is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlBindShaderBuffer` (binding a shader storage buffer).

		No target has compute shaders or shader storage buffers, as WebGL2 has none.

		@param id  As rlgl takes it.
		@param index  As rlgl takes it. */
	@:unsupported("rlBindShaderBuffer: Not supported: helix-raylib has no compute shaders or shader storage buffers, as WebGL2 has none.")
	static function rlBindShaderBuffer(id:Int, index:Int):Void {
		throw "rlBindShaderBuffer is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlReadShaderBuffer` (reading a shader storage buffer's data).

		No target has compute shaders or shader storage buffers, as WebGL2 has none.

		@param id  As rlgl takes it.
		@param dest  As rlgl takes it.
		@param count  As rlgl takes it.
		@param offset  As rlgl takes it. */
	@:unsupported("rlReadShaderBuffer: Not supported: helix-raylib has no compute shaders or shader storage buffers, as WebGL2 has none.")
	static function rlReadShaderBuffer(id:Int, dest:Dynamic, count:Int, offset:Int):Void {
		throw "rlReadShaderBuffer is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlCopyShaderBuffer` (copying between shader storage buffers).

		No target has compute shaders or shader storage buffers, as WebGL2 has none.

		@param destId  As rlgl takes it.
		@param srcId  As rlgl takes it.
		@param destOffset  As rlgl takes it.
		@param srcOffset  As rlgl takes it.
		@param count  As rlgl takes it. */
	@:unsupported("rlCopyShaderBuffer: Not supported: helix-raylib has no compute shaders or shader storage buffers, as WebGL2 has none.")
	static function rlCopyShaderBuffer(destId:Int, srcId:Int, destOffset:Int, srcOffset:Int, count:Int):Void {
		throw "rlCopyShaderBuffer is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlGetShaderBufferSize` (getting a shader storage buffer's size).

		No target has compute shaders or shader storage buffers, as WebGL2 has none.

		@param id  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlGetShaderBufferSize: Not supported: helix-raylib has no compute shaders or shader storage buffers, as WebGL2 has none.")
	static function rlGetShaderBufferSize(id:Int):Int {
		throw "rlGetShaderBufferSize is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlBindImageTexture` (binding an image texture). See
		`LoadTextureFromImage` for making a texture and `rlSetTexture` for drawing vertices with one.

		@param id  As rlgl takes it.
		@param index  As rlgl takes it.
		@param format  As rlgl takes it.
		@param readonly  As rlgl takes it. */
	@:unsupported("rlBindImageTexture: Not supported: helix-raylib has no GL texture ids; a Texture2D is made with LoadTextureAsync,, or LoadTextureFromImage, set up with SetTextureFilter, and drawn with rlSetTexture or the drawing functions.")
	static function rlBindImageTexture(id:Int, index:Int, format:Int, readonly:Bool):Void {
		throw "rlBindImageTexture is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlLoadDrawCube` (drawing a cube). See `InitWindow` for setting up what
		helix-raylib draws with. */
	@:unsupported("rlLoadDrawCube: Not supported: helix-raylib has no GL of its own: InitWindow and CloseWindow set up and close what it draws with.")
	static function rlLoadDrawCube():Void {
		throw "rlLoadDrawCube is unsupported";
	}

	/** Refuses to compile on every target, replacing rlgl's `rlLoadDrawQuad` (drawing a quad). See `InitWindow` for setting up what
		helix-raylib draws with. */
	@:unsupported("rlLoadDrawQuad: Not supported: helix-raylib has no GL of its own: InitWindow and CloseWindow set up and close what it draws with.")
	static function rlLoadDrawQuad():Void {
		throw "rlLoadDrawQuad is unsupported";
	}

	static var matrixMode = RL_MODELVIEW;
	static var cullNear:Float = RL_CULL_DISTANCE_NEAR;
	static var cullFar:Float = RL_CULL_DISTANCE_FAR;
	static var scissorBox:Null<Array<Int>> = null;
	static var clearColor = 0xff000000;
	static var lineWidth = 1.;
	static var framebufferWidth = 0;
	static var framebufferHeight = 0;
	static var framebufferPass = -1;
	static var pushed = false;
	static final transform = new Matrix3D();
	static final stack:Array<Matrix3D> = [];
	// The corners of the quad being added, 0 to 3.
	static var quadCorners = 0;
	static var u = 0.;
	static var v = 0.;
	static var color = new Color(255, 255, 255, 255);
	// rlgl's current texture id, which the next change of mode (rlBegin) gives its draw call: 0 for the white texture.
	static var textureId = 0;

	// The frame whose state rlgl's state calls set: without flushing its batch, as rlgl's don't, so the vertices waiting in it are drawn
	// with the state as it is when it is flushed.
	static inline function state():helix.raylib.internal.Frame {
		return Runtime.frame;
	}

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
		set(Matrix3D.compose(m, current()));
	}

	// The draw call's texture, the white one for none.
	static function texture():Int {
		var id = Runtime.frame.drawTexture;
		var handle = id == 0 ? 0 : Textures.handle(id);
		return handle == 0 ? Runtime.frame.white : handle;
	}
	#end
}
