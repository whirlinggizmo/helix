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

/** Holds raylib's rlgl (the matrix stack, immediate drawing and render state), written here; `Rlgl` forwards to each
	(`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RRlgl {
	// The quads added here draw as sprites: the frame given its sprite shader as the module starts.
	static function __init__():Void {
		helix.raylib.internal.Sprites.register();
	}

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

		At most 32 are saved at once, as rlgl allows: past them it saves nothing and changes nothing, logging an error. */
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

	/** Starts vertices: each 2 a line, 3 a triangle or 4 a quad, until `rlEnd`.

		A mode other than the last one's starts a new draw call: it takes the texture `rlSetTexture` last set, and the white texture is
		set for the next, so a second change of mode without another `rlSetTexture` draws untextured. The same mode again keeps the draw
		call and its texture.

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

	/** Ends the vertices `rlBegin` started; a shape left short of its vertices isn't drawn. */
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

	/** Sets the next vertices' normal: turned by the transform `rlPushMatrix` started, when there is one, and made length 1, as rlgl does.

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

	/** Sets the texture the next vertices draw with, as rlgl's: the vertices after it draw with it, and so does the draw call the next
		change of mode (`rlBegin`) starts. 0 leaves the vertices after it with the texture they have, and has the next change of mode
		start with the white texture.

		@param id  The texture's id (`Texture2D.id`), or 0 for none. */
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

	/** Sets the GL factors and equation `RL_BLEND_CUSTOM` blends by, red, green, blue and alpha alike, as `glBlendFunc` and `glBlendEquation`
		take them. They take effect at the next `rlSetBlendMode(RL_BLEND_CUSTOM)`, even in that mode already. A value GL doesn't have leaves
		the factors (or the equation) as they were, as GL refuses it. raylib sets no blend color, so `RL_CONSTANT_COLOR` and
		`RL_CONSTANT_ALPHA` are 0 and their `RL_ONE_MINUS_` forms 1.

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
		`glBlendFuncSeparate` and `glBlendEquationSeparate` take them. They take effect at the next
		`rlSetBlendMode(RL_BLEND_CUSTOM_SEPARATE)`, as `rlSetBlendFactors`' do.

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

	/** Sets which color channels the next draws write, as `glColorMask` does. The batch isn't drawn first, so the vertices waiting in it
		are masked too. `ClearBackground` clears every channel whatever this says, where raylib's clears only those written.

		@param r  Whether red is written.
		@param g  Whether green is written.
		@param b  Whether blue is written.
		@param a  Whether alpha is written. */
	static function rlColorMask(r:Bool, g:Bool, b:Bool, a:Bool):Void {
		state().colorMask = cast((r ? 1 : 0) | (g ? 2 : 0) | (b ? 4 : 0) | (a ? 8 : 0));
	}

	/** Draws the vertices waiting in rlgl's batch now, with the state as it is (rlgl's state calls don't, so a program calls this before
		and after changing one for the shapes between); a mode, a shader, blending, scissor or a pass changing does it too. */
	static function rlDrawRenderBatchActive():Void {
		Runtime.frame.cut();
	}

	/** Returns whether the next vertices would overflow rlgl's batch, which it then draws first. The batch here has no such limit, so it
		is drawn only as it is flushed (`rlDrawRenderBatchActive`).

		@param vCount  The vertices.
		@return  False. */
	static function rlCheckRenderBatchLimit(vCount:Int):Bool {
		return false;
	}

	/** Blends the next draws as the blend mode says, as raylib starts. */
	static function rlEnableColorBlend():Void {
		state().colorBlend = true;
	}

	/** Draws the next draws over what is there, without blending. */
	static function rlDisableColorBlend():Void {
		state().colorBlend = false;
	}

	/** Tests the next draws' depth, keeping only what is as near as or nearer than what is drawn there. `BeginMode3D` does it. */
	static function rlEnableDepthTest():Void {
		state().depthTest = true;
	}

	/** Stops testing the next draws' depth, as raylib starts and `EndMode3D` does. */
	static function rlDisableDepthTest():Void {
		state().depthTest = false;
	}

	/** Lets the next draws that test depth write it, as raylib starts. */
	static function rlEnableDepthMask():Void {
		state().depthMask = true;
	}

	/** Stops the next draws writing depth, so what is drawn after isn't hidden by them, as for something see-through. */
	static function rlDisableDepthMask():Void {
		state().depthMask = false;
	}

	/** Leaves out the next triangles' backs (or fronts, by `rlSetCullFace`), as raylib starts: a triangle's front is the side its corners
		are counterclockwise from. */
	static function rlEnableBackfaceCulling():Void {
		state().cull = true;
	}

	/** Draws both sides of the next triangles. */
	static function rlDisableBackfaceCulling():Void {
		state().cull = false;
	}

	/** Chooses which side of triangles culling leaves out.

		@param mode  `RL_CULL_FACE_BACK`, as raylib starts, or `RL_CULL_FACE_FRONT`. */
	static function rlSetCullFace(mode:Int):Void {
		state().cullFront = mode == RL_CULL_FACE_FRONT;
	}

	/** Draws triangles as their edges from now: a model drawn after it at once, and the shapes in rlgl's batch when it is next drawn
		(`rlDrawRenderBatchActive`), as GL's line mode does, which a page's WebGL hasn't, done here as lines. Culling still leaves out the
		triangles it would, by their facing on the screen as GL finds it; a shader that moves the vertices isn't seen in that. It ends
		point mode (`rlEnablePointMode`). */
	static function rlEnableWireMode():Void {
		var f = state();
		f.wire = true;
		f.pointRun = null;
		f.pointMesh = null;
	}

	/** Draws triangles as their corners from now, one pixel each: a model drawn after it at once (each index of its triangles, or each
		vertex of its whole triangles without indices), and the triangles in rlgl's batch when it is next drawn, as desktop GL's point mode
		does, which a page's WebGL hasn't, done here as points on every backend. Lines are drawn as lines. Culling still leaves out the
		triangles it would, by their facing on the screen as GL finds it. A shader's own `gl_PointSize` is ignored: every point is one
		pixel, the size every backend draws. `rlDisableWireMode` ends it, and `rlEnableWireMode` replaces it. */
	static function rlEnablePointMode():Void {
		var f = state();
		f.wire = false;
		f.pointRun = f.pointsOfRun;
		f.pointMesh = f.pointsOfMesh;
	}

	/** Draws the next triangles filled, as raylib starts, ending wire mode or point mode. */
	static function rlDisableWireMode():Void {
		var f = state();
		f.wire = false;
		f.pointRun = null;
		f.pointMesh = null;
	}

	/** Clips the next draws to the rectangle `rlScissor` last set: the whole pass until it is set. */
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

	/** Sets the rectangle the next draws are clipped to while the scissor test is on, as GL takes it: in the framebuffer's pixels, from
		its bottom left. `BeginScissorMode` takes one from the top left in the screen's pixels.

		@param x  Its left edge.
		@param y  Its bottom edge, from the bottom.
		@param width  Its width.
		@param height  Its height. */
	static function rlScissor(x:Int, y:Int, width:Int, height:Int):Void {
		scissorBox = [x, y, width, height];
		if (Runtime.frame.scissor != null)
			rlEnableScissorTest();
	}

	/** Sets the rectangle the next draws fill, as GL takes it, until the next pass begins (`BeginDrawing`, `BeginTextureMode`,
		`EndTextureMode`), which fills the whole of it again; the projection is unchanged, so what is drawn is squeezed into it.

		@param x  Its left edge, in framebuffer pixels.
		@param y  Its bottom edge, from the bottom.
		@param width  Its width.
		@param height  Its height. */
	static function rlViewport(x:Int, y:Int, width:Int, height:Int):Void {
		state().viewport = [x, y, width, height];
	}

	/** Sets the near and far distances `BeginMode3D`'s cameras see between, and the rays and projections of cameras after it use.

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

	/** Clears what is drawn into, its colors to `rlClearColor`'s (black until set) and its depth, as `ClearBackground` does. */
	static function rlClearScreenBuffers():Void {
		Runtime.frame.clear(clearColor);
	}

	/** Sets the width lines are drawn at. GL 3.3's core profile and WebGL draw only 1, as raylib's lines are there, so lines stay 1 pixel
		wide; the width is kept for `rlGetLineWidth`.

		@param width  The width, in pixels. */
	static function rlSetLineWidth(width:Float):Void {
		lineWidth = width;
	}

	/** Returns the width `rlSetLineWidth` last set, 1 until then.

		@return  The width. */
	static function rlGetLineWidth():Float {
		return lineWidth;
	}

	/** Asks for smoothed lines. GL 3.3's core profile and WebGL don't smooth them, so this changes nothing; `FLAG_MSAA_4X_HINT` smooths
		every edge. */
	static function rlEnableSmoothLines():Void {}

	/** Stops asking for smoothed lines, which changes nothing here (`rlEnableSmoothLines`). */
	static function rlDisableSmoothLines():Void {}

	/** Sets the width rlgl takes the framebuffer drawn into to have, until the next pass begins, as `BeginTextureMode` and `EndTextureMode`
		set it. Drawing here doesn't read it; `rlGetFramebufferWidth` gives it back.

		@param width  The width, in pixels. */
	static function rlSetFramebufferWidth(width:Int):Void {
		framebufferWidth = width;
		framebufferPass = Runtime.frame.passCount;
	}

	/** Returns the width of what is drawn into: the render texture's in `BeginTextureMode`, the screen's in framebuffer pixels
		otherwise, or `rlSetFramebufferWidth`'s since this pass began.

		@return  The width. */
	static function rlGetFramebufferWidth():Int {
		var f = Runtime.frame;
		return framebufferPass == f.passCount ? framebufferWidth : f.inTarget ? Std.int(f.width) : GetRenderWidth();
	}

	/** Sets the height rlgl takes the framebuffer drawn into to have, until the next pass begins (`rlSetFramebufferWidth`).

		@param height  The height, in pixels. */
	static function rlSetFramebufferHeight(height:Int):Void {
		framebufferHeight = height;
		framebufferPass = Runtime.frame.passCount;
	}

	/** Returns the height of what is drawn into, as `rlGetFramebufferWidth` gives its width.

		@return  The height. */
	static function rlGetFramebufferHeight():Int {
		var f = Runtime.frame;
		return framebufferPass == f.passCount ? framebufferHeight : f.inTarget ? Std.int(f.height) : GetRenderHeight();
	}

	/** Returns a pixel format's name, as rlgl writes it in its log: "R8G8B8A8" for `RL_PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`.

		@param format  The format (`RL_PIXELFORMAT_*`).
		@return  Its name; "UNKNOWN" for another number. */
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

	/** Turns stereo rendering on: from the next flush of the batch, its vertices waiting among them, and the next mesh drawn, each is
		drawn twice, in the left half of what is drawn into through the first eye's view offset and projection, then in the right half
		through the second's (`rlSetMatrixViewOffsetStereo`, `rlSetMatrixProjectionStereo`). After the batch the viewport is the whole
		again; after a mesh it is left the right half, as rlgl leaves it. `BeginVrStereoMode` turns it on with a config's matrices. */
	static function rlEnableStereoRender():Void {
		helix.raylib.internal.Stereo.enable(true);
	}

	/** Turns stereo rendering off, for the next flush of the batch and the next mesh drawn. */
	static function rlDisableStereoRender():Void {
		helix.raylib.internal.Stereo.enable(false);
	}

	/** Returns whether stereo rendering is on (`rlEnableStereoRender`).

		@return  True when it is. */
	static function rlIsStereoRenderEnabled():Bool {
		return helix.raylib.internal.Stereo.enabled;
	}

	/** Returns an eye's projection in stereo rendering, as `rlSetMatrixProjectionStereo` set it: zero until then, and for any other eye (raylib reads past its two).

		@param eye  The eye: 0, drawn in the left half, or 1.
		@return  The matrix. */
	static function rlGetMatrixProjectionStereo(eye:Int):Matrix {
		return eye == 0 || eye == 1 ? toMatrix(helix.raylib.internal.Stereo.projections[eye]) : new Matrix();
	}

	/** Returns an eye's view offset in stereo rendering, as `rlSetMatrixViewOffsetStereo` set it: zero until then, and for any other eye (raylib reads past its two).

		@param eye  The eye: 0, drawn in the left half, or 1.
		@return  The matrix. */
	static function rlGetMatrixViewOffsetStereo(eye:Int):Matrix {
		return eye == 0 || eye == 1 ? toMatrix(helix.raylib.internal.Stereo.offsets[eye]) : new Matrix();
	}

	/** Sets each eye's projection in stereo rendering, in place of the projection, for the batch's next flush; a mesh's mvp takes it,
		its `matProjection` left the projection.

		@param right  Eye 0's projection, drawn in the left half (raylib names it the right).
		@param left  Eye 1's, drawn in the right half. */
	static function rlSetMatrixProjectionStereo(right:Matrix, left:Matrix):Void {
		helix.raylib.internal.Stereo.projections[0].copyFrom(toMatrix3D(right));
		helix.raylib.internal.Stereo.projections[1].copyFrom(toMatrix3D(left));
	}

	/** Sets each eye's view offset in stereo rendering, applied after the view for the batch's next flush and a mesh's mvp.

		@param right  Eye 0's offset, drawn in the left half (raylib names it the right).
		@param left  Eye 1's, drawn in the right half. */
	static function rlSetMatrixViewOffsetStereo(right:Matrix, left:Matrix):Void {
		helix.raylib.internal.Stereo.offsets[0].copyFrom(toMatrix3D(right));
		helix.raylib.internal.Stereo.offsets[1].copyFrom(toMatrix3D(left));
	}

	// ---- rlgl's GL objects and GL itself, which helix-raylib draws without: each refuses to compile, saying what to use ----

	/** rlgl's `rlEnableVertexArray`: enable vertex array (vao, if supported), which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param vaoId  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlEnableVertexArray: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlEnableVertexArray(vaoId:Int):Bool {
		throw "rlEnableVertexArray is unsupported";
	}

	/** rlgl's `rlDisableVertexArray`: disable vertex array (vao, if supported), which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.
	 */
	@:unsupported("rlDisableVertexArray: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlDisableVertexArray():Void {
		throw "rlDisableVertexArray is unsupported";
	}

	/** rlgl's `rlEnableVertexBuffer`: enable vertex buffer (vbo), which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param id  As rlgl takes it. */
	@:unsupported("rlEnableVertexBuffer: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlEnableVertexBuffer(id:Int):Void {
		throw "rlEnableVertexBuffer is unsupported";
	}

	/** rlgl's `rlDisableVertexBuffer`: disable vertex buffer (vbo), which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.
	 */
	@:unsupported("rlDisableVertexBuffer: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlDisableVertexBuffer():Void {
		throw "rlDisableVertexBuffer is unsupported";
	}

	/** rlgl's `rlEnableVertexBufferElement`: enable vertex buffer element (vbo element), which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param id  As rlgl takes it. */
	@:unsupported("rlEnableVertexBufferElement: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlEnableVertexBufferElement(id:Int):Void {
		throw "rlEnableVertexBufferElement is unsupported";
	}

	/** rlgl's `rlDisableVertexBufferElement`: disable vertex buffer element (vbo element), which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.
	 */
	@:unsupported("rlDisableVertexBufferElement: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlDisableVertexBufferElement():Void {
		throw "rlDisableVertexBufferElement is unsupported";
	}

	/** rlgl's `rlEnableVertexAttribute`: enable vertex attribute index, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param index  As rlgl takes it. */
	@:unsupported("rlEnableVertexAttribute: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlEnableVertexAttribute(index:Int):Void {
		throw "rlEnableVertexAttribute is unsupported";
	}

	/** rlgl's `rlDisableVertexAttribute`: disable vertex attribute index, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param index  As rlgl takes it. */
	@:unsupported("rlDisableVertexAttribute: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlDisableVertexAttribute(index:Int):Void {
		throw "rlDisableVertexAttribute is unsupported";
	}

	/** rlgl's `rlEnableStatePointer`: enable attribute state pointer, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param vertexAttribType  As rlgl takes it.
		@param buffer  As rlgl takes it. */
	@:unsupported("rlEnableStatePointer: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlEnableStatePointer(vertexAttribType:Int, buffer:Dynamic):Void {
		throw "rlEnableStatePointer is unsupported";
	}

	/** rlgl's `rlDisableStatePointer`: disable attribute state pointer, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param vertexAttribType  As rlgl takes it. */
	@:unsupported("rlDisableStatePointer: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlDisableStatePointer(vertexAttribType:Int):Void {
		throw "rlDisableStatePointer is unsupported";
	}

	/** rlgl's `rlActiveTextureSlot`: select and active a texture slot, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param slot  As rlgl takes it. */
	@:unsupported("rlActiveTextureSlot: Not supported: helix-raylib has no GL texture ids; a Texture2D is made with LoadTextureAsync, in helix.raylib.extras.Textures (import helix.raylib.extras.Textures.*;), or LoadTextureFromImage, set up with SetTextureFilter, and drawn with rlSetTexture or the drawing functions.")
	static function rlActiveTextureSlot(slot:Int):Void {
		throw "rlActiveTextureSlot is unsupported";
	}

	/** rlgl's `rlEnableTexture`: enable texture, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param id  As rlgl takes it. */
	@:unsupported("rlEnableTexture: Not supported: helix-raylib has no GL texture ids; a Texture2D is made with LoadTextureAsync, in helix.raylib.extras.Textures (import helix.raylib.extras.Textures.*;), or LoadTextureFromImage, set up with SetTextureFilter, and drawn with rlSetTexture or the drawing functions.")
	static function rlEnableTexture(id:Int):Void {
		throw "rlEnableTexture is unsupported";
	}

	/** rlgl's `rlDisableTexture`: disable texture, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.
	 */
	@:unsupported("rlDisableTexture: Not supported: helix-raylib has no GL texture ids; a Texture2D is made with LoadTextureAsync, in helix.raylib.extras.Textures (import helix.raylib.extras.Textures.*;), or LoadTextureFromImage, set up with SetTextureFilter, and drawn with rlSetTexture or the drawing functions.")
	static function rlDisableTexture():Void {
		throw "rlDisableTexture is unsupported";
	}

	/** rlgl's `rlEnableTextureCubemap`: enable texture cubemap, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param id  As rlgl takes it. */
	@:unsupported("rlEnableTextureCubemap: Not supported: helix-raylib has no GL texture ids; a Texture2D is made with LoadTextureAsync, in helix.raylib.extras.Textures (import helix.raylib.extras.Textures.*;), or LoadTextureFromImage, set up with SetTextureFilter, and drawn with rlSetTexture or the drawing functions.")
	static function rlEnableTextureCubemap(id:Int):Void {
		throw "rlEnableTextureCubemap is unsupported";
	}

	/** rlgl's `rlDisableTextureCubemap`: disable texture cubemap, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.
	 */
	@:unsupported("rlDisableTextureCubemap: Not supported: helix-raylib has no GL texture ids; a Texture2D is made with LoadTextureAsync, in helix.raylib.extras.Textures (import helix.raylib.extras.Textures.*;), or LoadTextureFromImage, set up with SetTextureFilter, and drawn with rlSetTexture or the drawing functions.")
	static function rlDisableTextureCubemap():Void {
		throw "rlDisableTextureCubemap is unsupported";
	}

	/** rlgl's `rlTextureParameters`: set texture parameters (filter, wrap), which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param id  As rlgl takes it.
		@param param  As rlgl takes it.
		@param value  As rlgl takes it. */
	@:unsupported("rlTextureParameters: Not supported: helix-raylib has no GL texture ids; a Texture2D is made with LoadTextureAsync, in helix.raylib.extras.Textures (import helix.raylib.extras.Textures.*;), or LoadTextureFromImage, set up with SetTextureFilter, and drawn with rlSetTexture or the drawing functions.")
	static function rlTextureParameters(id:Int, param:Int, value:Int):Void {
		throw "rlTextureParameters is unsupported";
	}

	/** rlgl's `rlCubemapParameters`: set cubemap parameters (filter, wrap), which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param id  As rlgl takes it.
		@param param  As rlgl takes it.
		@param value  As rlgl takes it. */
	@:unsupported("rlCubemapParameters: Not supported: helix-raylib has no GL texture ids; a Texture2D is made with LoadTextureAsync, in helix.raylib.extras.Textures (import helix.raylib.extras.Textures.*;), or LoadTextureFromImage, set up with SetTextureFilter, and drawn with rlSetTexture or the drawing functions.")
	static function rlCubemapParameters(id:Int, param:Int, value:Int):Void {
		throw "rlCubemapParameters is unsupported";
	}

	/** rlgl's `rlEnableShader`: enable shader program, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param id  As rlgl takes it. */
	@:unsupported("rlEnableShader: Not supported: helix-raylib has no GL shader ids; a Shader is compiled as the program builds by LoadShader, set with SetShaderValue, and used between BeginShaderMode and EndShaderMode.")
	static function rlEnableShader(id:Int):Void {
		throw "rlEnableShader is unsupported";
	}

	/** rlgl's `rlDisableShader`: disable shader program, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.
	 */
	@:unsupported("rlDisableShader: Not supported: helix-raylib has no GL shader ids; a Shader is compiled as the program builds by LoadShader, set with SetShaderValue, and used between BeginShaderMode and EndShaderMode.")
	static function rlDisableShader():Void {
		throw "rlDisableShader is unsupported";
	}

	/** rlgl's `rlEnableFramebuffer`: enable render texture (fbo), which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param id  As rlgl takes it. */
	@:unsupported("rlEnableFramebuffer: Not supported: helix-raylib has no GL framebuffers; a RenderTexture2D is made with LoadRenderTexture and drawn into between BeginTextureMode and EndTextureMode.")
	static function rlEnableFramebuffer(id:Int):Void {
		throw "rlEnableFramebuffer is unsupported";
	}

	/** rlgl's `rlDisableFramebuffer`: disable render texture (fbo), return to default framebuffer, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.
	 */
	@:unsupported("rlDisableFramebuffer: Not supported: helix-raylib has no GL framebuffers; a RenderTexture2D is made with LoadRenderTexture and drawn into between BeginTextureMode and EndTextureMode.")
	static function rlDisableFramebuffer():Void {
		throw "rlDisableFramebuffer is unsupported";
	}

	/** rlgl's `rlGetActiveFramebuffer`: get the currently active render texture (fbo), 0 for default framebuffer, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlGetActiveFramebuffer: Not supported: helix-raylib has no GL framebuffers; a RenderTexture2D is made with LoadRenderTexture and drawn into between BeginTextureMode and EndTextureMode.")
	static function rlGetActiveFramebuffer():Int {
		throw "rlGetActiveFramebuffer is unsupported";
	}

	/** rlgl's `rlActiveDrawBuffers`: activate multiple draw color buffers, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param count  As rlgl takes it. */
	@:unsupported("rlActiveDrawBuffers: Not supported: helix-raylib has no GL framebuffers; a RenderTexture2D is made with LoadRenderTexture and drawn into between BeginTextureMode and EndTextureMode.")
	static function rlActiveDrawBuffers(count:Int):Void {
		throw "rlActiveDrawBuffers is unsupported";
	}

	/** rlgl's `rlBlitFramebuffer`: blit active framebuffer to main framebuffer, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

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

	/** rlgl's `rlBindFramebuffer`: bind framebuffer (fbo), which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param target  As rlgl takes it.
		@param framebuffer  As rlgl takes it. */
	@:unsupported("rlBindFramebuffer: Not supported: helix-raylib has no GL framebuffers; a RenderTexture2D is made with LoadRenderTexture and drawn into between BeginTextureMode and EndTextureMode.")
	static function rlBindFramebuffer(target:Int, framebuffer:Int):Void {
		throw "rlBindFramebuffer is unsupported";
	}

	/** rlgl's `rlCheckErrors`: check and log opengl error codes, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.
	 */
	@:unsupported("rlCheckErrors: Not supported: helix-raylib has no GL of its own: InitWindow and CloseWindow set up and close what it draws with.")
	static function rlCheckErrors():Void {
		throw "rlCheckErrors is unsupported";
	}

	/** rlgl's `rlglInit`: initialize rlgl (buffers, shaders, textures, states), which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param width  As rlgl takes it.
		@param height  As rlgl takes it. */
	@:unsupported("rlglInit: Not supported: helix-raylib has no GL of its own: InitWindow and CloseWindow set up and close what it draws with.")
	static function rlglInit(width:Int, height:Int):Void {
		throw "rlglInit is unsupported";
	}

	/** rlgl's `rlglClose`: de-initialize rlgl (buffers, shaders, textures), which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.
	 */
	@:unsupported("rlglClose: Not supported: helix-raylib has no GL of its own: InitWindow and CloseWindow set up and close what it draws with.")
	static function rlglClose():Void {
		throw "rlglClose is unsupported";
	}

	/** rlgl's `rlLoadExtensions`: load opengl extensions (loader function required), which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param loader  As rlgl takes it. */
	@:unsupported("rlLoadExtensions: Not supported: helix-raylib has no GL of its own: InitWindow and CloseWindow set up and close what it draws with.")
	static function rlLoadExtensions(loader:Dynamic):Void {
		throw "rlLoadExtensions is unsupported";
	}

	/** rlgl's `rlGetVersion`: get current opengl version, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlGetVersion: Not supported: helix-raylib has no GL of its own: InitWindow and CloseWindow set up and close what it draws with.")
	static function rlGetVersion():Int {
		throw "rlGetVersion is unsupported";
	}

	/** rlgl's `rlGetTextureIdDefault`: get default texture id, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlGetTextureIdDefault: Not supported: helix-raylib has no GL texture ids; a Texture2D is made with LoadTextureAsync, in helix.raylib.extras.Textures (import helix.raylib.extras.Textures.*;), or LoadTextureFromImage, set up with SetTextureFilter, and drawn with rlSetTexture or the drawing functions.")
	static function rlGetTextureIdDefault():Int {
		throw "rlGetTextureIdDefault is unsupported";
	}

	/** rlgl's `rlGetShaderIdDefault`: get default shader id, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlGetShaderIdDefault: Not supported: helix-raylib has no GL shader ids; a Shader is compiled as the program builds by LoadShader, set with SetShaderValue, and used between BeginShaderMode and EndShaderMode.")
	static function rlGetShaderIdDefault():Int {
		throw "rlGetShaderIdDefault is unsupported";
	}

	/** rlgl's `rlGetShaderLocsDefault`: get default shader locations, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlGetShaderLocsDefault: Not supported: helix-raylib has no GL shader ids; a Shader is compiled as the program builds by LoadShader, set with SetShaderValue, and used between BeginShaderMode and EndShaderMode.")
	static function rlGetShaderLocsDefault():Array<Int> {
		throw "rlGetShaderLocsDefault is unsupported";
	}

	/** rlgl's `rlLoadRenderBatch`: load a render batch system, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param numBuffers  As rlgl takes it.
		@param bufferElements  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlLoadRenderBatch: Not supported: helix-raylib has no render batches of rlgl's; its frame keeps one batch, as rlgl's default one, drawn by rlDrawRenderBatchActive.")
	static function rlLoadRenderBatch(numBuffers:Int, bufferElements:Int):Dynamic {
		throw "rlLoadRenderBatch is unsupported";
	}

	/** rlgl's `rlUnloadRenderBatch`: unload render batch system, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param batch  As rlgl takes it. */
	@:unsupported("rlUnloadRenderBatch: Not supported: helix-raylib has no render batches of rlgl's; its frame keeps one batch, as rlgl's default one, drawn by rlDrawRenderBatchActive.")
	static function rlUnloadRenderBatch(batch:Dynamic):Void {
		throw "rlUnloadRenderBatch is unsupported";
	}

	/** rlgl's `rlDrawRenderBatch`: draw render batch data (update->draw->reset), which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param batch  As rlgl takes it. */
	@:unsupported("rlDrawRenderBatch: Not supported: helix-raylib has no render batches of rlgl's; its frame keeps one batch, as rlgl's default one, drawn by rlDrawRenderBatchActive.")
	static function rlDrawRenderBatch(batch:Dynamic):Void {
		throw "rlDrawRenderBatch is unsupported";
	}

	/** rlgl's `rlSetRenderBatchActive`: set the active render batch for rlgl (null for default internal), which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param batch  As rlgl takes it. */
	@:unsupported("rlSetRenderBatchActive: Not supported: helix-raylib has no render batches of rlgl's; its frame keeps one batch, as rlgl's default one, drawn by rlDrawRenderBatchActive.")
	static function rlSetRenderBatchActive(batch:Dynamic):Void {
		throw "rlSetRenderBatchActive is unsupported";
	}

	/** rlgl's `rlLoadVertexArray`: load vertex array (vao) if supported, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlLoadVertexArray: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlLoadVertexArray():Int {
		throw "rlLoadVertexArray is unsupported";
	}

	/** rlgl's `rlLoadVertexBuffer`: load a vertex buffer object, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param buffer  As rlgl takes it.
		@param size  As rlgl takes it.
		@param isDynamic  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlLoadVertexBuffer: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlLoadVertexBuffer(buffer:Dynamic, size:Int, isDynamic:Bool):Int {
		throw "rlLoadVertexBuffer is unsupported";
	}

	/** rlgl's `rlLoadVertexBufferElement`: load vertex buffer elements object, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param buffer  As rlgl takes it.
		@param size  As rlgl takes it.
		@param isDynamic  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlLoadVertexBufferElement: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlLoadVertexBufferElement(buffer:Dynamic, size:Int, isDynamic:Bool):Int {
		throw "rlLoadVertexBufferElement is unsupported";
	}

	/** rlgl's `rlUpdateVertexBuffer`: update vertex buffer object data on gpu buffer, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param bufferId  As rlgl takes it.
		@param data  As rlgl takes it.
		@param dataSize  As rlgl takes it.
		@param offset  As rlgl takes it. */
	@:unsupported("rlUpdateVertexBuffer: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlUpdateVertexBuffer(bufferId:Int, data:Dynamic, dataSize:Int, offset:Int):Void {
		throw "rlUpdateVertexBuffer is unsupported";
	}

	/** rlgl's `rlUpdateVertexBufferElements`: update vertex buffer elements data on gpu buffer, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param id  As rlgl takes it.
		@param data  As rlgl takes it.
		@param dataSize  As rlgl takes it.
		@param offset  As rlgl takes it. */
	@:unsupported("rlUpdateVertexBufferElements: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlUpdateVertexBufferElements(id:Int, data:Dynamic, dataSize:Int, offset:Int):Void {
		throw "rlUpdateVertexBufferElements is unsupported";
	}

	/** rlgl's `rlUnloadVertexArray`: unload vertex array (vao), which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param vaoId  As rlgl takes it. */
	@:unsupported("rlUnloadVertexArray: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlUnloadVertexArray(vaoId:Int):Void {
		throw "rlUnloadVertexArray is unsupported";
	}

	/** rlgl's `rlUnloadVertexBuffer`: unload vertex buffer object, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param vboId  As rlgl takes it. */
	@:unsupported("rlUnloadVertexBuffer: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlUnloadVertexBuffer(vboId:Int):Void {
		throw "rlUnloadVertexBuffer is unsupported";
	}

	/** rlgl's `rlSetVertexAttribute`: set vertex attribute data configuration, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

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

	/** rlgl's `rlSetVertexAttributeDivisor`: set vertex attribute data divisor, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param index  As rlgl takes it.
		@param divisor  As rlgl takes it. */
	@:unsupported("rlSetVertexAttributeDivisor: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlSetVertexAttributeDivisor(index:Int, divisor:Int):Void {
		throw "rlSetVertexAttributeDivisor is unsupported";
	}

	/** rlgl's `rlSetVertexAttributeDefault`: set vertex attribute default value, when attribute to provided, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param locIndex  As rlgl takes it.
		@param value  As rlgl takes it.
		@param attribType  As rlgl takes it.
		@param count  As rlgl takes it. */
	@:unsupported("rlSetVertexAttributeDefault: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlSetVertexAttributeDefault(locIndex:Int, value:Dynamic, attribType:Int, count:Int):Void {
		throw "rlSetVertexAttributeDefault is unsupported";
	}

	/** rlgl's `rlDrawVertexArray`: draw vertex array (currently active vao), which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param offset  As rlgl takes it.
		@param count  As rlgl takes it. */
	@:unsupported("rlDrawVertexArray: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlDrawVertexArray(offset:Int, count:Int):Void {
		throw "rlDrawVertexArray is unsupported";
	}

	/** rlgl's `rlDrawVertexArrayElements`: draw vertex array elements, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param offset  As rlgl takes it.
		@param count  As rlgl takes it.
		@param buffer  As rlgl takes it. */
	@:unsupported("rlDrawVertexArrayElements: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlDrawVertexArrayElements(offset:Int, count:Int, buffer:Dynamic):Void {
		throw "rlDrawVertexArrayElements is unsupported";
	}

	/** rlgl's `rlDrawVertexArrayInstanced`: draw vertex array (currently active vao) with instancing, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param offset  As rlgl takes it.
		@param count  As rlgl takes it.
		@param instances  As rlgl takes it. */
	@:unsupported("rlDrawVertexArrayInstanced: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlDrawVertexArrayInstanced(offset:Int, count:Int, instances:Int):Void {
		throw "rlDrawVertexArrayInstanced is unsupported";
	}

	/** rlgl's `rlDrawVertexArrayElementsInstanced`: draw vertex array elements with instancing, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param offset  As rlgl takes it.
		@param count  As rlgl takes it.
		@param buffer  As rlgl takes it.
		@param instances  As rlgl takes it. */
	@:unsupported("rlDrawVertexArrayElementsInstanced: Not supported: helix-raylib has no vertex arrays or buffers of GL's; a Mesh is uploaded with UploadMesh and drawn with DrawMesh.")
	static function rlDrawVertexArrayElementsInstanced(offset:Int, count:Int, buffer:Dynamic, instances:Int):Void {
		throw "rlDrawVertexArrayElementsInstanced is unsupported";
	}

	/** rlgl's `rlLoadTexture`: load texture data, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param data  As rlgl takes it.
		@param width  As rlgl takes it.
		@param height  As rlgl takes it.
		@param format  As rlgl takes it.
		@param mipmapCount  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlLoadTexture: Not supported: helix-raylib has no GL texture ids; a Texture2D is made with LoadTextureAsync, in helix.raylib.extras.Textures (import helix.raylib.extras.Textures.*;), or LoadTextureFromImage, set up with SetTextureFilter, and drawn with rlSetTexture or the drawing functions.")
	static function rlLoadTexture(data:Dynamic, width:Int, height:Int, format:Int, mipmapCount:Int):Int {
		throw "rlLoadTexture is unsupported";
	}

	/** rlgl's `rlLoadTextureDepth`: load depth texture/renderbuffer (to be attached to fbo), which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param width  As rlgl takes it.
		@param height  As rlgl takes it.
		@param useRenderBuffer  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlLoadTextureDepth: Not supported: helix-raylib has no GL texture ids; a Texture2D is made with LoadTextureAsync, in helix.raylib.extras.Textures (import helix.raylib.extras.Textures.*;), or LoadTextureFromImage, set up with SetTextureFilter, and drawn with rlSetTexture or the drawing functions.")
	static function rlLoadTextureDepth(width:Int, height:Int, useRenderBuffer:Bool):Int {
		throw "rlLoadTextureDepth is unsupported";
	}

	/** rlgl's `rlLoadTextureCubemap`: load texture cubemap data, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param data  As rlgl takes it.
		@param size  As rlgl takes it.
		@param format  As rlgl takes it.
		@param mipmapCount  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlLoadTextureCubemap: Not supported: helix-raylib has no GL texture ids; a Texture2D is made with LoadTextureAsync, in helix.raylib.extras.Textures (import helix.raylib.extras.Textures.*;), or LoadTextureFromImage, set up with SetTextureFilter, and drawn with rlSetTexture or the drawing functions.")
	static function rlLoadTextureCubemap(data:Dynamic, size:Int, format:Int, mipmapCount:Int):Int {
		throw "rlLoadTextureCubemap is unsupported";
	}

	/** rlgl's `rlUpdateTexture`: update texture with new data on gpu, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param id  As rlgl takes it.
		@param offsetX  As rlgl takes it.
		@param offsetY  As rlgl takes it.
		@param width  As rlgl takes it.
		@param height  As rlgl takes it.
		@param format  As rlgl takes it.
		@param data  As rlgl takes it. */
	@:unsupported("rlUpdateTexture: Not supported: helix-raylib has no GL texture ids; a Texture2D is made with LoadTextureAsync, in helix.raylib.extras.Textures (import helix.raylib.extras.Textures.*;), or LoadTextureFromImage, set up with SetTextureFilter, and drawn with rlSetTexture or the drawing functions.")
	static function rlUpdateTexture(id:Int, offsetX:Int, offsetY:Int, width:Int, height:Int, format:Int, data:Dynamic):Void {
		throw "rlUpdateTexture is unsupported";
	}

	/** rlgl's `rlGetGlTextureFormats`: get opengl internal formats, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param format  As rlgl takes it.
		@param glInternalFormat  As rlgl takes it.
		@param glFormat  As rlgl takes it.
		@param glType  As rlgl takes it. */
	@:unsupported("rlGetGlTextureFormats: Not supported: helix-raylib has no GL texture ids; a Texture2D is made with LoadTextureAsync, in helix.raylib.extras.Textures (import helix.raylib.extras.Textures.*;), or LoadTextureFromImage, set up with SetTextureFilter, and drawn with rlSetTexture or the drawing functions.")
	static function rlGetGlTextureFormats(format:Int, glInternalFormat:Array<Int>, glFormat:Array<Int>, glType:Array<Int>):Void {
		throw "rlGetGlTextureFormats is unsupported";
	}

	/** rlgl's `rlUnloadTexture`: unload texture from gpu memory, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param id  As rlgl takes it. */
	@:unsupported("rlUnloadTexture: Not supported: helix-raylib has no GL texture ids; a Texture2D is made with LoadTextureAsync, in helix.raylib.extras.Textures (import helix.raylib.extras.Textures.*;), or LoadTextureFromImage, set up with SetTextureFilter, and drawn with rlSetTexture or the drawing functions.")
	static function rlUnloadTexture(id:Int):Void {
		throw "rlUnloadTexture is unsupported";
	}

	/** rlgl's `rlGenTextureMipmaps`: generate mipmap data for selected texture, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param id  As rlgl takes it.
		@param width  As rlgl takes it.
		@param height  As rlgl takes it.
		@param format  As rlgl takes it.
		@param mipmaps  As rlgl takes it. */
	@:unsupported("rlGenTextureMipmaps: Not supported: helix-raylib has no GL texture ids; a Texture2D is made with LoadTextureAsync, in helix.raylib.extras.Textures (import helix.raylib.extras.Textures.*;), or LoadTextureFromImage, set up with SetTextureFilter, and drawn with rlSetTexture or the drawing functions.")
	static function rlGenTextureMipmaps(id:Int, width:Int, height:Int, format:Int, mipmaps:Array<Int>):Void {
		throw "rlGenTextureMipmaps is unsupported";
	}

	/** rlgl's `rlReadTexturePixels`: read texture pixel data, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param id  As rlgl takes it.
		@param width  As rlgl takes it.
		@param height  As rlgl takes it.
		@param format  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlReadTexturePixels: Not supported: helix-raylib has no GL texture ids; a Texture2D is made with LoadTextureAsync, in helix.raylib.extras.Textures (import helix.raylib.extras.Textures.*;), or LoadTextureFromImage, set up with SetTextureFilter, and drawn with rlSetTexture or the drawing functions.")
	static function rlReadTexturePixels(id:Int, width:Int, height:Int, format:Int):Dynamic {
		throw "rlReadTexturePixels is unsupported";
	}

	/** rlgl's `rlReadScreenPixels`: read screen pixel data (color buffer), which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param width  As rlgl takes it.
		@param height  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlReadScreenPixels: Not supported: helix-raylib has no GL framebuffers; a RenderTexture2D is made with LoadRenderTexture and drawn into between BeginTextureMode and EndTextureMode.")
	static function rlReadScreenPixels(width:Int, height:Int):haxe.io.Bytes {
		throw "rlReadScreenPixels is unsupported";
	}

	/** rlgl's `rlLoadFramebuffer`: load an empty framebuffer, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlLoadFramebuffer: Not supported: helix-raylib has no GL framebuffers; a RenderTexture2D is made with LoadRenderTexture and drawn into between BeginTextureMode and EndTextureMode.")
	static function rlLoadFramebuffer():Int {
		throw "rlLoadFramebuffer is unsupported";
	}

	/** rlgl's `rlFramebufferAttach`: attach texture/renderbuffer to a framebuffer, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param fboId  As rlgl takes it.
		@param texId  As rlgl takes it.
		@param attachType  As rlgl takes it.
		@param texType  As rlgl takes it.
		@param mipLevel  As rlgl takes it. */
	@:unsupported("rlFramebufferAttach: Not supported: helix-raylib has no GL framebuffers; a RenderTexture2D is made with LoadRenderTexture and drawn into between BeginTextureMode and EndTextureMode.")
	static function rlFramebufferAttach(fboId:Int, texId:Int, attachType:Int, texType:Int, mipLevel:Int):Void {
		throw "rlFramebufferAttach is unsupported";
	}

	/** rlgl's `rlFramebufferComplete`: verify framebuffer is complete, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param id  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlFramebufferComplete: Not supported: helix-raylib has no GL framebuffers; a RenderTexture2D is made with LoadRenderTexture and drawn into between BeginTextureMode and EndTextureMode.")
	static function rlFramebufferComplete(id:Int):Bool {
		throw "rlFramebufferComplete is unsupported";
	}

	/** rlgl's `rlUnloadFramebuffer`: delete framebuffer from gpu, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param id  As rlgl takes it. */
	@:unsupported("rlUnloadFramebuffer: Not supported: helix-raylib has no GL framebuffers; a RenderTexture2D is made with LoadRenderTexture and drawn into between BeginTextureMode and EndTextureMode.")
	static function rlUnloadFramebuffer(id:Int):Void {
		throw "rlUnloadFramebuffer is unsupported";
	}

	/** rlgl's `rlLoadShaderCode`: load shader from code strings, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param vsCode  As rlgl takes it.
		@param fsCode  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlLoadShaderCode: Not supported: helix-raylib has no GL shader ids; a Shader is compiled as the program builds by LoadShader, set with SetShaderValue, and used between BeginShaderMode and EndShaderMode.")
	static function rlLoadShaderCode(vsCode:String, fsCode:String):Int {
		throw "rlLoadShaderCode is unsupported";
	}

	/** rlgl's `rlCompileShader`: compile custom shader and return shader id (type: rl_vertex_shader, rl_fragment_shader, rl_compute_shader), which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param shaderCode  As rlgl takes it.
		@param type  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlCompileShader: Not supported: helix-raylib has no GL shader ids; a Shader is compiled as the program builds by LoadShader, set with SetShaderValue, and used between BeginShaderMode and EndShaderMode.")
	static function rlCompileShader(shaderCode:String, type:Int):Int {
		throw "rlCompileShader is unsupported";
	}

	/** rlgl's `rlLoadShaderProgram`: load custom shader program, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param vShaderId  As rlgl takes it.
		@param fShaderId  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlLoadShaderProgram: Not supported: helix-raylib has no GL shader ids; a Shader is compiled as the program builds by LoadShader, set with SetShaderValue, and used between BeginShaderMode and EndShaderMode.")
	static function rlLoadShaderProgram(vShaderId:Int, fShaderId:Int):Int {
		throw "rlLoadShaderProgram is unsupported";
	}

	/** rlgl's `rlUnloadShaderProgram`: unload shader program, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param id  As rlgl takes it. */
	@:unsupported("rlUnloadShaderProgram: Not supported: helix-raylib has no GL shader ids; a Shader is compiled as the program builds by LoadShader, set with SetShaderValue, and used between BeginShaderMode and EndShaderMode.")
	static function rlUnloadShaderProgram(id:Int):Void {
		throw "rlUnloadShaderProgram is unsupported";
	}

	/** rlgl's `rlGetLocationUniform`: get shader location uniform, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param shaderId  As rlgl takes it.
		@param uniformName  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlGetLocationUniform: Not supported: helix-raylib has no GL shader ids; a Shader is compiled as the program builds by LoadShader, set with SetShaderValue, and used between BeginShaderMode and EndShaderMode.")
	static function rlGetLocationUniform(shaderId:Int, uniformName:String):Int {
		throw "rlGetLocationUniform is unsupported";
	}

	/** rlgl's `rlGetLocationAttrib`: get shader location attribute, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param shaderId  As rlgl takes it.
		@param attribName  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlGetLocationAttrib: Not supported: helix-raylib has no GL shader ids; a Shader is compiled as the program builds by LoadShader, set with SetShaderValue, and used between BeginShaderMode and EndShaderMode.")
	static function rlGetLocationAttrib(shaderId:Int, attribName:String):Int {
		throw "rlGetLocationAttrib is unsupported";
	}

	/** rlgl's `rlSetUniform`: set shader value uniform, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param locIndex  As rlgl takes it.
		@param value  As rlgl takes it.
		@param uniformType  As rlgl takes it.
		@param count  As rlgl takes it. */
	@:unsupported("rlSetUniform: Not supported: helix-raylib has no GL shader ids; a Shader is compiled as the program builds by LoadShader, set with SetShaderValue, and used between BeginShaderMode and EndShaderMode.")
	static function rlSetUniform(locIndex:Int, value:Dynamic, uniformType:Int, count:Int):Void {
		throw "rlSetUniform is unsupported";
	}

	/** rlgl's `rlSetUniformMatrix`: set shader value matrix, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param locIndex  As rlgl takes it.
		@param mat  As rlgl takes it. */
	@:unsupported("rlSetUniformMatrix: Not supported: helix-raylib has no GL shader ids; a Shader is compiled as the program builds by LoadShader, set with SetShaderValue, and used between BeginShaderMode and EndShaderMode.")
	static function rlSetUniformMatrix(locIndex:Int, mat:Matrix):Void {
		throw "rlSetUniformMatrix is unsupported";
	}

	/** rlgl's `rlSetUniformMatrices`: set shader value matrices, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param locIndex  As rlgl takes it.
		@param mat  As rlgl takes it.
		@param count  As rlgl takes it. */
	@:unsupported("rlSetUniformMatrices: Not supported: helix-raylib has no GL shader ids; a Shader is compiled as the program builds by LoadShader, set with SetShaderValue, and used between BeginShaderMode and EndShaderMode.")
	static function rlSetUniformMatrices(locIndex:Int, mat:Array<Matrix>, count:Int):Void {
		throw "rlSetUniformMatrices is unsupported";
	}

	/** rlgl's `rlSetUniformSampler`: set shader value sampler, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param locIndex  As rlgl takes it.
		@param textureId  As rlgl takes it. */
	@:unsupported("rlSetUniformSampler: Not supported: helix-raylib has no GL shader ids; a Shader is compiled as the program builds by LoadShader, set with SetShaderValue, and used between BeginShaderMode and EndShaderMode.")
	static function rlSetUniformSampler(locIndex:Int, textureId:Int):Void {
		throw "rlSetUniformSampler is unsupported";
	}

	/** rlgl's `rlSetShader`: set shader currently active (id and locations), which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param id  As rlgl takes it.
		@param locs  As rlgl takes it. */
	@:unsupported("rlSetShader: Not supported: helix-raylib has no GL shader ids; a Shader is compiled as the program builds by LoadShader, set with SetShaderValue, and used between BeginShaderMode and EndShaderMode.")
	static function rlSetShader(id:Int, locs:Array<Int>):Void {
		throw "rlSetShader is unsupported";
	}

	/** rlgl's `rlLoadComputeShaderProgram`: load compute shader program, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param shaderId  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlLoadComputeShaderProgram: Not supported: helix-raylib has no compute shaders or shader storage buffers, as WebGL2 has none.")
	static function rlLoadComputeShaderProgram(shaderId:Int):Int {
		throw "rlLoadComputeShaderProgram is unsupported";
	}

	/** rlgl's `rlComputeShaderDispatch`: dispatch compute shader (equivalent to *draw* for graphics pipeline), which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param groupX  As rlgl takes it.
		@param groupY  As rlgl takes it.
		@param groupZ  As rlgl takes it. */
	@:unsupported("rlComputeShaderDispatch: Not supported: helix-raylib has no compute shaders or shader storage buffers, as WebGL2 has none.")
	static function rlComputeShaderDispatch(groupX:Int, groupY:Int, groupZ:Int):Void {
		throw "rlComputeShaderDispatch is unsupported";
	}

	/** rlgl's `rlLoadShaderBuffer`: load shader storage buffer object (ssbo), which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param size  As rlgl takes it.
		@param data  As rlgl takes it.
		@param usageHint  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlLoadShaderBuffer: Not supported: helix-raylib has no compute shaders or shader storage buffers, as WebGL2 has none.")
	static function rlLoadShaderBuffer(size:Int, data:Dynamic, usageHint:Int):Int {
		throw "rlLoadShaderBuffer is unsupported";
	}

	/** rlgl's `rlUnloadShaderBuffer`: unload shader storage buffer object (ssbo), which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param ssboId  As rlgl takes it. */
	@:unsupported("rlUnloadShaderBuffer: Not supported: helix-raylib has no compute shaders or shader storage buffers, as WebGL2 has none.")
	static function rlUnloadShaderBuffer(ssboId:Int):Void {
		throw "rlUnloadShaderBuffer is unsupported";
	}

	/** rlgl's `rlUpdateShaderBuffer`: update ssbo buffer data, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param id  As rlgl takes it.
		@param data  As rlgl takes it.
		@param dataSize  As rlgl takes it.
		@param offset  As rlgl takes it. */
	@:unsupported("rlUpdateShaderBuffer: Not supported: helix-raylib has no compute shaders or shader storage buffers, as WebGL2 has none.")
	static function rlUpdateShaderBuffer(id:Int, data:Dynamic, dataSize:Int, offset:Int):Void {
		throw "rlUpdateShaderBuffer is unsupported";
	}

	/** rlgl's `rlBindShaderBuffer`: bind ssbo buffer, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param id  As rlgl takes it.
		@param index  As rlgl takes it. */
	@:unsupported("rlBindShaderBuffer: Not supported: helix-raylib has no compute shaders or shader storage buffers, as WebGL2 has none.")
	static function rlBindShaderBuffer(id:Int, index:Int):Void {
		throw "rlBindShaderBuffer is unsupported";
	}

	/** rlgl's `rlReadShaderBuffer`: read ssbo buffer data (gpu->cpu), which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param id  As rlgl takes it.
		@param dest  As rlgl takes it.
		@param count  As rlgl takes it.
		@param offset  As rlgl takes it. */
	@:unsupported("rlReadShaderBuffer: Not supported: helix-raylib has no compute shaders or shader storage buffers, as WebGL2 has none.")
	static function rlReadShaderBuffer(id:Int, dest:Dynamic, count:Int, offset:Int):Void {
		throw "rlReadShaderBuffer is unsupported";
	}

	/** rlgl's `rlCopyShaderBuffer`: copy ssbo data between buffers, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param destId  As rlgl takes it.
		@param srcId  As rlgl takes it.
		@param destOffset  As rlgl takes it.
		@param srcOffset  As rlgl takes it.
		@param count  As rlgl takes it. */
	@:unsupported("rlCopyShaderBuffer: Not supported: helix-raylib has no compute shaders or shader storage buffers, as WebGL2 has none.")
	static function rlCopyShaderBuffer(destId:Int, srcId:Int, destOffset:Int, srcOffset:Int, count:Int):Void {
		throw "rlCopyShaderBuffer is unsupported";
	}

	/** rlgl's `rlGetShaderBufferSize`: get ssbo buffer size, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param id  As rlgl takes it.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("rlGetShaderBufferSize: Not supported: helix-raylib has no compute shaders or shader storage buffers, as WebGL2 has none.")
	static function rlGetShaderBufferSize(id:Int):Int {
		throw "rlGetShaderBufferSize is unsupported";
	}

	/** rlgl's `rlBindImageTexture`: bind image texture, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.

		@param id  As rlgl takes it.
		@param index  As rlgl takes it.
		@param format  As rlgl takes it.
		@param readonly  As rlgl takes it. */
	@:unsupported("rlBindImageTexture: Not supported: helix-raylib has no GL texture ids; a Texture2D is made with LoadTextureAsync, in helix.raylib.extras.Textures (import helix.raylib.extras.Textures.*;), or LoadTextureFromImage, set up with SetTextureFilter, and drawn with rlSetTexture or the drawing functions.")
	static function rlBindImageTexture(id:Int, index:Int, format:Int, readonly:Bool):Void {
		throw "rlBindImageTexture is unsupported";
	}

	/** rlgl's `rlLoadDrawCube`: load and draw a cube, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.
	 */
	@:unsupported("rlLoadDrawCube: Not supported: helix-raylib has no GL of its own: InitWindow and CloseWindow set up and close what it draws with.")
	static function rlLoadDrawCube():Void {
		throw "rlLoadDrawCube is unsupported";
	}

	/** rlgl's `rlLoadDrawQuad`: load and draw a quad, which helix-raylib doesn't have, as it
		draws through helix-platform, not GL, so a call doesn't compile.
	 */
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
