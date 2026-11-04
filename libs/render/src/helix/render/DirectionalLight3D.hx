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

	function writeLight(out:Array<Float>, at:Int):Void {
		Light3D.writePoint(0, 0, 0, 0, out, at);
		Light3D.writeDirection(direction.x, direction.y, direction.z, 0, out, at + 4);
		Light3D.writeRadiance(color, intensity, out, at + 8);
		Light3D.writePoint(1, 1, -1, 0, out, at + 12);
	}
}
