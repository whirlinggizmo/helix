package helix.asset;

/** Host-thread cancellation. Completion is asynchronous and exactly once. */
interface IRequest {
	/** Cancels the operation if it has not settled: a load's lambdas aren't called (an operation with a result enum reports Cancelled); does
		nothing once settled. */
	function cancel():Void;
}
