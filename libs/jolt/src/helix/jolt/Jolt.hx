package helix.jolt;

import helix.jolt.internal.Hj;

/** Provides the Jolt Physics module: loading the module, and destroying what a program made in it.

	A program loads the module once, before it constructs anything in this package:

	```haxe
	import helix.jolt.*;
	import helix.jolt.Jolt.*;

	Jolt.loadAsync(() -> {
		var settings = new JoltSettings();
		settings.mObjectLayerPairFilter = objectFilter;
		settings.mBroadPhaseLayerInterface = broadPhaseLayers;
		settings.mObjectVsBroadPhaseLayerFilter = new ObjectVsBroadPhaseLayerFilterTable(broadPhaseLayers, 2, objectFilter, 2);
		jolt = new JoltInterface(settings);
	});
	```

	Natively, Jolt is compiled into the program, and `loadAsync` calls `loaded` before returning. In a page, `loadAsync` fetches the
	module (`jolt.wasm`) and calls `loaded` once the module runs.

	The build of Jolt the module holds is single precision, single threaded, and cross-platform deterministic: the same steps from the
	same state produce the same bits natively and in a page.

	Jolt's value types (`Vec3`, `Quat`, the settings, a query's results) are Haxe objects, which the garbage collector frees. What Jolt
	holds (a `JoltInterface`, a body, a shape, a constraint) lives in the module until it is destroyed or released.

	Jolt's constants are on this class, as JoltPhysics.js has them on its module: `Jolt.EMotionType_Dynamic`, or `EMotionType_Dynamic`
	after `import helix.jolt.Jolt.*;`. */
class Jolt {
	/** The `EActivation` value EActivation_Activate: Wakes the body. */
	public static inline final EActivation_Activate:EActivation = EActivation.EActivation_Activate;

	/** The `EActivation` value EActivation_DontActivate: Leaves the body asleep or awake as it is. */
	public static inline final EActivation_DontActivate:EActivation = EActivation.EActivation_DontActivate;

	/** The `EAllowedDOFs` value EAllowedDOFs_TranslationX: Moving along x. */
	public static inline final EAllowedDOFs_TranslationX:EAllowedDOFs = EAllowedDOFs.EAllowedDOFs_TranslationX;

	/** The `EAllowedDOFs` value EAllowedDOFs_TranslationY: Moving along y. */
	public static inline final EAllowedDOFs_TranslationY:EAllowedDOFs = EAllowedDOFs.EAllowedDOFs_TranslationY;

	/** The `EAllowedDOFs` value EAllowedDOFs_TranslationZ: Moving along z. */
	public static inline final EAllowedDOFs_TranslationZ:EAllowedDOFs = EAllowedDOFs.EAllowedDOFs_TranslationZ;

	/** The `EAllowedDOFs` value EAllowedDOFs_RotationX: Turning about x. */
	public static inline final EAllowedDOFs_RotationX:EAllowedDOFs = EAllowedDOFs.EAllowedDOFs_RotationX;

	/** The `EAllowedDOFs` value EAllowedDOFs_RotationY: Turning about y. */
	public static inline final EAllowedDOFs_RotationY:EAllowedDOFs = EAllowedDOFs.EAllowedDOFs_RotationY;

	/** The `EAllowedDOFs` value EAllowedDOFs_RotationZ: Turning about z. */
	public static inline final EAllowedDOFs_RotationZ:EAllowedDOFs = EAllowedDOFs.EAllowedDOFs_RotationZ;

	/** The `EAllowedDOFs` value EAllowedDOFs_Plane2D: Moving along x and y and turning about z: a body in 2D. */
	public static inline final EAllowedDOFs_Plane2D:EAllowedDOFs = EAllowedDOFs.EAllowedDOFs_Plane2D;

	/** The `EAllowedDOFs` value EAllowedDOFs_All: Moving and turning freely. */
	public static inline final EAllowedDOFs_All:EAllowedDOFs = EAllowedDOFs.EAllowedDOFs_All;

	/** The `EBackFaceMode` value EBackFaceMode_IgnoreBackFaces: Only a face's front is hit. */
	public static inline final EBackFaceMode_IgnoreBackFaces:EBackFaceMode = EBackFaceMode.EBackFaceMode_IgnoreBackFaces;

