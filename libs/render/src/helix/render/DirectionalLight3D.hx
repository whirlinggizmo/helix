package helix.render;

import helix.math.Vector3D;

/** Represents the sun: light from one direction, reaching everything alike, wherever it is.

	```haxe
	var sun = new DirectionalLight3D();
	sun.direction.set(-1, -2, -1);
	batch.lights.push(sun);
	``` */
class DirectionalLight3D extends Light3D {
	/** Gets the direction it shines in, in world units; it needn't be of length 1. Straight down until changed; a direction of length 0
		is taken as straight down. */
	public final direction = new Vector3D(0, -1, 0);

	/** Creates a white directional light of intensity π shining straight down: a surface facing it shows its own color. */
	public function new() {
		super();
	}
}
