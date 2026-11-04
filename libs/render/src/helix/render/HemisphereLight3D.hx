package helix.render;

import helix.math.Vector3D;

/** Represents light from the sky above and the ground below: a surface facing up gets the sky's color, one facing down the ground's, one
	between a blend, from no one direction. It is three.js's HemisphereLight, and casts no shadows. */
class HemisphereLight3D extends Light3D {
	/** Gets or sets the ground's color, 0xAARRGGBB, its alpha ignored: the sky's is `color`. Dark grey until set. */
	public var groundColor:Int = 0xff404040;

	/** Gets the way up, the sky's side, in world units: +y until changed. */
	public final up = new Vector3D(0, 1, 0);

	/** Creates a hemisphere light of intensity π: a white sky over a dark grey ground. */
	public function new() {
		super();
	}

	function writeLight(out:Array<Float>, at:Int):Void {
		Light3D.writeRadiance(groundColor, intensity, out, at);
		Light3D.writeDirection(up.x, up.y, up.z, 3, out, at + 4);
		Light3D.writeRadiance(color, intensity, out, at + 8);
		Light3D.writePoint(0, 0, -1, 0, out, at + 12);
	}
}