	/** The `EBackFaceMode` value EBackFaceMode_CollideWithBackFaces: Both sides of a face are hit. */
	public static inline final EBackFaceMode_CollideWithBackFaces:EBackFaceMode = EBackFaceMode.EBackFaceMode_CollideWithBackFaces;

	/** The `EBodyType` value EBodyType_RigidBody: A rigid body. */
	public static inline final EBodyType_RigidBody:EBodyType = EBodyType.EBodyType_RigidBody;

	/** The `EBodyType` value EBodyType_SoftBody: A soft body, which this module doesn't make. */
	public static inline final EBodyType_SoftBody:EBodyType = EBodyType.EBodyType_SoftBody;

	/** The `EConstraintSpace` value EConstraintSpace_LocalToBodyCOM: Each body's own, from its center of mass. */
	public static inline final EConstraintSpace_LocalToBodyCOM:EConstraintSpace = EConstraintSpace.EConstraintSpace_LocalToBodyCOM;

	/** The `EConstraintSpace` value EConstraintSpace_WorldSpace: The world's, as the bodies are placed when the constraint is made. */
	public static inline final EConstraintSpace_WorldSpace:EConstraintSpace = EConstraintSpace.EConstraintSpace_WorldSpace;

	/** The `EConstraintSubType` value EConstraintSubType_Fixed: Made by `FixedConstraintSettings`. */
	public static inline final EConstraintSubType_Fixed:EConstraintSubType = EConstraintSubType.EConstraintSubType_Fixed;

	/** The `EConstraintSubType` value EConstraintSubType_Point: Made by `PointConstraintSettings`. */
	public static inline final EConstraintSubType_Point:EConstraintSubType = EConstraintSubType.EConstraintSubType_Point;

	/** The `EConstraintSubType` value EConstraintSubType_Hinge: Made by `HingeConstraintSettings`. */
	public static inline final EConstraintSubType_Hinge:EConstraintSubType = EConstraintSubType.EConstraintSubType_Hinge;

	/** The `EConstraintSubType` value EConstraintSubType_Slider: Made by `SliderConstraintSettings`. */
	public static inline final EConstraintSubType_Slider:EConstraintSubType = EConstraintSubType.EConstraintSubType_Slider;

	/** The `EConstraintSubType` value EConstraintSubType_Distance: Made by `DistanceConstraintSettings`. */
	public static inline final EConstraintSubType_Distance:EConstraintSubType = EConstraintSubType.EConstraintSubType_Distance;

	/** The `EConstraintSubType` value EConstraintSubType_Cone: Made by `ConeConstraintSettings`. */
	public static inline final EConstraintSubType_Cone:EConstraintSubType = EConstraintSubType.EConstraintSubType_Cone;

	/** The `EConstraintSubType` value EConstraintSubType_SwingTwist: A swing twist constraint, for a ragdoll's joints. */
	public static inline final EConstraintSubType_SwingTwist:EConstraintSubType = EConstraintSubType.EConstraintSubType_SwingTwist;

	/** The `EConstraintSubType` value EConstraintSubType_SixDOF: Made by `SixDOFConstraintSettings`. */
	public static inline final EConstraintSubType_SixDOF:EConstraintSubType = EConstraintSubType.EConstraintSubType_SixDOF;

	/** The `EConstraintType` value EConstraintType_Constraint: A constraint on one body. */
	public static inline final EConstraintType_Constraint:EConstraintType = EConstraintType.EConstraintType_Constraint;

	/** The `EConstraintType` value EConstraintType_TwoBodyConstraint: A constraint between two bodies. */
	public static inline final EConstraintType_TwoBodyConstraint:EConstraintType = EConstraintType.EConstraintType_TwoBodyConstraint;

	/** The `EContactEventType` value EContactEventType_Added: The bodies started touching, as Jolt's `ContactListener.OnContactAdded` reports. A sensor's body entering it. */
	public static inline final EContactEventType_Added:EContactEventType = EContactEventType.EContactEventType_Added;

