package helix.jolt;

/** Represents what hears of contacts between bodies during a step, set with `PhysicsSystem.SetContactListener`. Made as a
	`ContactEventQueue`. */
class ContactListener {
	function new() {}

	/** Starts listening to a world's steps. */
	@:allow(helix.jolt) function attach(world:Int):Void {}

	/** Stops listening. */
	@:allow(helix.jolt) function detach():Void {}

	/** Reads what a step recorded. */
	@:allow(helix.jolt) function stepped(world:Int):Void {}
}
