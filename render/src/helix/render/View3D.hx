package helix.render;

import helix.geometry.Camera3D;
import helix.math.Bounds3D;
import helix.math.Matrix3D;

/** Represents one view a `Batch3D` draws through: where the eye is and how it projects, as matrices, and the rectangle of the pass it
	fills.

	`Batch3D.begin(camera)` makes one from a camera. A program gives its own to `Batch3D.beginViews` for what a camera can't say: a
	projection of its own (an off-center frustum, a view offset, a zoom, rlgl's matrix stack), 2D in pixels (`setFromScreen`), or
	several views drawn at once, each draw drawn once in each: the two eyes of a headset (WebXR's views, raylib's stereo mode, three.js's
	ArrayCamera), or split screens that see one scene. `isInView` tests a box against it at any time, so a scene walked before the
	batch opens is culled by the views it will be drawn through.

	```haxe
	var left = new View3D(), right = new View3D();
	left.viewMatrix.copyFrom(eyeViews[0]);
	left.projectionMatrix.copyFrom(eyeProjections[0]);
	left.setViewport(0, 0, width >> 1, height);
	right.viewMatrix.copyFrom(eyeViews[1]);
	right.projectionMatrix.copyFrom(eyeProjections[1]);
	right.setViewport(width >> 1, 0, width >> 1, height);
	batch.beginViews([left, right]);
	```

	**In a shader.** Each view is a block a shader reads by `#include <helix/render/view.glsl>` (block `View`, both stages), written once
	a view and shared with every draw in it (helix-services' `ShaderScene`), never copied per draw; `Batch2D` writes one for its camera
	or the viewport. A shader that declares one of its names itself, as raylib's declare `viewProjection`'s kin, is written it per
	draw instead.

	| Name | Type | What |
	|---|---|---|
	| `viewMatrix`, `projectionMatrix`, `viewProjection` | mat4 | The view's matrices, and the projection after the view. |
	| `cameraPosition` | vec4 | The eye, in world units. |
	| `viewportSize` | vec4 | Its rectangle's width and height in framebuffer pixels, and their inverses. |
	| `linearTarget` | int | 1 in an RGBA16F target, which holds linear light; 0 in an RGBA8 target or the screen, which hold sRGB. |
	| `exposure`, `toneMapping` | float, int | `Renderer.exposure` as a multiplier (2 to the stops), and `Renderer.toneMapping`. |
	| `fogColor`, `fogParams` | vec4 | The fog's color as stored, and its mode, near, far and density. |

	**Colors in a shader.** `#include <helix/render/color.glsl>` (either stage; it includes `view.glsl`) gives the conversions helix-render's
	own shaders make, and declares `toneMapped` (int: the material's; for a batch draw `Batch3D.toneMapped`; 0 for `Batch2D`'s) for
	`writeColor`:

	```glsl
	vec3 decodeSrgb(vec3 color);           // sRGB to linear
	vec4 decodeSrgb(vec4 color);           // alpha unchanged
	vec3 encodeSrgb(vec3 linear);          // linear to sRGB
	vec4 encodeSrgb(vec4 linear);
	vec3 applyToneMapping(vec3 linear);    // times exposure, then toneMapping: 0 to 1
	vec3 applyFog(vec3 linear, vec3 worldPosition); // toward the fog's color, decoded, by the fog at the eye's distance; unchanged without fog
	vec4 encodeColor(vec4 linear);         // for the target: encoded into sRGB, unchanged into linear (linearTarget); never tone mapped
	vec4 writeColor(vec4 linear);          // as encodeColor, after applyToneMapping into sRGB where toneMapped is 1
	```

	The batches' own draws multiply their colors as stored, and write the product as it is into an sRGB target unless fog or tone
	mapping reaches it (`Batch3D`); a material writes by `writeColor`, through `material.glsl`'s `writeMaterialColor`. */
class View3D {
	/** Gets the matrix that puts the world into the eye's space, +y up and looking down -z: changed in place, read at `beginViews`. */
	public final viewMatrix = new Matrix3D();

	/** Gets the matrix that projects the eye's space into GL's clip space (depth -1 to 1), as `Camera3D.computeProjectionMatrix` makes
		it: changed in place, read at `beginViews`. */
	public final projectionMatrix = new Matrix3D();

	/** Gets the left edge of the rectangle it fills, in the pass's pixels from the left of the renderer's viewport: 0 until set. */
	public var viewportX(default, null):Int = 0;

	/** Gets the top edge of the rectangle it fills, in the pass's pixels from the top of the renderer's viewport: 0 until set. */
	public var viewportY(default, null):Int = 0;

	/** Gets the width of the rectangle it fills, in pixels: 0 until set, for the whole of the renderer's viewport. */
	public var viewportWidth(default, null):Int = 0;

	/** Gets the height of the rectangle it fills, in pixels: 0 until set, for the whole of the renderer's viewport. */
	public var viewportHeight(default, null):Int = 0;

	/** Creates a view with identity matrices, filling the renderer's viewport. */
	public function new() {}

	/** Sets the matrices to a camera's.

		@param camera  The camera.
		@param aspect  The width of what it fills over its height.
		@return  This view. */
	public function setFromCamera(camera:Camera3D, aspect:Float):View3D {
		throw "helix-render: View3D.setFromCamera is not yet built (stage 1)";
	}

	/** Sets the matrices to draw in pixels: the view identity, and an orthographic projection with x from 0 at the left to `width` at
		the right and y from 0 at the top to `height` at the bottom, z from 0 (nearest) to -1 (farthest), as raylib's 2D draws without a
		camera (`rlOrtho(0, width, height, 0, 0, 1)`).

		Sprites, shapes and text drawn by `Batch3D` in their plane (y down the texture) are then upright, a unit a pixel. A 2D camera is
		its matrix copied into `viewMatrix` after, as raylib's `BeginMode2D` multiplies it in.
		@param width  The width it spans, in pixels: the rectangle's, or the renderer's viewport's.
		@param height  The height it spans, in pixels.
		@return  This view. */
	public function setFromScreen(width:Float, height:Float):View3D {
		throw "helix-render: View3D.setFromScreen is not yet built (stage 1)";
	}

	/** Returns whether a box may be seen through this view: whether it is in the frustum of its matrices as they are now.

		It may be called at any time, a batch open or not, as a three.js layer culls its scene while walking it before `beginViews`.
		`Batch3D`'s culling makes the same test against every view it draws through.
		@param bounds  The box, in world units.
		@return  True when some of it may be in the frustum; false when all of it is out. */
	public function isInView(bounds:Bounds3D):Bool {
		throw "helix-render: View3D.isInView is not yet built (stage 1)";
	}

	/** Sets the rectangle of the renderer's viewport it fills.

		@param x  The left edge, in pixels from the viewport's left.
		@param y  The top edge, in pixels from the viewport's top.
		@param width  The width, in pixels; 0 with a height of 0 for the whole viewport.
		@param height  The height, in pixels.
		@return  This view. */
	public function setViewport(x:Int, y:Int, width:Int, height:Int):View3D {
		throw "helix-render: View3D.setViewport is not yet built (stage 1)";
	}
}
