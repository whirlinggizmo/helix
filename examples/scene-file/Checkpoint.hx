import helix.behavior.Behavior;
import helix.render3d.Node3D;

/** A checkpoint on its node: when the race's car comes within radius of it (across the ground, x and z), it tells the race it passed
	this index, every frame it is near; the race takes only the next index, so a lap counts each once. The race is the Race behavior on
	race (a node reference, "@race" in the file), found through the pass once both have started. */
class Checkpoint extends Behavior {
	/** Its index along the lap, from 0 at the start line. */
	@:prop @:range(0, 64) public var index = 0;

	/** How near the car must come, m. */
	@:prop @:range(0.1, 100) public var radius = 10.;

	/** The node the Race behavior is on. */
	@:prop public var race:Node3D = null;

	var found:Null<Race>;

	/** Finds its race once it has started, registers its index, and tells the race when the car is near. */
	override public function update(dt:Float):Void {
		if (found == null) {
			found = race != null ? pass.on(race, Race) : null;
			if (found == null)
				return;
			found.register(index);
		}
		var car = found.car;
		if (car == null)
			return;
		var dx = car.x - node.x, dz = car.z - node.z;
		if (dx * dx + dz * dz <= radius * radius)
			found.reach(index);
	}
}
