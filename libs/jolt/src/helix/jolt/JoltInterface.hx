package helix.jolt;

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
		throw "not built yet";
	}

	/** Advances the world.

		Contact events recorded by a `ContactEventQueue` set on the system are cleared, then refilled during the step.
		@param inDeltaTime  The seconds to advance. A fixed step (1 / 60) keeps the world deterministic.
		@param inCollisionSteps  The collision steps the time is split into; 1 at 60 steps a second, more for a longer step. */
	public function Step(inDeltaTime:Float, inCollisionSteps:Int):Void {
		throw "not built yet";
	}

	/** Returns the world's physics system.

		@return  The system. */
	public function GetPhysicsSystem():PhysicsSystem {
		throw "not built yet";
	}

	/** Returns the filter deciding which object layers collide.

		@return  The filter from the settings. */
	public function GetObjectLayerPairFilter():ObjectLayerPairFilter {
		throw "not built yet";
	}

	/** Returns the map from object layers to broad phase layers.

		@return  The map from the settings. */
	public function GetBroadPhaseLayerInterface():BroadPhaseLayerInterface {
		throw "not built yet";
	}

	/** Returns the filter deciding which broad phase layers each object layer meets.

		@return  The filter from the settings. */
	public function GetObjectVsBroadPhaseLayerFilter():ObjectVsBroadPhaseLayerFilter {
		throw "not built yet";
	}

	/** Returns the body standing for the world, which a constraint fixes a body to.

		Its id (`GetID`) is the invalid id, which `BodyInterface.CreateConstraint` reads as the world.
		@return  The body. */
	public static function sGetFixedToWorldBody():Body {
		throw "not built yet";
	}

	/** Returns the bytes the module has reserved.

		@return  The bytes. */
	public static function sGetTotalMemory():Int {
		throw "not built yet";
	}

	/** Returns the bytes of the module's reserved memory not in use.

		@return  The bytes. */
	public static function sGetFreeMemory():Int {
		throw "not built yet";
	}
}
