package helix.assets;

/** The IRequest the services and adapters return: it settles exactly once, by finish or by cancel. */
class Request implements IRequest {
	var settled = false;

	/** Whether it has finished or been cancelled. */
	public function isSettled():Bool
		return settled;

	var cancelled:Void->Void;

	/** cancelled runs once, when cancel settles the request. */
	public function new(cancelled:Void->Void) {
		this.cancelled = cancelled;
	}

	/** Settles the request: true the first time, false once it has finished or been cancelled. */
	public function finish():Bool {
		if (settled)
			return false;
		settled = true;
		return true;
	}

	public function cancel():Void {
		if (finish())
			cancelled();
	}
}
