package helix.jolt;

import helix.jolt.internal.Hj;
import helix.jolt.internal.Io;

/** Represents a physics world: a `PhysicsSystem` with the memory and the thread it steps on.

	```haxe
	var jolt = new JoltInterface(settings);
	var bodyInterface = jolt.GetPhysicsSystem().GetBodyInterface();
	// each frame:
	jolt.Step(1 / 60, 1);
	```

	`Jolt.destroy` destroys the world and what is in it. */
class JoltInterface {
	/** Creates a world.

		@param inSettings  The limits and the layers. Read once. The layer objects are kept. */
	public function new(inSettings:JoltSettings) {
		Jolt.ensureLoaded();
		var objectPairs = inSettings.mObjectLayerPairFilter,
			broadPhaseLayers = inSettings.mBroadPhaseLayerInterface;
		var numObjectLayers = objectPairs.numObjectLayers;
		var base = Io.bulk((numObjectLayers + numObjectLayers * numObjectLayers) * 4);
		for (layer in 0...numObjectLayers)
			Io.setBulkI(base, layer, layer < broadPhaseLayers.map.length ? broadPhaseLayers.map[layer] : 0);
		for (n in 0...numObjectLayers * numObjectLayers)
			Io.setBulkI(base, numObjectLayers + n, objectPairs.pairs[n] ? 1 : 0);
		world = Hj.worldCreate(inSettings.mMaxBodies, inSettings.mMaxBodyPairs, inSettings.mMaxContactConstraints, numObjectLayers,
			broadPhaseLayers.numBroadPhaseLayers);
		settings = inSettings;
		system = new PhysicsSystem(world);
	}

	/** Advances the world.

		Contact events recorded by a `ContactEventQueue` set on the system are cleared, then refilled during the step.
		@param inDeltaTime  The seconds to advance. A fixed step (1 / 60) keeps the world deterministic.
		@param inCollisionSteps  The collision steps the time is split into; 1 at 60 steps a second, more for a longer step. */
	public function Step(inDeltaTime:Float, inCollisionSteps:Int):Void {
		Constraint.writeMotors(world);
		Hj.worldStep(world, inDeltaTime, inCollisionSteps);
		system.stepped();
	}

	/** Returns the world's physics system.

		@return  The system. */
	public function GetPhysicsSystem():PhysicsSystem {
		return system;
	}

	/** Returns the filter deciding which object layers collide.

		@return  The filter from the settings. */
	public function GetObjectLayerPairFilter():ObjectLayerPairFilter {
		return settings.mObjectLayerPairFilter;
	}

	/** Returns the map from object layers to broad phase layers.

		@return  The map from the settings. */
	public function GetBroadPhaseLayerInterface():BroadPhaseLayerInterface {
		return settings.mBroadPhaseLayerInterface;
	}

	/** Returns the filter deciding which broad phase layers each object layer meets.

		@return  The filter from the settings. */
	public function GetObjectVsBroadPhaseLayerFilter():ObjectVsBroadPhaseLayerFilter {
		return settings.mObjectVsBroadPhaseLayerFilter;
	}

	/** Returns the body standing for the world, which a constraint fixes a body to.

		Its id (`GetID`) is the invalid id, which `BodyInterface.CreateConstraint` reads as the world.
		@return  The body. */
	public static function sGetFixedToWorldBody():Body {
		if (fixedToWorld == null)
			fixedToWorld = new Body(-1, new BodyID());
		return fixedToWorld;
	}

	/** Returns the bytes the module has reserved.

		Natively, 0, as Jolt allocates from the program's own memory.
		@return  The bytes. */
	public static function sGetTotalMemory():Int {
		return Hj.totalMemory();
	}

	/** Returns the bytes of the module's reserved memory not in use.

		Natively, 0, as Jolt allocates from the program's own memory.
		@return  The bytes. */
	public static function sGetFreeMemory():Int {
		return Hj.freeMemory();
	}

	@:allow(helix.jolt) var world:Int;
	var settings:JoltSettings;
	var system:PhysicsSystem;

	static var fixedToWorld:Body;
}
