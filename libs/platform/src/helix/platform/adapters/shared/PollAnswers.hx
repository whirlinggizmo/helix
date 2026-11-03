package helix.platform.adapters.shared;

/** Provides how adapters answer their requests at the events' poll, never during the call that asked: the window's, the mouse's lock
	and the clipboard's. Each request leaves a check, run after each `IEvents.poll` until it has answered. */
@:noCompletion
class PollAnswers {
	static var checks:Array<Void->Bool> = [];

	/** Leaves a check, run first after the next poll, so it never answers during the call that asked. A request whose answer is known
		at once leaves a check that answers and returns true.

		@param check  Answers the request when it can, returning whether it has. */
	public static function add(check:Void->Bool):Void
		checks.push(check);

	/** Runs every check left, keeping those that haven't answered; call after the events' poll. A check left during one is run at the
		next poll. */
	public static function poll():Void {
		if (checks.length == 0)
			return;
		var due = checks;
		checks = [];
		var kept = [for (check in due) if (!check()) check];
		checks = kept.concat(checks);
	}
}
