package helix.shader;

import helix.render3d.Model3D;
import helix.render3d.ModelPass3D;

/** An outline round a model: a pass (ModelPass3D) drawing the model again after the stage's opaque models, pushed out by a width in world
	units, its front faces culled, so the far side of that shell shows as a band past the model's edges, in a flat color; depth tested, so
	what's nearer covers it. Static or skinned, instanced like the model. Each vertex is pushed along its normal averaged over the vertices at
	its place (Mesh3D.passVertices), so where a low-poly model's normals split at its hard edges the shell stays closed; a flat face between hard
	edges moves out less than the width (a cube's by .58 of it, its corners along their diagonals). A model's separate meshes are pushed
	apart each on its own. Made on a model, it draws from then on; remove takes it off. */
class Outline extends ModelPass3D {
	/** How far the outline reaches past the model's surface, world units, 0 or more. Under 0, or NaN, is 0. */
	public var width(get, set):Float;

	function get_width():Float
		return push;

	function set_width(value:Float):Float {
		value = value > 0 ? value : 0;
		push = value;
		return value;
	}

	/** Outlines model in color (0xAARRGGBB, sRGB: black by default; its alpha ignored, an outline is opaque), width world units wide (.02 by
		default; under 0 is 0). */
	public function new(model:Model3D, color = 0xff000000, width = .02) {
		super(model, color, 0, false);
		this.width = width;
	}
}
