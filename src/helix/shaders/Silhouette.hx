package helix.shaders;

import helix.render3d.Model;
import helix.render3d.ModelPass;

/** A model seen through what hides it: a pass (ModelPass) drawing the model's shape where something nearer hides it (depth greater), in a
	flat color blended by its alpha, over the stage's other opaque models and sprites; the model itself is drawn after it, so its own parts
	never hide it (layered clothes, hair over a head). Static or skinned, instanced like the model. Made on a model, it draws from then on;
	remove takes it off. */
class Silhouette extends ModelPass {
	/** Shows model where it's hidden in color (0xAARRGGBB, sRGB, blended by its alpha): a light blue at 60% by default. */
	public function new(model:Model, color = 0x993fa9ff)
		super(model, color, 0, true);
}
