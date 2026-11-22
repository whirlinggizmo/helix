package helix.box2d;

/** The joint events of the last step, buffered in the world. Box2D fills it. Read the events right after the step, as the next step replaces them, and destroying joints makes them invalid. */
class B2JointEvents {
	/** The joint events, from index 0 up to `count`. The array may be longer when it is reused. */
	public var jointEvents:Array<B2JointEvent>;

	/** The number of joint events. */
	public var count:Int;

	/** Creates one, its fields zero. */
	public function new() {
		throw "not built yet";
	}
}
