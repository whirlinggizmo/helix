package helix.box2d;

/** The time each part of the last world step used, in milliseconds. `b2World_GetProfile` returns one that Box2D fills. */
class B2Profile {
	/** Milliseconds spent: the whole step. */
	public var step:Float;

	/** Milliseconds spent: updating the broad-phase pairs, which finds new contacts. */
	public var pairs:Float;

	/** Milliseconds spent: updating contacts, the narrow phase. */
	public var collide:Float;

	/** Milliseconds spent: the solver stage, all of the constraint solving and integration. */
	public var solve:Float;

	/** Milliseconds spent: preparing the solver's data for the step. */
	public var solverSetup:Float;

	/** Milliseconds spent: solving the constraints, in all its stages. */
	public var constraints:Float;

	/** Milliseconds spent: preparing the contact and joint constraints. */
	public var prepareConstraints:Float;

	/** Milliseconds spent: integrating velocities from forces and gravity. */
	public var integrateVelocities:Float;

	/** Milliseconds spent: warm starting the constraints with the last step's impulses. */
	public var warmStart:Float;

	/** Milliseconds spent: solving the constraints' impulses. */
	public var solveImpulses:Float;

	/** Milliseconds spent: integrating positions from velocities. */
	public var integratePositions:Float;

	/** Milliseconds spent: relaxing the constraints' impulses. */
	public var relaxImpulses:Float;

	/** Milliseconds spent: applying restitution. */
	public var restitution:Float;

	/** Milliseconds spent: storing impulses to warm start the next step. */
	public var storeImpulses:Float;

	/** Milliseconds spent: splitting islands that are no longer connected. */
	public var splitIslands:Float;

	/** Milliseconds spent: updating the transforms and broad-phase boxes of bodies that moved. */
	public var transforms:Float;

	/** Milliseconds spent: finding sensor overlaps for moving shapes. */
	public var sensorHits:Float;

	/** Milliseconds spent: reporting joint events. */
	public var jointEvents:Float;

	/** Milliseconds spent: reporting contact hit events. */
	public var hitEvents:Float;

	/** Milliseconds spent: refitting the broad-phase trees. */
	public var refit:Float;

	/** Milliseconds spent: continuous collision for bullet bodies. */
	public var bullets:Float;

	/** Milliseconds spent: putting islands to sleep. */
	public var sleepIslands:Float;

	/** Milliseconds spent: updating sensor events. */
	public var sensors:Float;

	/** Creates one, its fields zero. */
	public function new() {
		helix.box2d.internal.Init.initB2Profile(this);
	}
}
