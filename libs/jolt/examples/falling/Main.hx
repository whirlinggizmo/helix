import helix.jolt.*;
import helix.jolt.Jolt.*;

/** A box falling onto the floor, its height printed each quarter of a second until it rests: the world, its layers, two bodies and
	the step, with helix-jolt alone. */
class Main {
	static inline final NON_MOVING = 0;
	static inline final MOVING = 1;

	static function main():Void {
		Jolt.loadAsync(() -> {
			var objectFilter = new ObjectLayerPairFilterTable(2);
			objectFilter.EnableCollision(NON_MOVING, MOVING);
			objectFilter.EnableCollision(MOVING, MOVING);
			var broadPhaseLayers = new BroadPhaseLayerInterfaceTable(2, 2);
			broadPhaseLayers.MapObjectToBroadPhaseLayer(NON_MOVING, new BroadPhaseLayer(0));
			broadPhaseLayers.MapObjectToBroadPhaseLayer(MOVING, new BroadPhaseLayer(1));
			var settings = new JoltSettings();
			settings.mObjectLayerPairFilter = objectFilter;
			settings.mBroadPhaseLayerInterface = broadPhaseLayers;
			settings.mObjectVsBroadPhaseLayerFilter = new ObjectVsBroadPhaseLayerFilterTable(broadPhaseLayers, 2, objectFilter, 2);
			var jolt = new JoltInterface(settings);
			var bodyInterface = jolt.GetPhysicsSystem().GetBodyInterface();

			bodyInterface.CreateAndAddBody(new BodyCreationSettings(new BoxShape(new Vec3(10, 0.5, 10)), new RVec3(0, -0.5, 0), Quat.sIdentity(),
				EMotionType_Static, NON_MOVING),
				EActivation_DontActivate);
			var box = bodyInterface.CreateAndAddBody(new BodyCreationSettings(new BoxShape(new Vec3(0.5, 0.5, 0.5)), new RVec3(0, 5, 0), Quat.sIdentity(),
				EMotionType_Dynamic, MOVING),
				EActivation_Activate);

			var position = new RVec3();
			var step = 0;
			while (bodyInterface.IsActive(box)) {
				jolt.Step(1 / 60, 1);
				if (++step % 15 == 0)
					trace('${step / 60} s: ${Math.round(bodyInterface.GetPosition(box, position).y * 1000) / 1000} m');
			}
			trace('at rest after ${step / 60} s');
			Jolt.destroy(jolt);
		});
	}
}
