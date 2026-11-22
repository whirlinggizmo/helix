package helix.jolt;

import helix.jolt.internal.Hj;

/** Provides the bodies by their ids, returned by `PhysicsSystem.GetBodyLockInterfaceNoLock`. The module runs on one thread, so a body is
	read without a lock. */
class BodyLockInterfaceNoLock {
	var world:Int;
	var bodies = new Map<Int, Body>();

	@:allow(helix.jolt) function new(world:Int) {
		this.world = world;
	}

	/** Returns the `Body` for an id, made the first time. */
	@:allow(helix.jolt) function body(inBodyID:BodyID):Body {
		var key = inBodyID.GetIndexAndSequenceNumber();
		var found = bodies.get(key);
		if (found == null) {
			found = new Body(world, inBodyID);
			bodies.set(key, found);
		}
		return found;
	}

	/** Lets go of a destroyed body's `Body`. */
	@:allow(helix.jolt) function forget(inBodyID:BodyID):Void {
		bodies.remove(inBodyID.GetIndexAndSequenceNumber());
	}

	/** Returns a body by its id.

		The `Body` returned for an id is the same object each time, so a call allocates nothing.
		@param inBodyID  The body's id.
		@return  The body, or null when the id names no body. */
	public function TryGetBody(inBodyID:BodyID):Null<Body> {
		return Hj.bodyExists(world, inBodyID.GetIndexAndSequenceNumber()) != 0 ? body(inBodyID) : null;
	}
}
