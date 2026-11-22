package helix.box2d;

/** Describes the motion of a body or shape for a time of impact computation. The body moves linearly from its starting to its ending center of mass and rotation. */
class B2Sweep {
	/** The center of mass in the body's frame. */
	public var localCenter:B2Vec2;

	/** The center of mass in the world at the start. */
	public var c1:B2Vec2;

	/** The center of mass in the world at the end. */
	public var c2:B2Vec2;

	/** The rotation in the world at the start. */
	public var q1:B2Rot;

	/** The rotation in the world at the end. */
	public var q2:B2Rot;

	/** Creates one, its fields zero. */
	public function new() {
		throw "not built yet";
	}
}
