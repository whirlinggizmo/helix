package helix.platform.adapters.shared;

/** Provides how the window adapters answer their requests at the events' poll, which is where what happens to the window is seen: each
	request leaves a check, run after each `IEvents.poll` until it has answered. */
@:noCompletion
class WindowAnswers {
	static var checks:Array<Void->Bool> = [];

	/** Leaves a check, run first after the next poll, so it never answers during the call that asked.

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
