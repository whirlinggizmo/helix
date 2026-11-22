package helix.jolt;

/** Provides the bodies by their ids, returned by `PhysicsSystem.GetBodyLockInterfaceNoLock`. The module runs on one thread, so a body is
	read without a lock. */
class BodyLockInterfaceNoLock {
	function new() {}

	/** Returns a body by its id.

		The `Body` returned for an id is the same object each time, so a call allocates nothing.
		@param inBodyID  The body's id.
		@return  The body, or null when the id names no body. */
	public function TryGetBody(inBodyID:BodyID):Null<Body> {
		throw "not built yet";
	}
}
