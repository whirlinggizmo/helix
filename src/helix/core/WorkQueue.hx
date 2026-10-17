package helix.core;

/** Cooperative host work. Individual operations can exceed the nominal budget. */
class WorkQueue {
	var pending:Array<Void->Void> = [];

	/** Milliseconds poll may spend before it leaves the rest for the next poll; 2 to start. 0 or more (under 0, or NaN, is 0). */
	public var budgetMs(default, set):Float = 2.;

	function set_budgetMs(value:Float):Float {
		value = value >= 0 ? value : 0;
		budgetMs = value;
		return value;
	}

	/** An empty queue with a 2 ms budget. */
	public function new() {}

	/** Whether no work is queued. */
	public var empty(get, never):Bool;

	function get_empty():Bool
		return pending.length == 0;

	/** Queues work for a later poll, in order. */
	public function add(work:Void->Void):Void
		pending.push(work);

	/** Runs queued work in order until the budget is spent (at least one item, when any is queued); work added meanwhile waits for the next poll. */
	public function poll():Void {
		var start = haxe.Timer.stamp(), count = pending.length;
		for (_ in 0...count) {
			pending.shift()();
			if ((haxe.Timer.stamp() - start) * 1000 >= budgetMs)
				break;
		}
	}
}
