package helix.box2d;

/** The body events of the last step, buffered in the world. Box2D fills it. Read the events right after the step, as the next step replaces them, and destroying bodies makes them invalid. */
class B2BodyEvents {
	/** The move events, from index 0 up to `moveCount`. The array may be longer when it is reused. */
	public var moveEvents:Array<B2BodyMoveEvent>;

	/** The number of move events. */
	public var moveCount:Int;

	/** Creates one, its fields zero. */
	public function new() {
		throw "not built yet";
	}
}
