import helix.behavior.Behavior;
import helix.render3d.Node3D;

/** A chase camera on its node (a Camera3D): it follows target from behind, distance back along the target's heading (its yaw, read from
	its rotation) and height up, easing toward that place with lag, and looks at a point a little above the target (Node3D.lookAt). Drawing
	only, so Math's trigonometry is fine here: nothing an autopilot probes depends on it. It runs Late, after the car has moved this
	frame, so it never trails it by one. */
@:phase(Late)
class ChaseCamera extends Behavior {
	/** The node followed. Null: the camera stays where it is. */
	@:prop public var target:Node3D = null;

	/** How far behind the target, m. */
	@:prop @:range(0.1, 100) public var distance = 9.;

	/** How high over the target's position, m. */
	@:prop @:range(0, 100) public var height = 3.5;

	/** Seconds the camera takes to close most of the way to its place: 0 snaps it there. */
	@:prop @:range(0, 10) public var lag = .25;

	/** How far above the target it looks, m. */
	@:prop @:range(0, 50) public var aimHeight = 1.;

	var placed = false;

	/** Eases the camera toward its place behind the target and turns it to look at the target. */
	override public function update(dt:Float):Void {
		if (target == null)
			return;
		// The target's forward: its local +z in the world, from its quaternion.
		var qx = target.quaternionX,
			qy = target.quaternionY,
			qz = target.quaternionZ,
			qw = target.quaternionW;
		var fx = 2 * (qx * qz + qw * qy), fz = 1 - 2 * (qx * qx + qy * qy);
		var length = Math.sqrt(fx * fx + fz * fz);
		if (length > 0) {
			fx /= length;
			fz /= length;
		}
		var wantX = target.x - fx * distance,
			wantY = target.y + height,
			wantZ = target.z - fz * distance;
		var share = !placed || lag <= 0 ? 1 : 1 - Math.exp(-dt / lag);
		placed = true;
		node.setPosition(node.x + (wantX - node.x) * share, node.y + (wantY - node.y) * share, node.z + (wantZ - node.z) * share);
		node.lookAt(target.x, target.y + aimHeight, target.z);
	}
}
