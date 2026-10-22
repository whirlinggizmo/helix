package helix.render3d;

/** The sun: everything lit from one direction, its node's -z (aim it with lookAt or setRotation), wherever it is. It may cast shadows
	(shadowCasting), over what the camera sees out to its shadow distance. */
class DirectionalLight3D extends Light3D {
	/** A white directional light of intensity π shining down its -z: lit as glTF lights a surface (its diffuse its color over π), a surface
		facing it shows its own color, as written, before the ambient light and the tone mapping. */
	public function new() {
		super();
		intensity = Math.PI;
	}
}
