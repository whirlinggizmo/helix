package helix.box2d;

/** The sensor events of the last step, buffered in the world. Box2D fills it. Read the events right after the step, as the next step replaces them, and destroying bodies or shapes can make them invalid. */
class B2SensorEvents {
	/** The sensor begin touch events, from index 0 up to `beginCount`. The array may be longer when it is reused. */
	public var beginEvents:Array<B2SensorBeginTouchEvent>;

	/** The sensor end touch events, from index 0 up to `endCount`. The array may be longer when it is reused. */
	public var endEvents:Array<B2SensorEndTouchEvent>;

	/** The number of sensor begin touch events. */
	public var beginCount:Int;

	/** The number of sensor end touch events. */
	public var endCount:Int;

	/** Creates one, its fields zero. */
	public function new() {
		throw "not built yet";
	}
}
