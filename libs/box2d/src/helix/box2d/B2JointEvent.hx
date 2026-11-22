package helix.box2d;

/** Reports an awake joint whose force or torque exceeds its threshold. The force and torque themselves are not reported. */
class B2JointEvent {
	/** The id of the joint. */
	public var jointId:B2JointId;

	/** The `userData` of the joint, returned as set. */
	public var userData:Dynamic;

	/** Creates one, its fields zero. */
	public function new() {
		helix.box2d.internal.Init.initB2JointEvent(this);
	}
}
