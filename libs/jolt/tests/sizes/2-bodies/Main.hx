// helix-jolt's size ladder (tools/gen_sizes.py): each rung adds one thing to the one before; this one a box falling onto a floor and its position read.
import helix.jolt.*;
import helix.jolt.Jolt.*;

/** A program on helix-jolt alone, constructing only what it uses. */
@:adds("helix.jolt.BodyCreationSettings", "helix.jolt.BoxShape", "helix.jolt.ConvexShape", "helix.jolt.MassProperties", "helix.math.Matrix4",
	"helix.math.Matrix4Storage", "helix.math.Quaternion", "helix.math.Vector3")
class Main {
	static function main():Void {
		Jolt.loadAsync(() -> {
			var objectFilter = new ObjectLayerPairFilterTable(2);
			objectFilter.EnableCollision(0, 1);
			objectFilter.EnableCollision(1, 1);
			var broadPhaseLayers = new BroadPhaseLayerInterfaceTable(2, 2);
			broadPhaseLayers.MapObjectToBroadPhaseLayer(0, new BroadPhaseLayer(0));
			broadPhaseLayers.MapObjectToBroadPhaseLayer(1, new BroadPhaseLayer(1));
			var settings = new JoltSettings();
			settings.mObjectLayerPairFilter = objectFilter;
			settings.mBroadPhaseLayerInterface = broadPhaseLayers;
			settings.mObjectVsBroadPhaseLayerFilter = new ObjectVsBroadPhaseLayerFilterTable(broadPhaseLayers, 2, objectFilter, 2);
			var jolt = new JoltInterface(settings);
			var system = jolt.GetPhysicsSystem();
			var bodies = system.GetBodyInterface();
			bodies.CreateAndAddBody(new BodyCreationSettings(new BoxShape(new Vec3(10, 0.5, 10)), new RVec3(0, -0.5, 0), Quat.sIdentity(), EMotionType_Static,
				0),
				EActivation_DontActivate);
			var box = bodies.CreateAndAddBody(new BodyCreationSettings(new BoxShape(new Vec3(0.5, 0.5, 0.5)), new RVec3(0, 5, 0), Quat.sIdentity(),
				EMotionType_Dynamic, 1),
				EActivation_Activate);
			var position = new RVec3();
			for (step in 0...60) {
				jolt.Step(1 / 60, 1);
			}
			trace(bodies.GetPosition(box, position).y);
			Jolt.destroy(jolt);
		});
	}
}
