package helix.render3d;

/** The sun: everything lit from one direction, its node's -z (aim it with lookAt or setRotation), wherever it is. It may cast shadows
	(shadowCasting), over what the camera sees out to its shadow distance. */
class DirectionalLight extends Light {
	/** A white directional light of intensity 1 shining down its -z. */
	public function new()
		super();
}
