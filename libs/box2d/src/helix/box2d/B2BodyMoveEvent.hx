package helix.box2d;

/** Reports a body that moved in the simulation, with its new transform. It is not reported for a body the program moved. It is an efficient way to update the program's own objects, as only the bodies that moved are listed. With sleeping disabled, every dynamic and kinematic body is reported each step. */
class B2BodyMoveEvent {
	/** The `userData` of the body, returned as set. */
	public var userData:Dynamic;

	/** The new transform of the body, in the world. */
	public var transform:B2WorldTransform;

	/** The id of the body that moved. */
	public var bodyId:B2BodyId;

	/** Whether the body fell asleep in this step. A body that didn't can be treated as awake. */
	public var fellAsleep:Bool;

	/** Creates one, its fields zero. */
	public function new() {
		throw "not built yet";
	}
}
