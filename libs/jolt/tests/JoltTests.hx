import haxe.io.FPHelper;
import haxe.io.Float32Array;
import helix.jolt.*;
import helix.jolt.Jolt.*;

/** Checks helix-jolt on a page's module (Node) and natively: a world's layers and settings, every shape made directly and from
	settings, bodies made, moved and read one by one and in bulk, a stack falling to rest, a sensor's contact events, each query with each
	collector and filter, each constraint with its motor and limits, and destroying. Prints the checks and a digest of the scene's
	final state, every body's position and rotation as 32-bit floats, which helix.py compares between the targets: the same steps make
	the same bits. */
class JoltTests {
	static inline final NON_MOVING = 0;
	static inline final MOVING = 1;
	static inline final GHOST = 2;

	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float, tolerance = 1e-4):Bool
		return Math.abs(a - b) <= tolerance;

	static function main():Void {
		Jolt.loadAsync(run, error -> {
			throw error;
		}, "libs/jolt/wasm/jolt.wasm");
	}

	static function world():JoltInterface {
		var objectFilter = new ObjectLayerPairFilterTable(3);
		objectFilter.EnableCollision(NON_MOVING, MOVING);
		objectFilter.EnableCollision(MOVING, MOVING);
		var broadPhaseLayers = new BroadPhaseLayerInterfaceTable(3, 2);
		broadPhaseLayers.MapObjectToBroadPhaseLayer(NON_MOVING, new BroadPhaseLayer(0));
		broadPhaseLayers.MapObjectToBroadPhaseLayer(MOVING, new BroadPhaseLayer(1));
		broadPhaseLayers.MapObjectToBroadPhaseLayer(GHOST, new BroadPhaseLayer(1));
		var settings = new JoltSettings();
		settings.mMaxBodies = 1024;
		settings.mObjectLayerPairFilter = objectFilter;
		settings.mBroadPhaseLayerInterface = broadPhaseLayers;
		settings.mObjectVsBroadPhaseLayerFilter = new ObjectVsBroadPhaseLayerFilterTable(broadPhaseLayers, 2, objectFilter, 3);
		check(objectFilter.ShouldCollide(MOVING, NON_MOVING)
			&& !objectFilter.ShouldCollide(GHOST, MOVING), "the layer table answers as set");
		return new JoltInterface(settings);
	}

	static function run():Void {
		check(Jolt.isLoaded(), "the module has loaded");
		var jolt = world();
		var system = jolt.GetPhysicsSystem();
		var bodies = system.GetBodyInterface();
		var gravity = system.GetGravity();
		check(near(gravity.y, -9.81), "gravity defaults to -9.81 along y");
		var settings = system.GetPhysicsSettings();
		check(settings.mNumVelocitySteps == 10 && settings.mAllowSleeping, "the physics settings read Jolt's defaults");
		settings.mNumVelocitySteps = 12;
		system.SetPhysicsSettings(settings);
		check(system.GetPhysicsSettings().mNumVelocitySteps == 12, "the physics settings are set");

		shapes();

		// The floor, a stack of boxes and a ball.
		var floor = bodies.CreateAndAddBody(new BodyCreationSettings(new BoxShape(new Vec3(20, 0.5, 20)), new RVec3(0, -0.5, 0), Quat.sIdentity(),
			EMotionType_Static, NON_MOVING),
			EActivation_DontActivate);
		check(!floor.IsInvalid() && bodies.IsAdded(floor), "a static body is made and added");
		var box = new BoxShape(new Vec3(0.5, 0.5, 0.5));
		var stack = [
			for (i in 0...5)
				bodies.CreateAndAddBody(new BodyCreationSettings(box, new RVec3(0, 0.5 + i * 1.01, 0), Quat.sIdentity(), EMotionType_Dynamic, MOVING),
					EActivation_Activate)
		];
		var ballSettings = new BodyCreationSettings(new SphereShape(0.4), new RVec3(3, 6, 0), Quat.sIdentity(), EMotionType_Dynamic, MOVING);
		ballSettings.mRestitution = 0.6;
		var ball = bodies.CreateBody(ballSettings);
		check(ball != null && !bodies.IsAdded(ball.GetID()), "CreateBody makes a body not yet added");
		bodies.AddBody(ball.GetID(), EActivation_Activate);
		check(bodies.GetRestitution(ball.GetID()) > 0.59 && ball.IsDynamic(), "the body reads its settings");
		check(Std.isOfType(bodies.GetShape(stack[0]), BoxShape)
			&& bodies.GetShape(stack[0]) == box, "a body returns the shape it was made from");
		check(near((cast bodies.GetShape(stack[0]) : BoxShape).GetHalfExtent().x, 0.5), "a box returns its half extent");

		// A sensor at the ball's landing place, recording contacts.
		var trigger = new BodyCreationSettings(new BoxShape(new Vec3(1, 1, 1)), new RVec3(3, 1, 0), Quat.sIdentity(), EMotionType_Static, NON_MOVING);
		trigger.mIsSensor = true;
		var sensor = bodies.CreateAndAddBody(trigger, EActivation_DontActivate);
		var contacts = new ContactEventQueue(256);
		system.SetContactListener(contacts);
		check(system.GetContactListener() == contacts, "the contact listener is the queue set");

		// A kinematic platform moved each step.
		var platform = bodies.CreateAndAddBody(new BodyCreationSettings(new BoxShape(new Vec3(1, 0.1, 1)), new RVec3(-5, 1, 0), Quat.sIdentity(),
			EMotionType_Kinematic, MOVING),
			EActivation_Activate);

		var entered = false,
			active = new BodyIDVector(),
			poses = new Float32Array(7 * 64),
			event = new ContactEvent(),
			target = new RVec3();
		for (step in 0...240) {
			bodies.MoveKinematic(platform, target.set(-5 + Math.min(step, 60) * 0.05, 1, 0), Quat.sIdentity(), 1 / 60);
			jolt.Step(1 / 60, 1);
			for (i in 0...contacts.GetNumEvents()) {
				contacts.GetEvent(i, event);
				if (event.mBodyID1 == sensor && event.mBodyID2 == ball.GetID() && event.mType == EContactEventType_Added)
					entered = true;
			}
			system.GetActiveBodies(EBodyType_RigidBody, active);
			var read = bodies.GetPositionsAndRotations(active, poses);
			check(read == active.size(), "the active bodies are read in bulk");
		}
		check(entered, "the ball entering the sensor is reported, the sensor first");
		check(contacts.GetNumDroppedEvents() == 0, "no event was dropped");
		var top = bodies.GetPosition(stack[4]);
		check(near(top.x, 0, 0.05) && near(top.y, 4.5, 0.1), 'the stack stands, its top at y ${top.y}');
		check(near(bodies.GetPosition(platform).x, -2, 1e-3), "the kinematic platform arrives where it was moved");
		var position = new RVec3(), rotation = new Quat(0, 0, 0, 1);
		bodies.GetPositionAndRotation(stack[2], position, rotation);
		var transform = bodies.GetWorldTransform(stack[2]);
		check(near(transform.GetTranslation().y, position.y), "the world transform holds the position");
		var all = new BodyIDVector();
		system.GetBodies(all);
		var transforms:Array<Mat44> = [];
		check(bodies.GetWorldTransforms(all, transforms) == all.size()
			&& transforms.length == all.size(), "every transform is read in bulk");
		check(system.GetNumBodies() == 9, "the system counts its bodies");

		var digests = [digestOf(bodies, all)];
		queries(system, floor, stack, ball.GetID());
		digests.push(digestOf(bodies, all));
		constraints(jolt, floor);
		system.GetBodies(all);
		digests.push(digestOf(bodies, all));

		// Forces, impulses and velocities.
		bodies.AddImpulse(stack[4], new Vec3(500, 0, 0));
		check(bodies.GetLinearVelocity(stack[4]).x > 0.4, "an impulse changes the velocity at once");
		bodies.SetLinearVelocity(ball.GetID(), new Vec3(0, 2, 0));
		check(near(bodies.GetLinearVelocity(ball.GetID()).y, 2), "the velocity is set");
		bodies.SetGravityFactor(ball.GetID(), 0);
		check(bodies.GetGravityFactor(ball.GetID()) == 0, "the gravity factor is set");
		bodies.SetUserData(ball.GetID(), 42);
		check(bodies.GetUserData(ball.GetID()) == 42
			&& system.GetBodyLockInterfaceNoLock().TryGetBody(ball.GetID()) == ball, "a body is found by id");
		for (step in 0...60)
			jolt.Step(1 / 60, 1);

		digests.push(digestOf(bodies, all));
		bodies.RemoveBody(ball.GetID());
		bodies.DestroyBody(ball.GetID());
		check(system.GetBodyLockInterfaceNoLock().TryGetBody(ball.GetID()) == null, "a destroyed body is gone");
		Jolt.destroy(jolt);
		var report = haxe.Json.stringify({passed: true, checks: checks, digest: digests.join(" ")});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}

	/** Every shape, made directly and from settings, and what it reads back. */
	static function shapes():Void {
		var sphere = new SphereShape(0.5);
		check(near(sphere.GetRadius(), 0.5)
			&& sphere.GetSubType() == EShapeSubType_Sphere
			&& sphere.GetType() == EShapeType_Convex, "a sphere");
		check(near(sphere.GetVolume(), 4 / 3 * Math.PI * 0.125, 1e-3), "a sphere's volume");
		var capsule = new CapsuleShape(1, 0.5);
		check(near(capsule.GetHalfHeightOfCylinder(), 1) && near(capsule.GetRadius(), 0.5), "a capsule");
		var cylinder = new CylinderShape(1, 0.5);
		check(near(cylinder.GetHalfHeight(), 1) && cylinder.GetSubType() == EShapeSubType_Cylinder, "a cylinder");
		var scaled = new ScaledShape(sphere, new Vec3(2, 2, 2));
		check(near(scaled.GetScale().x, 2) && scaled.GetType() == EShapeType_Decorated, "a scaled shape");
		var offset = new OffsetCenterOfMassShape(new BoxShape(new Vec3(1, 1, 1)), new Vec3(0, -0.5, 0));
		check(near(offset.GetCenterOfMass().y, -0.5), "a shape's center of mass moved");
		check(new PlaneShape(new Plane(new Vec3(0, 1, 0), 0)).GetSubType() == EShapeSubType_Plane, "a plane");
		check(new EmptyShape().GetSubType() == EShapeSubType_Empty, "an empty shape");
		var box = new BoxShape(new Vec3(1, 1, 1));
		check(near(box.GetDensity(), 1000) && near(box.GetMassProperties().mMass, 8000, 1), "a box of 2 meters weighs 8000 kg");
		box.SetUserData(7);
		check(box.GetUserData() == 7, "a shape keeps a number for the program");

		var tapered = new TaperedCapsuleShapeSettings(1, 0.3, 0.6).Create();
		check(tapered.IsValid() && tapered.Get().GetSubType() == EShapeSubType_TaperedCapsule, "a tapered capsule");
		var hull = new ConvexHullShapeSettings();
		hull.mPoints = [for (x in [-1, 1]) for (y in [-1, 1]) for (z in [-1, 1]) new Vec3(x, y, z)];
		var hullResult = hull.Create();
		check(hullResult.IsValid() && near(hullResult.Get().GetVolume(), 8, 0.05), "a convex hull of a cube's corners");
		var noHull = new ConvexHullShapeSettings();
		noHull.mPoints = [new Vec3(0, 0, 0)];
		var refused = noHull.Create();
		check(refused.HasError() && refused.Get() == null && refused.GetError().length > 0, 'a hull of one point is refused: ${refused.GetError()}');
		var vertices:VertexList = [
			new Float3(0, 0, 0),
			new Float3(1, 0, 0),
			new Float3(0, 0, 1),
			new Float3(1, 0, 1)
		];
		var triangles:IndexedTriangleList = [
			new IndexedTriangle(0, 2, 1),
			new IndexedTriangle(1, 2, 3),
			new IndexedTriangle(1, 1, 2)
		];
		var mesh = new MeshShapeSettings(vertices, triangles);
		mesh.Sanitize();
		check(mesh.mIndexedTriangles.length == 2, "Sanitize removes a triangle of no area");
		var meshShape = mesh.Create().Get();
		check(meshShape.MustBeStatic() && meshShape.GetSubType() == EShapeSubType_Mesh, "a mesh");
		var buffers = MeshShapeSettings.sFromBuffers(Float32Array.fromArray([0, 0, 0, 1, 0, 0, 0, 0, 1]));
		check(buffers.Create().IsValid(), "a mesh from a renderer's arrays");
		var heights = new HeightFieldShapeSettings();
		heights.mSampleCount = 4;
		heights.mHeightSamples = [for (i in 0...16) i % 4 * 0.1];
		check(heights.Create().Get().GetSubType() == EShapeSubType_HeightField, "a height field");
		var compound = new StaticCompoundShapeSettings();
		compound.AddShape(new Vec3(0, 1, 0), Quat.sIdentity(), new BoxShape(new Vec3(1, 0.1, 1)));
		compound.AddShape(new Vec3(0, 0.5, 0), Quat.sIdentity(), new CylinderShape(0.5, 0.1));
		check(compound.Create().Get().GetType() == EShapeType_Compound, "a static compound of two parts");
		var moved = new RotatedTranslatedShapeSettings(new Vec3(0, 2, 0), Quat.sRotation(new Vec3(0, 0, 1), Math.PI / 2), box).Create().Get();
		check(moved.GetSubType() == EShapeSubType_RotatedTranslated && near(moved.GetCenterOfMass().y, 2), "a shape moved and turned");
		var held = new SphereShape(1);
		held.AddRef();
		check(held.GetRefCount() == 1, "a shape held by the program counts it");
		held.Release();
	}

	/** Each query with each collector and filter. */
	static function queries(system:PhysicsSystem, floor:BodyID, stack:Array<BodyID>, ball:BodyID):Void {
		var query = system.GetNarrowPhaseQuery();
		var ray = new RRayCast(new RVec3(0, 20, 0), new Vec3(0, -40, 0));
		var closest = new CastRayClosestHitCollisionCollector();
		query.CastRay(ray, new RayCastSettings(), closest);
		check(closest.HadHit() && closest.mHit.mBodyID == stack[4], "a ray down the stack hits its top first");
		var point = ray.GetPointOnRay(closest.mHit.mFraction);
		check(near(point.y, 5, 0.1), 'the hit is on the top box\'s top: ${point.y}');
		var normal = system.GetBodyLockInterfaceNoLock().TryGetBody(closest.mHit.mBodyID).GetWorldSpaceSurfaceNormal(closest.mHit.mSubShapeID2, point);
		check(near(normal.y, 1, 0.01), "the surface's normal points up");
		var transformed = system.GetBodyInterface().GetTransformedShape(closest.mHit.mBodyID);
		check(near(transformed.GetWorldSpaceSurfaceNormal(closest.mHit.mSubShapeID2, point).y, 1, 0.01), "a transformed shape returns the normal");
		check(near(transformed.GetWorldTransform().GetTranslation().y, 4.5, 0.1), "a transformed shape's transform");
		var everything = new CastRayAllHitCollisionCollector();
		query.CastRay(ray, new RayCastSettings(), everything);
		everything.Sort();
		check(everything.mHits.length == 6 && everything.mHits[5].mBodyID == floor, "every hit along the ray, nearest first, the floor last");
		var below = new CastRayClosestHitCollisionCollector();
		query.CastRay(ray, new RayCastSettings(), below, new IgnoreSingleBodyFilter(stack[4]));
		check(below.mHit.mBodyID == stack[3], "a body filter skips the top box");
		var layered = new CastRayClosestHitCollisionCollector();
		query.CastRay(ray, new RayCastSettings(), layered, null, new SpecifiedObjectLayerFilter(NON_MOVING));
		check(layered.mHit.mBodyID == floor, "an object layer filter tests the floor's layer alone");
		var ghosts = new CastRayAnyHitCollisionCollector();
		query.CastRay(ray, new RayCastSettings(), ghosts, null, new DefaultObjectLayerFilter(new ObjectLayerPairFilterTable(3), GHOST));
		check(!ghosts.HadHit(), "a ghost's layer collides with nothing");
		var many = new IgnoreMultipleBodiesFilter();
		for (id in stack)
			many.IgnoreBody(id);
		var past = new CastRayClosestHitCollisionCollector();
		query.CastRay(ray, new RayCastSettings(), past, null, null, many);
		check(past.mHit.mBodyID == floor, "a list of bodies is skipped");

		var inside = new CollidePointAllHitCollisionCollector();
		query.CollidePoint(new RVec3(0, 2.5, 0), inside);
		check(inside.mHits.length == 1 && inside.mHits[0].mBodyID == stack[2], "a point inside the third box");

		var probe = new SphereShape(0.6);
		var overlaps = new CollideShapeAllHitCollisionCollector();
		query.CollideShape(probe, new Vec3(1, 1, 1), Mat44.sTranslation(new Vec3(0, 1, 0)), new CollideShapeSettings(), new RVec3(), overlaps);
		overlaps.Sort();
		check(overlaps.mHits.length >= 2 && overlaps.mHits[0].mPenetrationDepth >= overlaps.mHits[1].mPenetrationDepth,
			"a sphere overlapping two boxes, deepest first");

		var sweep = new RShapeCast(probe, new Vec3(1, 1, 1), Mat44.sTranslation(new Vec3(-5, 3, 0)), new Vec3(10, 0, 0));
		var swept = new CastShapeClosestHitCollisionCollector();
		query.CastShape(sweep, new ShapeCastSettings(), new RVec3(), swept);
		check(swept.HadHit() && swept.mHit.mBodyID2 == stack[2] || swept.mHit.mBodyID2 == stack[3], "a sphere swept sideways meets the stack");
		check(sweep.GetPointOnRay(swept.mHit.mFraction).x < -0.5, "the swept sphere stops before the stack's middle");
	}

	/** Each constraint with its motor and limits. */
	static function constraints(jolt:JoltInterface, floor:BodyID):Void {
		var system = jolt.GetPhysicsSystem(),
			bodies = system.GetBodyInterface();
		function body(x:Float):BodyID {
			var settings = new BodyCreationSettings(new BoxShape(new Vec3(0.5, 1, 0.05)), new RVec3(x, 10, 5), Quat.sIdentity(), EMotionType_Dynamic, MOVING);
			settings.mGravityFactor = 0;
			settings.mAllowSleeping = false;
			return bodies.CreateAndAddBody(settings, EActivation_Activate);
		}

		var door = body(0);
		var hinge = new HingeConstraintSettings();
		hinge.mPoint1 = hinge.mPoint2 = new RVec3(-0.5, 10, 5);
		hinge.mLimitsMin = -Math.PI / 2;
		hinge.mLimitsMax = Math.PI / 2;
		var doorHinge = bodies.CreateConstraint(hinge, JoltInterface.sGetFixedToWorldBody().GetID(), door);
		system.AddConstraint(doorHinge);
		doorHinge.SetMotorState(EMotorState_Velocity);
		doorHinge.SetTargetAngularVelocity(1);
		check(doorHinge.GetSubType() == EConstraintSubType_Hinge && doorHinge.HasLimits(), "a hinge to the world, limited");
		check(doorHinge.GetBody1().IsInvalid() && doorHinge.GetBody2() == door, "a hinge's first body is the world");
		doorHinge.GetMotorSettings().mMaxTorqueLimit = 1e6;

		var drawer = body(3);
		var slider = new SliderConstraintSettings();
		slider.mAutoDetectPoint = true;
		slider.mLimitsMin = 0;
		slider.mLimitsMax = 1;
		var drawerSlider = bodies.CreateConstraint(slider, JoltInterface.sGetFixedToWorldBody().GetID(), drawer);
		system.AddConstraint(drawerSlider);
		drawerSlider.SetMotorState(EMotorState_Position);
		drawerSlider.SetTargetPosition(0.5);

		var ropeEnd = body(6);
		var rope = new DistanceConstraintSettings();
		rope.mPoint1 = new RVec3(6, 12, 5);
		rope.mPoint2 = new RVec3(6, 10, 5);
		var ropeConstraint = bodies.CreateConstraint(rope, JoltInterface.sGetFixedToWorldBody().GetID(), ropeEnd);
		system.AddConstraint(ropeConstraint);
		check(near(ropeConstraint.GetMaxDistance(), 2, 1e-3), "a distance of -1 is the distance when made");

		var shoulder = body(9);
		var cone = new ConeConstraintSettings();
		cone.mPoint1 = cone.mPoint2 = new RVec3(9, 11, 5);
		cone.mHalfConeAngle = 0.5;
		var coneConstraint = bodies.CreateConstraint(cone, JoltInterface.sGetFixedToWorldBody().GetID(), shoulder);
		system.AddConstraint(coneConstraint);
		coneConstraint.SetHalfConeAngle(0.3);

		var welded = body(12);
		var fixed = new FixedConstraintSettings();
		fixed.mAutoDetectPoint = true;
		system.AddConstraint(bodies.CreateConstraint(fixed, JoltInterface.sGetFixedToWorldBody().GetID(), welded));
		var ball = body(15);
		var point = new PointConstraintSettings();
		point.mPoint1 = point.mPoint2 = new RVec3(15, 11, 5);
		system.AddConstraint(bodies.CreateConstraint(point, JoltInterface.sGetFixedToWorldBody().GetID(), ball));

		var free = body(18);
		var six = new SixDOFConstraintSettings();
		six.mPosition1 = six.mPosition2 = new RVec3(18, 10, 5);
		for (axis in [
			SixDOFConstraintSettings_EAxis_TranslationX,
			SixDOFConstraintSettings_EAxis_TranslationY,
			SixDOFConstraintSettings_EAxis_TranslationZ
		])
			six.MakeFixedAxis(axis);
		six.SetLimitedAxis(SixDOFConstraintSettings_EAxis_RotationY, -0.2, 0.2);
		check(six.IsFixedAxis(SixDOFConstraintSettings_EAxis_TranslationX)
			&& six.IsFreeAxis(SixDOFConstraintSettings_EAxis_RotationX), "six axes' settings");
		var sixConstraint = bodies.CreateConstraint(six, JoltInterface.sGetFixedToWorldBody().GetID(), free);
		system.AddConstraint(sixConstraint);
		check(sixConstraint.IsFixedAxis(SixDOFConstraintSettings_EAxis_TranslationY)
			&& near(sixConstraint.GetLimitsMax(SixDOFConstraintSettings_EAxis_RotationY), 0.2),
			"a six axes' limits");
		bodies.AddAngularImpulse(free, new Vec3(0, 50, 0));

		for (step in 0...120)
			jolt.Step(1 / 60, 1);
		check(near(doorHinge.GetCurrentAngle(), Math.PI / 2, 0.1), 'the door turns to its limit: ${doorHinge.GetCurrentAngle()}');
		check(near(drawerSlider.GetCurrentPosition(), 0.5, 0.05), 'the drawer slides to its target: ${drawerSlider.GetCurrentPosition()}');
		check(near(bodies.GetPosition(welded).x, 12, 1e-3)
			&& near(bodies.GetPosition(ball).y, 10, 0.01), "the welded and pointed bodies stay");
		check(Math.abs(bodies.GetRotation(free).GetEulerAngles().y) <= 0.25, "the six axes' turn stays within its limit");
		doorHinge.SetEnabled(false);
		check(!doorHinge.GetEnabled(), "a constraint is turned off");
		system.RemoveConstraint(doorHinge);
		doorHinge.AddRef();
		check(doorHinge.GetRefCount() == 1, "a removed constraint the program holds counts it");
		doorHinge.Release();
	}

	/** A CRC-32 of every body's position and rotation, as the 32-bit floats Jolt holds. */
	static function digestOf(bodies:BodyInterface, all:BodyIDVector):String {
		var values = new Float32Array(7 * all.size());
		bodies.GetPositionsAndRotations(all, values);
		var bytes = haxe.io.Bytes.alloc(values.length * 4);
		for (i in 0...values.length)
			bytes.setInt32(i * 4, FPHelper.floatToI32(values[i]));
		return StringTools.hex(haxe.crypto.Crc32.make(bytes), 8);
	}
}
