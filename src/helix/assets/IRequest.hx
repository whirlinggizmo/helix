package helix.assets;

/** Host-thread cancellation. Completion is asynchronous and exactly once. */
interface IRequest {
	/** Cancels the operation if it has not settled, so its completion reports Cancelled; does nothing once settled. */
	function cancel():Void;
}