	/** The `EContactEventType` value EContactEventType_Persisted: The bodies were touching and still are, as Jolt's `ContactListener.OnContactPersisted` reports. */
	public static inline final EContactEventType_Persisted:EContactEventType = EContactEventType.EContactEventType_Persisted;

	/** The `EContactEventType` value EContactEventType_Removed: The bodies stopped touching, as Jolt's `ContactListener.OnContactRemoved` reports. A sensor's body leaving it. */
	public static inline final EContactEventType_Removed:EContactEventType = EContactEventType.EContactEventType_Removed;

	/** The `EMotionQuality` value EMotionQuality_Discrete: Tested where the body is at each step, so a fast, thin body may pass through another. */
	public static inline final EMotionQuality_Discrete:EMotionQuality = EMotionQuality.EMotionQuality_Discrete;

	/** The `EMotionQuality` value EMotionQuality_LinearCast: Cast along its motion each step, so a fast body stops at what it would pass through: a bullet. */
	public static inline final EMotionQuality_LinearCast:EMotionQuality = EMotionQuality.EMotionQuality_LinearCast;

	/** The `EMotionType` value EMotionType_Static: Never moves: the ground, a wall. */
	public static inline final EMotionType_Static:EMotionType = EMotionType.EMotionType_Static;

	/** The `EMotionType` value EMotionType_Kinematic: Moved by the program (`BodyInterface.MoveKinematic`), pushing dynamic bodies aside. */
	public static inline final EMotionType_Kinematic:EMotionType = EMotionType.EMotionType_Kinematic;

	/** The `EMotionType` value EMotionType_Dynamic: Moved by the simulation: falling, pushed, thrown. */
	public static inline final EMotionType_Dynamic:EMotionType = EMotionType.EMotionType_Dynamic;

	/** The `EMotorState` value EMotorState_Off: Nothing: the motor is off. */
	public static inline final EMotorState_Off:EMotorState = EMotorState.EMotorState_Off;

	/** The `EMotorState` value EMotorState_Velocity: A target velocity. */
	public static inline final EMotorState_Velocity:EMotorState = EMotorState.EMotorState_Velocity;

	/** The `EMotorState` value EMotorState_Position: A target position or angle. */
	public static inline final EMotorState_Position:EMotorState = EMotorState.EMotorState_Position;

	/** The `EMotorState` value EMotorState_PositionAndVelocity: A target position or angle, at a target velocity. */
	public static inline final EMotorState_PositionAndVelocity:EMotorState = EMotorState.EMotorState_PositionAndVelocity;

	/** The `EOverrideMassProperties` value EOverrideMassProperties_CalculateMassAndInertia: Both from the shape and its density. */
	public static inline final EOverrideMassProperties_CalculateMassAndInertia:EOverrideMassProperties = EOverrideMassProperties.EOverrideMassProperties_CalculateMassAndInertia;

	/** The `EOverrideMassProperties` value EOverrideMassProperties_CalculateInertia: The mass from `BodyCreationSettings.mMassPropertiesOverride`, the inertia from the shape scaled to it. */
	public static inline final EOverrideMassProperties_CalculateInertia:EOverrideMassProperties = EOverrideMassProperties.EOverrideMassProperties_CalculateInertia;

	/** The `EOverrideMassProperties` value EOverrideMassProperties_MassAndInertiaProvided: Both from `BodyCreationSettings.mMassPropertiesOverride`. */
	public static inline final EOverrideMassProperties_MassAndInertiaProvided:EOverrideMassProperties = EOverrideMassProperties.EOverrideMassProperties_MassAndInertiaProvided;

	/** The `EShapeSubType` value EShapeSubType_Sphere: `SphereShape`. */
	public static inline final EShapeSubType_Sphere:EShapeSubType = EShapeSubType.EShapeSubType_Sphere;

	/** The `EShapeSubType` value EShapeSubType_Box: `BoxShape`. */
	public static inline final EShapeSubType_Box:EShapeSubType = EShapeSubType.EShapeSubType_Box;

	/** The `EShapeSubType` value EShapeSubType_Capsule: `CapsuleShape`. */
	public static inline final EShapeSubType_Capsule:EShapeSubType = EShapeSubType.EShapeSubType_Capsule;

