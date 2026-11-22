package helix.box2d;

/** The contact events of the last step, buffered in the world. Box2D fills it. Read the events right after the step, as the next step replaces them, and destroying bodies or shapes can make them invalid. */
class B2ContactEvents {
	/** The begin touch events, from index 0 up to `beginCount`. The array may be longer when it is reused. */
	public var beginEvents:Array<B2ContactBeginTouchEvent>;

	/** The end touch events, from index 0 up to `endCount`. The array may be longer when it is reused. */
	public var endEvents:Array<B2ContactEndTouchEvent>;

	/** The hit events, from index 0 up to `hitCount`. The array may be longer when it is reused. */
	public var hitEvents:Array<B2ContactHitEvent>;

	/** The number of begin touch events. */
	public var beginCount:Int;

	/** The number of end touch events. */
	public var endCount:Int;

	/** The number of hit events. */
	public var hitCount:Int;

	/** Creates one, its fields zero. */
	public function new() {
		throw "not built yet";
	}
}
