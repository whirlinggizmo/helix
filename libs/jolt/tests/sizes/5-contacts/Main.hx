// helix-jolt's size ladder (tools/gen_sizes.py): each rung adds one thing to the one before; this one a sensor and the contact events of each step.
import helix.jolt.*;
import helix.jolt.Jolt.*;

/** A program on helix-jolt alone, constructing only what it uses. */
@:adds("helix.jolt.ContactEvent", "helix.jolt.ContactEventQueue")
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
			var hull = new ConvexHullShapeSettings();
			hull.mPoints = [
				for (x in [-1, 1])
					for (y in [-1, 1])
						for (z in [-1, 1])
							new Vec3(x * 0.5, y * 0.5, z * 0.5)
			];
			var vertices:VertexList = [
				new Float3(-5, 0, -5),
				new Float3(5, 0, -5),
				new Float3(-5, 0, 5),
				new Float3(5, 0, 5)
			];
			var triangles:IndexedTriangleList = [new IndexedTriangle(0, 2, 1), new IndexedTriangle(1, 2, 3)];
			bodies.CreateAndAddBody(new BodyCreationSettings(new MeshShapeSettings(vertices, triangles).Create().Get(), new RVec3(20, 0, 0), Quat.sIdentity(),
				EMotionType_Static, 0),
				EActivation_DontActivate);
			var shapes:Array<Shape> = [new SphereShape(0.5), new CapsuleShape(0.5, 0.3), hull.Create().Get()];
			for (i in 0...shapes.length)
				bodies.CreateAndAddBody(new BodyCreationSettings(shapes[i], new RVec3(20 + i * 2 - 2, 3, 0), Quat.sIdentity(), EMotionType_Dynamic, 1),
					EActivation_Activate);
			var trigger = new BodyCreationSettings(new BoxShape(new Vec3(1, 1, 1)), new RVec3(0, 1, 0), Quat.sIdentity(), EMotionType_Static, 0);
			trigger.mIsSensor = true;
			bodies.CreateAndAddBody(trigger, EActivation_DontActivate);
			var contacts = new ContactEventQueue(256);
			system.SetContactListener(contacts);
			var event = new ContactEvent();
			var added = 0;
			for (step in 0...60) {
				jolt.Step(1 / 60, 1);
				for (i in 0...contacts.GetNumEvents()) {
					contacts.GetEvent(i, event);
					if (event.mType == EContactEventType_Added)
						added++;
				}
			}
			trace(bodies.GetPosition(box, position).y);
			var closest = new CastRayClosestHitCollisionCollector();
			system.GetNarrowPhaseQuery().CastRay(new RRayCast(new RVec3(0, 20, 0), new Vec3(0, -40, 0)), new RayCastSettings(), closest);
			var overlaps = new CollideShapeAllHitCollisionCollector();
			system.GetNarrowPhaseQuery()
				.CollideShape(new SphereShape(1), new Vec3(1, 1, 1), Mat44.sTranslation(new Vec3(0, 1, 0)), new CollideShapeSettings(), new RVec3(), overlaps);
			trace(closest.HadHit(), overlaps.HadHit());
			trace(added);
			Jolt.destroy(jolt);
		});
	}
}