	/** The `EShapeSubType` value EShapeSubType_TaperedCapsule: A shape made by `TaperedCapsuleShapeSettings`. */
	public static inline final EShapeSubType_TaperedCapsule:EShapeSubType = EShapeSubType.EShapeSubType_TaperedCapsule;

	/** The `EShapeSubType` value EShapeSubType_Cylinder: `CylinderShape`. */
	public static inline final EShapeSubType_Cylinder:EShapeSubType = EShapeSubType.EShapeSubType_Cylinder;

	/** The `EShapeSubType` value EShapeSubType_TaperedCylinder: A tapered cylinder, which this module doesn't make. */
	public static inline final EShapeSubType_TaperedCylinder:EShapeSubType = EShapeSubType.EShapeSubType_TaperedCylinder;

	/** The `EShapeSubType` value EShapeSubType_ConvexHull: A shape made by `ConvexHullShapeSettings`. */
	public static inline final EShapeSubType_ConvexHull:EShapeSubType = EShapeSubType.EShapeSubType_ConvexHull;

	/** The `EShapeSubType` value EShapeSubType_StaticCompound: A shape made by `StaticCompoundShapeSettings`. */
	public static inline final EShapeSubType_StaticCompound:EShapeSubType = EShapeSubType.EShapeSubType_StaticCompound;

	/** The `EShapeSubType` value EShapeSubType_MutableCompound: A mutable compound, which this module doesn't make. */
	public static inline final EShapeSubType_MutableCompound:EShapeSubType = EShapeSubType.EShapeSubType_MutableCompound;

	/** The `EShapeSubType` value EShapeSubType_RotatedTranslated: A shape made by `RotatedTranslatedShapeSettings`. */
	public static inline final EShapeSubType_RotatedTranslated:EShapeSubType = EShapeSubType.EShapeSubType_RotatedTranslated;

	/** The `EShapeSubType` value EShapeSubType_Scaled: `ScaledShape`. */
	public static inline final EShapeSubType_Scaled:EShapeSubType = EShapeSubType.EShapeSubType_Scaled;

	/** The `EShapeSubType` value EShapeSubType_OffsetCenterOfMass: `OffsetCenterOfMassShape`. */
	public static inline final EShapeSubType_OffsetCenterOfMass:EShapeSubType = EShapeSubType.EShapeSubType_OffsetCenterOfMass;

	/** The `EShapeSubType` value EShapeSubType_Mesh: A shape made by `MeshShapeSettings`. */
	public static inline final EShapeSubType_Mesh:EShapeSubType = EShapeSubType.EShapeSubType_Mesh;

	/** The `EShapeSubType` value EShapeSubType_HeightField: A shape made by `HeightFieldShapeSettings`. */
	public static inline final EShapeSubType_HeightField:EShapeSubType = EShapeSubType.EShapeSubType_HeightField;

	/** The `EShapeSubType` value EShapeSubType_Plane: `PlaneShape`. */
	public static inline final EShapeSubType_Plane:EShapeSubType = EShapeSubType.EShapeSubType_Plane;

	/** The `EShapeSubType` value EShapeSubType_Empty: `EmptyShape`. */
	public static inline final EShapeSubType_Empty:EShapeSubType = EShapeSubType.EShapeSubType_Empty;

	/** The `EShapeType` value EShapeType_Convex: A convex shape: box, sphere, capsule, cylinder, hull. */
	public static inline final EShapeType_Convex:EShapeType = EShapeType.EShapeType_Convex;

	/** The `EShapeType` value EShapeType_Compound: Shapes put together. */
	public static inline final EShapeType_Compound:EShapeType = EShapeType.EShapeType_Compound;

	/** The `EShapeType` value EShapeType_Decorated: A shape changed by another: scaled, moved, its center of mass offset. */
	public static inline final EShapeType_Decorated:EShapeType = EShapeType.EShapeType_Decorated;

	/** The `EShapeType` value EShapeType_Mesh: Triangles. */
	public static inline final EShapeType_Mesh:EShapeType = EShapeType.EShapeType_Mesh;

