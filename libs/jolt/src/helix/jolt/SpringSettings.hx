package helix.jolt;

/** Represents a spring: how a constraint's limit or motor pulls back, soft rather than at once. */
class SpringSettings {
	/** Gets or sets how the strength is set. Defaults to `ESpringMode_FrequencyAndDamping`. */
	public var mMode:ESpringMode = ESpringMode_FrequencyAndDamping;

	/** Gets or sets the frequency, in hertz: 0 is rigid, at once. Defaults to 0. */
	public var mFrequency:Float = 0;

	/** Gets or sets the stiffness, in newtons a meter, under `ESpringMode_StiffnessAndDamping`. Defaults to 0. */
	public var mStiffness:Float = 0;

	/** Gets or sets the damping: 0 swings forever, 1 settles without overshooting. Defaults to 0. */
	public var mDamping:Float = 0;

	/** Creates a rigid spring. */
	public function new() {}
}
