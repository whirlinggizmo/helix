package helix.asset;

/** The IRequest the asset service and audio resources return for work they settle themselves (Jobs returns its own): it settles exactly once, by finish or by cancel. */
class Request implements IRequest {
	/** Whether it has finished or been cancelled. */
	@:isVar public var settled(get, null):Bool = false;

	function get_settled():Bool
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
