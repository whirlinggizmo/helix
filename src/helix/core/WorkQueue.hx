package helix.core;

/** Cooperative host work. Individual operations can exceed the nominal budget. */
class WorkQueue {
	var pending:Array<Void->Void> = [];
	var budgetMs = 2.;

	public function getBudgetMs():Float
		return budgetMs;

	/** False for a budget under 0. */
	public function setBudgetMs(value:Float):Bool {
		if (!(value >= 0))
			return false;
		budgetMs = value;
		return true;
	}

	public function new() {}

	public function add(work:Void->Void):Void
		pending.push(work);

	public function poll():Void {
		var start = haxe.Timer.stamp(), count = pending.length;
		for (_ in 0...count) {
			pending.shift()();
			if ((haxe.Timer.stamp() - start) * 1000 >= budgetMs)
				break;
		}
	}
}