	/** The `EShapeType` value EShapeType_HeightField: A grid of heights. */
	public static inline final EShapeType_HeightField:EShapeType = EShapeType.EShapeType_HeightField;

	/** The `EShapeType` value EShapeType_Plane: A plane. */
	public static inline final EShapeType_Plane:EShapeType = EShapeType.EShapeType_Plane;

	/** The `EShapeType` value EShapeType_Empty: No shape. */
	public static inline final EShapeType_Empty:EShapeType = EShapeType.EShapeType_Empty;

	/** The `ESpringMode` value ESpringMode_FrequencyAndDamping: By `SpringSettings.mFrequency` and `mDamping`. */
	public static inline final ESpringMode_FrequencyAndDamping:ESpringMode = ESpringMode.ESpringMode_FrequencyAndDamping;

	/** The `ESpringMode` value ESpringMode_StiffnessAndDamping: By `SpringSettings.mStiffness` and `mDamping`. */
	public static inline final ESpringMode_StiffnessAndDamping:ESpringMode = ESpringMode.ESpringMode_StiffnessAndDamping;

	/** The `ESpringMode` value ESpringMode_MassNormalizedStiffnessAndDamping: By `SpringSettings.mStiffness` divided by the mass, and `mDamping`. */
	public static inline final ESpringMode_MassNormalizedStiffnessAndDamping:ESpringMode = ESpringMode.ESpringMode_MassNormalizedStiffnessAndDamping;

	/** The `SixDOFConstraintSettings_EAxis` value SixDOFConstraintSettings_EAxis_TranslationX: Moving along x. */
	public static inline final SixDOFConstraintSettings_EAxis_TranslationX:SixDOFConstraintSettings_EAxis = SixDOFConstraintSettings_EAxis.SixDOFConstraintSettings_EAxis_TranslationX;

	/** The `SixDOFConstraintSettings_EAxis` value SixDOFConstraintSettings_EAxis_TranslationY: Moving along y. */
	public static inline final SixDOFConstraintSettings_EAxis_TranslationY:SixDOFConstraintSettings_EAxis = SixDOFConstraintSettings_EAxis.SixDOFConstraintSettings_EAxis_TranslationY;

	/** The `SixDOFConstraintSettings_EAxis` value SixDOFConstraintSettings_EAxis_TranslationZ: Moving along z. */
	public static inline final SixDOFConstraintSettings_EAxis_TranslationZ:SixDOFConstraintSettings_EAxis = SixDOFConstraintSettings_EAxis.SixDOFConstraintSettings_EAxis_TranslationZ;

	/** The `SixDOFConstraintSettings_EAxis` value SixDOFConstraintSettings_EAxis_RotationX: Turning about x. */
	public static inline final SixDOFConstraintSettings_EAxis_RotationX:SixDOFConstraintSettings_EAxis = SixDOFConstraintSettings_EAxis.SixDOFConstraintSettings_EAxis_RotationX;

	/** The `SixDOFConstraintSettings_EAxis` value SixDOFConstraintSettings_EAxis_RotationY: Turning about y. */
	public static inline final SixDOFConstraintSettings_EAxis_RotationY:SixDOFConstraintSettings_EAxis = SixDOFConstraintSettings_EAxis.SixDOFConstraintSettings_EAxis_RotationY;

	/** The `SixDOFConstraintSettings_EAxis` value SixDOFConstraintSettings_EAxis_RotationZ: Turning about z. */
	public static inline final SixDOFConstraintSettings_EAxis_RotationZ:SixDOFConstraintSettings_EAxis = SixDOFConstraintSettings_EAxis.SixDOFConstraintSettings_EAxis_RotationZ;

