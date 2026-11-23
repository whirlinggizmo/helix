// helix-jolt's size ladder (tools/gen_sizes.py): each rung adds one thing to the one before; this one a world stepped: its layers, its settings and the step.
import helix.jolt.*;
import helix.jolt.Jolt.*;

/** A program on helix-jolt alone, constructing only what it uses. */
@:adds("helix.jolt.BodyInterface", "helix.jolt.BodyLockInterfaceNoLock", "helix.jolt.BroadPhaseLayerInterface", "helix.jolt.BroadPhaseLayerInterfaceTable",
	"helix.jolt.Constraint", "helix.jolt.ContactListener", "helix.jolt.Jolt", "helix.jolt.JoltInterface", "helix.jolt.JoltSettings",
	"helix.jolt.MotorSettings", "helix.jolt.NarrowPhaseQuery", "helix.jolt.ObjectLayerPairFilter", "helix.jolt.ObjectLayerPairFilterTable",
	"helix.jolt.ObjectVsBroadPhaseLayerFilter", "helix.jolt.ObjectVsBroadPhaseLayerFilterTable", "helix.jolt.PhysicsSystem", "helix.jolt.Shape",
	"helix.jolt.SpringSettings", "helix.jolt.internal.Io")
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
			for (step in 0...60) {
				jolt.Step(1 / 60, 1);
			}
			Jolt.destroy(jolt);
		});
	}
}
