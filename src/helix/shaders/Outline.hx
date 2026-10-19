package helix.shaders;

import helix.render3d.Model;
import helix.render3d.ModelPass;

/** An outline round a model: a pass (ModelPass) drawing the model again after the stage's opaque models, pushed out along its normals by a
	width in world units, its front faces culled, so the far side of that shell shows as a band past the model's edges, in a flat color; depth
	tested, so what's nearer covers it. Static or skinned, instanced like the model. Edges where the model's normals split (a cube's corners)
	open gaps as wide as the width. Made on a model, it draws from then on; remove takes it off. */
class Outline extends ModelPass {
	/** How far the outline reaches past the model's surface, world units, 0 or more. Under 0, or NaN, is 0. */
	public var width(get, set):Float;

	function get_width():Float
		return push;

	function set_width(value:Float):Float {
		value = value > 0 ? value : 0;
		push = value;
		return value;
	}

	/** Outlines model in color (0xRRGGBBAA, sRGB: black by default; its alpha ignored, an outline is opaque), width world units wide (.02 by
		default; under 0 is 0). */
	public function new(model:Model, color = 0x000000ff, width = .02) {
		super(model, color, 0, false);
		this.width = width;
	}
}