	#if !macro
	/** Asynchronously loads the module.

		Calling it again after the module has loaded calls `loaded` again.

		_Note that in a page the module is `jolt.wasm` beside the page unless `wasmUrl` names another. The build copies it there with
		a line in the build's hxml:_

		```hxml
		--macro helix.jolt.Jolt.copyWasm("web")
		```

		@param loaded  Called once the module is ready.
		@param failed  Optional. Receives why the module couldn't be loaded; when omitted, it is thrown.
		@param wasmUrl  Optional. In a page, the module's URL; defaults to `jolt.wasm`. Ignored natively. */
	public static function loadAsync(loaded:Void->Void, ?failed:String->Void, ?wasmUrl:String):Void {
		if (loaded_) {
			loaded();
			return;
		}
		#if js
		var url = wasmUrl == null ? "jolt.wasm" : wasmUrl;
		var instantiate = (bytes:js.lib.ArrayBuffer) -> {
			var imports = {
				env: {emscripten_notify_memory_growth: (index:Int) -> {}},
				wasi_snapshot_preview1: {
					clock_time_get: (id:Int, precision:Dynamic, at:Int) -> {
						js.Syntax.code("new DataView(helixJolt.memory.buffer).setBigUint64({0}, 0n, true)", at);
						return 0;
					}
				}
			};
			js.lib.WebAssembly.instantiate(bytes, imports).then(result -> {
				var exports:Dynamic = result.instance.exports;
				js.Syntax.code("globalThis.helixJolt = {0}", exports);
				exports._initialize();
				Hj.init();
				loaded_ = true;
				loaded();
			}, error -> fail(failed, url + " couldn't be run: " + error));
		};
		if (js.Syntax.code("typeof process !== 'undefined' && process.versions != null && process.versions.node != null")) {
			var bytes:Dynamic = null;
			try {
				bytes = js.Syntax.code("require('fs').readFileSync({0})", url);
			} catch (error:Dynamic) {
				fail(failed, url + " couldn't be read: " + error);
				return;
			}
			instantiate(js.Syntax.code("{0}.buffer.slice({0}.byteOffset, {0}.byteOffset + {0}.byteLength)", bytes));
		} else
			js.Browser.window.fetch(url).then(response -> {
				if (!response.ok)
					fail(failed, url + " couldn't be fetched: " + response.status);
				else
					response.arrayBuffer().then(instantiate);
			}, error -> fail(failed, url + " couldn't be fetched: " + error));
		#else
		Hj.init();
		loaded_ = true;
		loaded();
		#end
	}

	/** Returns whether the module has loaded.

		@return  True once `loaded` has been called. */
	public static function isLoaded():Bool {
		return loaded_;
	}

	/** Destroys a `JoltInterface`, its `PhysicsSystem`, and every body, shape and constraint made in it, whether the program holds
		them or not.

		A call on what was destroyed (`Release` among them) is skipped after.
		@param inJoltInterface  The interface to destroy. */
	public static function destroy(inJoltInterface:JoltInterface):Void {
		Hj.worldDestroy(inJoltInterface.world);
		Constraint.forgetWorld(inJoltInterface.world);
		worlds--;
		if (worlds == 0)
			Shape.forgetAll();
	}
	#end

	/** Copies the module (`jolt.wasm`) into a directory as the program builds: a build macro, called from the build's hxml.

		Skipped natively, where Jolt is compiled into the program.
		@param directory  The page's directory, relative to the build's working directory. */
	public static macro function copyWasm(directory:String):haxe.macro.Expr {
		#if macro
		var here = haxe.io.Path.directory(haxe.io.Path.normalize(sys.FileSystem.absolutePath(haxe.macro.Context.resolvePath("helix/jolt/Jolt.hx"))));
		var source = haxe.io.Path.join([here, "..", "..", "..", "wasm", "jolt.wasm"]);
		if (haxe.macro.Context.defined("js")) {
			sys.FileSystem.createDirectory(directory);
			sys.io.File.copy(sys.FileSystem.absolutePath(source), haxe.io.Path.join([directory, "jolt.wasm"]));
		}
		#end
		return macro null;
	}

	#if !macro
	static var loaded_ = false;
	@:allow(helix.jolt) static var worlds = 0;

	static function fail(failed:Null<String->Void>, message:String):Void {
		if (failed != null)
			failed(message);
		else
			throw message;
	}

	/** Refuses a world made before the module has loaded, and counts it. */
	@:allow(helix.jolt) static function ensureLoaded():Void {
		if (!loaded_)
			throw "Jolt.loadAsync must have called loaded before a JoltInterface is made";
		worlds++;
	}
	#end
}
