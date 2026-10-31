package helix.ray;

/** Represents raylib's `AutomationEventList`: the events recorded, or loaded from a file, to be played. */
class AutomationEventList {
	/** Gets or sets the most events it holds: 16384, raylib's MAX_AUTOMATION_EVENTS, for one `LoadAutomationEventList` or
		`LoadAutomationEventListAsync` made. */
	public var capacity:Int = 0;

	/** Gets or sets how many events it holds. */
	public var count:Int = 0;

	/** Gets or sets the events, `count` of them. */
	public var events:Array<AutomationEvent> = [];

	/** Creates an empty list, of no capacity. */
	public function new() {}
}
