import haxe.io.FPHelper;
import helix.box2d.*;
import helix.box2d.Box2D.*;

/** Checks helix-box2d on a page's module (Node) and natively: a world's defs and settings, every shape and a chain, bodies made, moved
	and read, a stack falling to rest, contact, hit, sensor, body and joint events, each query with and without its callback, the
	world's callbacks, each joint with its motor, spring and limits, user data, names, debug drawing, a snapshot restored, the geometry
	and the maths, and destroying. Prints the checks and a digest of the scene at each stage, Box2D's state hash and every body's pose as
	32-bit floats, which helix.py compares between the targets: the same steps make the same bits. Natively the scene runs again on
	four of Box2D's threads, to the same bits. */
class Box2DTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float, tolerance = 1e-4):Bool
		return Math.abs(a - b) <= tolerance;

	static function main():Void {
		Box2D.loadAsync(run, error -> {
			throw error;
		}, "libs/box2d/wasm/box2d.wasm");
	}

	static function run():Void {
		var version = b2GetVersion();
		check(version.major == 3 && version.minor == 2 && version.revision == 0, "the module is Box2D 3.2.0");
		check(!b2IsDoublePrecision(), "the module is single precision");
		check(near(b2GetLengthUnitsPerMeter(), 1), "a length unit is a meter");
		check(near(b2Add(new B2Vec2(1, 2), new B2Vec2(3, 4)).x, 4)
			&& near(b2Dot(new B2Vec2(1, 2), new B2Vec2(3, 4)), 11), "the maths adds and dots");
		var rot = b2MakeRot(Math.PI / 2);
		check(near(rot.c, 0, 1e-3)
			&& near(rot.s, 1, 1e-3)
			&& near(b2Rot_GetAngle(rot), Math.PI / 2, 1e-3), "a rotation is made from an angle");
		check(near(b2RotateVector(rot, new B2Vec2(1, 0)).y, 1, 1e-3), "a rotation turns a vector");
		var bytes = haxe.io.Bytes.ofString("box2d");
		check(b2Hash(B2_HASH_INIT, bytes, bytes.length) == b2Hash(B2_HASH_INIT, haxe.io.Bytes.ofString("box2d"), 5), "the hash is the same twice");
		geometry();

		var digests = [];
		var single = scene(1, digests);
		#if cpp
		var threaded = [];
		scene(4, threaded);
		check(threaded.join(" ") == digests.join(" "), "four of Box2D's threads make the same bits as one");
		#end
		check(single, "the scene ran");
		var report = haxe.Json.stringify({passed: true, checks: checks, digest: digests.join(" ")});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}

	/** The functions on shapes alone: hulls, polygons, mass, collision and distance. */
	static function geometry():Void {
		var points = [
			new B2Vec2(-1, -1),
			new B2Vec2(1, -1),
			new B2Vec2(1, 1),
			new B2Vec2(-1, 1),
			new B2Vec2(0, 0)
		];
		var hull = b2ComputeHull(points, points.length);
		check(hull.count == 4, "a hull leaves out an inner point");
		check(b2ValidateHull(hull), "a computed hull is valid");
		var square = b2MakePolygon(hull, 0);
		check(square.count == 4 && near(square.centroid.x, 0), "a polygon is made from a hull");
		var mass = b2ComputePolygonMass(square, 2);
		check(near(mass.mass, 8), "a 2 by 2 polygon of density 2 weighs 8");
		var box = b2MakeBox(0.5, 0.5);
		var manifold = b2CollidePolygons(square, box, new B2Transform(new B2Vec2(1.25, 0)));
		check(manifold.pointCount == 2 && near(manifold.normal.x, 1, 1e-3), "two overlapping boxes collide along x at two points");
		var apart = b2CollidePolygons(square, box, new B2Transform(new B2Vec2(5, 0)));
		check(apart.pointCount == 0, "two boxes apart don't collide");
		var input = new B2DistanceInput();
		input.proxyA = b2MakeProxy(square.vertices, square.count, 0);
		input.proxyB = b2MakeProxy(box.vertices, box.count, 0);
		input.transform = new B2Transform(new B2Vec2(4, 0));
		var distance = b2ComputeShapeDistance(input, b2_emptySimplexCache);
		check(near(distance.distance, 2.5, 1e-3), "the distance between the boxes is 2.5");
		var circle = new B2Circle(new B2Vec2(0, 0), 1);
		var ray = new B2RayCastInput(new B2Vec2(-3, 0), new B2Vec2(6, 0), 1);
		var output = b2CastRayCircle(circle, ray);
		check(output.hit && near(output.point.x, -1, 1e-3), "a ray hits a circle on its near side");
		check(b2PointInPolygon(square, new B2Vec2(0.5, 0.5))
			&& !b2PointInPolygon(square, new B2Vec2(3, 0)), "a point is in a polygon or not");
	}

	/** The scene, on `workers` of Box2D's threads. Returns true, its digests pushed onto `digests`. */
	static function scene(workers:Int, digests:Array<String>):Bool {
		var worldDef = b2DefaultWorldDef();
		check(near(worldDef.gravity.y, -10) && worldDef.enableSleep, "a world def holds Box2D's defaults");
		worldDef.workerCount = workers;
		worldDef.userData = "the world";
		var frictionCalls = 0;
		worldDef.frictionCallback = (frictionA, materialA, frictionB, materialB) -> {
			frictionCalls++;
			return Math.sqrt(frictionA * frictionB);
		};
		var worldId = b2CreateWorld(worldDef);
		check(b2World_IsValid(worldId), "the world is made");
		check(b2World_GetUserData(worldId) == "the world", "the world's user data is kept");
		check(near(b2World_GetGravity(worldId).y, -10), "the world's gravity is the def's");
		var bodies = [];

		// The ground: a floor, a ramp, and hills from a chain.
		var groundDef = b2DefaultBodyDef();
		groundDef.name = "ground";
		var ground = b2CreateBody(worldId, groundDef);
		check(b2Body_GetName(ground) == "ground", "a body's name is kept");
		b2CreatePolygonShape(ground, b2DefaultShapeDef(), b2MakeOffsetBox(40, 0.5, new B2Vec2(0, -0.5), b2Rot_identity));
		b2CreatePolygonShape(ground, b2DefaultShapeDef(), b2MakeOffsetBox(3, 0.25, new B2Vec2(-10, 1), b2MakeRot(0.35)));
		var hills = [for (i in 0...40) new B2Vec2(34.5 - i * 0.5, 0.5 + 0.3 * Math.sin(i * 0.4))];
		var chainDef = b2DefaultChainDef();
		check(chainDef.materialCount == 1 && near(chainDef.materials[0].friction, 0.6), "a chain def holds one material by default");
		chainDef.points = hills;
		chainDef.pointCount = hills.length;
		chainDef.ghost1 = new B2Vec2(35, 0.5);
		chainDef.ghost2 = new B2Vec2(14.5, 0.5);
		chainDef.userData = "hills";
		var chain = b2CreateChain(ground, chainDef);
		check(b2Chain_IsValid(chain) && b2Chain_GetSegmentCount(chain) == 39, "an open chain of 40 points has 39 segments");
		var segments = [];
		check(b2Chain_GetSegments(chain, segments, 100) == 39 && segments.length == 39, "a chain's segments fill an empty array");

		// A stack of boxes, balls that bounce, a capsule and a rounded box.
		var boxes = [];
		for (i in 0...6) {
			var def = b2DefaultBodyDef();
			def.type = b2_dynamicBody;
			def.position = new B2Vec2(0, 0.5 + i);
			var body = b2CreateBody(worldId, def);
			var shapeDef = b2DefaultShapeDef();
			shapeDef.enableContactEvents = true;
			shapeDef.enableCustomFiltering = true;
			shapeDef.enablePreSolveEvents = true;
			b2CreatePolygonShape(body, shapeDef, b2MakeBox(0.5, 0.5));
			boxes.push(body);
			bodies.push(body);
		}
		var balls = [];
		for (i in 0...3) {
			var def = b2DefaultBodyDef();
			def.type = b2_dynamicBody;
			def.position = new B2Vec2(2 + i, 6);
			var body = b2CreateBody(worldId, def);
			var shapeDef = b2DefaultShapeDef();
			shapeDef.material.restitution = 0.6;
			shapeDef.enableHitEvents = true;
			shapeDef.enableSensorEvents = true;
			shapeDef.userData = "ball " + i;
			var shape = b2CreateCircleShape(body, shapeDef, new B2Circle(new B2Vec2(), 0.4));
			check(b2Shape_GetUserData(shape) == "ball " + i, "a shape's user data is kept");
			b2Body_SetUserData(body, i);
			balls.push(body);
			bodies.push(body);
		}
		var capsuleDef = b2DefaultBodyDef();
		capsuleDef.type = b2_dynamicBody;
		capsuleDef.position = new B2Vec2(-10, 4);
		var capsule = b2CreateBody(worldId, capsuleDef);
		var capsuleShape = b2DefaultShapeDef();
		capsuleShape.enableCustomFiltering = true;
		b2CreateCapsuleShape(capsule, capsuleShape, new B2Capsule(new B2Vec2(-0.5, 0), new B2Vec2(0.5, 0), 0.25));
		bodies.push(capsule);
		var rounded = b2CreateBody(worldId, (() -> {
			var def = b2DefaultBodyDef();
			def.type = b2_dynamicBody;
			def.position = new B2Vec2(6, 3);
			def.rotation = b2MakeRot(0.3);
			return def;
		})());
		b2CreatePolygonShape(rounded, b2DefaultShapeDef(), b2MakeRoundedBox(0.4, 0.3, 0.1));
		bodies.push(rounded);

		// A sensor the balls fall through.
		var sensorDef = b2DefaultShapeDef();
		sensorDef.isSensor = true;
		sensorDef.enableSensorEvents = true;
		var sensor = b2CreatePolygonShape(ground, sensorDef, b2MakeOffsetBox(1.6, 1, new B2Vec2(3, 3), b2Rot_identity));
		check(b2Shape_IsSensor(sensor), "a sensor is a sensor");

		// A kinematic platform.
		var platformDef = b2DefaultBodyDef();
		platformDef.type = b2_kinematicBody;
		platformDef.position = new B2Vec2(-4, 2);
		var platform = b2CreateBody(worldId, platformDef);
		b2CreatePolygonShape(platform, b2DefaultShapeDef(), b2MakeBox(1.5, 0.25));
		bodies.push(platform);

		// Joints: a door on a limited motor, a cart on sprung wheels, a slider, a rope, a weld and a motor joint.
		var doorDef = b2DefaultBodyDef();
		doorDef.type = b2_dynamicBody;
		doorDef.position = new B2Vec2(10, 1);
		var door = b2CreateBody(worldId, doorDef);
		b2CreatePolygonShape(door, b2DefaultShapeDef(), b2MakeBox(0.1, 1));
		bodies.push(door);
		var hinge = b2DefaultRevoluteJointDef();
		hinge.base.bodyIdA = ground;
		hinge.base.bodyIdB = door;
		hinge.base.localFrameA.p = new B2Vec2(10, 0);
		hinge.base.localFrameB.p = new B2Vec2(0, -1);
		hinge.base.userData = "door";
		hinge.enableMotor = true;
		hinge.motorSpeed = 1;
		hinge.maxMotorTorque = 500;
		hinge.enableLimit = true;
		hinge.lowerAngle = -Math.PI / 2;
		hinge.upperAngle = Math.PI / 2;
		var doorJoint = b2CreateRevoluteJoint(worldId, hinge);
		check(b2Joint_GetType(doorJoint) == b2_revoluteJoint, "a revolute joint is made");
		check(b2Joint_GetUserData(doorJoint) == "door", "a joint's user data is kept");
		check(B2_ID_EQUALS(b2Joint_GetBodyB(doorJoint), door), "a joint's body B is the door");
		var joints = [];
		check(b2Body_GetJoints(door, joints, 4) == 1 && B2_ID_EQUALS(joints[0], doorJoint), "the door's joints are its hinge");

		var cartDef = b2DefaultBodyDef();
		cartDef.type = b2_dynamicBody;
		cartDef.position = new B2Vec2(18, 2.5);
		var cart = b2CreateBody(worldId, cartDef);
		b2CreatePolygonShape(cart, b2DefaultShapeDef(), b2MakeBox(1, 0.25));
		bodies.push(cart);
		var wheels = [];
		for (x in [-0.7, 0.7]) {
			var wheelDef = b2DefaultBodyDef();
			wheelDef.type = b2_dynamicBody;
			wheelDef.position = new B2Vec2(18 + x, 2);
			var wheel = b2CreateBody(worldId, wheelDef);
			b2CreateCircleShape(wheel, b2DefaultShapeDef(), new B2Circle(new B2Vec2(), 0.4));
			bodies.push(wheel);
			var axle = b2DefaultWheelJointDef();
			axle.base.bodyIdA = cart;
			axle.base.bodyIdB = wheel;
			axle.base.localFrameA.p = new B2Vec2(x, -0.5);
			axle.base.localFrameA.q = b2MakeRot(Math.PI / 2);
			axle.base.localFrameB.q = b2MakeRot(Math.PI / 2);
			axle.enableMotor = x < 0;
			axle.motorSpeed = -10;
			axle.maxMotorTorque = 20;
			wheels.push(b2CreateWheelJoint(worldId, axle));
		}
		check(b2WheelJoint_IsMotorEnabled(wheels[0]) && !b2WheelJoint_IsMotorEnabled(wheels[1]), "the rear wheel is driven");

		var slider = b2DefaultPrismaticJointDef();
		slider.base.bodyIdA = ground;
		slider.base.bodyIdB = capsule;
		slider.base.localFrameA.p = new B2Vec2(-10, 4);
		slider.enableLimit = true;
		slider.lowerTranslation = -1;
		slider.upperTranslation = 1;
		var sliderJoint = b2CreatePrismaticJoint(worldId, slider);
		var rope = b2DefaultDistanceJointDef();
		rope.base.bodyIdA = boxes[5];
		rope.base.bodyIdB = balls[0];
		rope.length = 3;
		rope.enableSpring = true;
		rope.hertz = 2;
		var ropeJoint = b2CreateDistanceJoint(worldId, rope);
		check(near(b2DistanceJoint_GetRestLength(ropeJoint), 3), "a distance joint keeps its length");
		var lo = [0.], hi = [0.];
		b2DistanceJoint_GetSpringForceRange(ropeJoint, lo, hi);
		check(lo[0] < 0 && hi[0] > 0, "a spring's force range reads into one-element arrays");
		var weld = b2DefaultWeldJointDef();
		weld.base.bodyIdA = boxes[4];
		weld.base.bodyIdB = boxes[5];
		weld.base.localFrameA.p = new B2Vec2(0, 0.5);
		weld.base.localFrameB.p = new B2Vec2(0, -0.5);
		b2CreateWeldJoint(worldId, weld);
		var motor = b2DefaultMotorJointDef();
		motor.base.bodyIdA = ground;
		motor.base.bodyIdB = rounded;
		motor.linearVelocity = new B2Vec2(0.5, 0);
		motor.maxVelocityForce = 50;
		b2CreateMotorJoint(worldId, motor);

		// The world's callbacks: one box never touches the ramp's capsule, and pre-solve sees each manifold.
		var filtered = 0;
		b2World_SetCustomFilterCallback(worldId, (a, b, context) -> {
			filtered++;
			return !(B2_ID_EQUALS(b2Shape_GetBody(a), capsule) && B2_ID_EQUALS(b2Shape_GetBody(b), boxes[0]))
				&& !(B2_ID_EQUALS(b2Shape_GetBody(b), capsule) && B2_ID_EQUALS(b2Shape_GetBody(a), boxes[0]));
		}, null);
		var preSolved = 0;
		b2World_SetPreSolveCallback(worldId, (a, b, manifold, context) -> {
			preSolved++;
			check(manifold.pointCount >= 0 && manifold.pointCount <= 2, "a pre-solve manifold has at most two points");
		}, null, null);

		digests.push(digest(worldId, bodies));

		// Two seconds: count the events.
		var began = 0, hits = 0, entered = 0, left = 0, moved = 0;
		var contactEvents = new B2ContactEvents();
		var sensorEvents = new B2SensorEvents();
		var bodyEvents = new B2BodyEvents();
		var target = new B2Transform();
		for (step in 0...120) {
			var t = (step + 1) / 60;
			target.p.x = -4 + 2 * Math.sin(t * Math.PI / 2);
			target.p.y = 2;
			b2Body_SetTargetTransform(platform, target, 1 / 60, true);
			b2World_Step(worldId, 1 / 60, 4);
			b2World_GetContactEvents(worldId, contactEvents);
			began += contactEvents.beginCount;
			for (k in 0...contactEvents.hitCount)
				if (contactEvents.hitEvents[k].approachSpeed > 1)
					hits++;
			b2World_GetSensorEvents(worldId, sensorEvents);
			entered += sensorEvents.beginCount;
			left += sensorEvents.endCount;
			b2World_GetBodyEvents(worldId, bodyEvents);
			moved += bodyEvents.moveCount;
		}
		check(began > 0, "boxes report touching");
		check(hits > 0, "balls report hitting the ground");
		check(entered > 0, "balls are seen entering the sensor");
		check(moved > 0, "moving bodies report moving");
		check(filtered > 0 && preSolved > 0, "the custom filter and pre-solve were called");
		check(frictionCalls > 0, "the world's friction callback was called");
		var sawUserData = false;
		for (k in 0...bodyEvents.moveCount)
			if (bodyEvents.moveEvents[k].userData == 1)
				sawUserData = true;
		check(sawUserData || !b2Body_IsAwake(balls[1]), "a move event carries its body's user data");
		var doorAngle = b2RevoluteJoint_GetCurrentAngle(doorJoint);
		check(doorAngle > 1 && doorAngle <= Math.PI / 2 + 0.05, "the door's motor turns it to its limit");
		check(b2Body_GetPosition(cart).x > 18.2, "the cart's driven wheel moves it toward +x");
		check(Math.abs(b2PrismaticJoint_GetCurrentTranslation(sliderJoint)) <= 1.01, "the slider stays within its limits");
		digests.push(digest(worldId, bodies));

		// Queries.
		var closest = b2World_CastRayClosest(worldId, new B2Vec2(0.2, 20), new B2Vec2(0, -40), b2DefaultQueryFilter());
		check(closest.hit && B2_ID_EQUALS(b2Shape_GetBody(closest.shapeId), boxes[5]) && near(closest.normal.y, 1, 0.02),
			"a ray down hits the top box, which leans on its rope");
		var hitsAlong = [];
		b2World_CastRay(worldId, new B2Vec2(0.2, 20), new B2Vec2(0, -40), b2DefaultQueryFilter(), (shapeId, point, normal, fraction, context) -> {
			check(context == "rays", "a cast's context is passed through");
			hitsAlong.push(point.y);
			return 1;
		}, "rays");
		check(hitsAlong.length >= 6, "a ray's callback sees every box in the stack and the floor");
		var overlapped = 0;
		b2World_OverlapAABB(worldId, new B2Vec2(), new B2AABB(new B2Vec2(-1, 0), new B2Vec2(1, 7)), b2DefaultQueryFilter(), (shapeId, context) -> {
			overlapped++;
			return true;
		}, null);
		check(overlapped >= 6, "a box overlaps the stack");
		var proxy = b2MakeProxy([new B2Vec2(0, 0)], 1, 0.2);
		var swept = 0;
		b2World_CastShape(worldId, new B2Vec2(-30, 5), proxy, new B2Vec2(60, 0), b2DefaultQueryFilter(), (shapeId, point, normal, fraction, context) -> {
			swept++;
			return fraction;
		}, null);
		check(swept > 0, "a swept circle hits something along its way");
		var shapes = [];
		check(b2Body_GetShapes(boxes[0], shapes, 4) == 1
			&& b2Shape_TestPoint(shapes[0], b2Body_GetPosition(boxes[0])), "a box's shape holds its center");
		var contacts = [];
		var touching = b2Body_GetContactData(boxes[0], contacts, 16);
		check(touching > 0 && contacts[0].manifold.pointCount > 0, "the bottom box's contacts have points");
		var visitors = [];
		b2Shape_GetSensorData(sensor, visitors, 8);
		var counters = b2World_GetCounters(worldId);
		check(counters.bodyCount == bodies.length + 1 && counters.jointCount == 7, "the counters count the bodies and joints");

		// Debug drawing.
		var drawn = 0;
		var draw = b2DefaultDebugDraw();
		draw.drawShapes = true;
		draw.drawJoints = true;
		draw.DrawSolidPolygonFcn = (transform, vertices, vertexCount, radius, color, context) -> {
			check(vertexCount >= 3 && vertices.length >= vertexCount, "a drawn polygon has its vertices");
			drawn++;
		};
		draw.DrawSolidCircleFcn = (transform, center, radius, color, context) -> drawn++;
		draw.DrawSolidCapsuleFcn = (p1, p2, radius, color, context) -> drawn++;
		draw.DrawLineFcn = (p1, p2, color, context) -> drawn++;
		b2World_Draw(worldId, draw);
		check(drawn > 10, "debug drawing draws the scene's shapes");

		// A snapshot restored replays the same steps to the same bits.
		var size = b2World_GetSnapshot(worldId, null, 0);
		var image = haxe.io.Bytes.alloc(size);
		check(b2World_GetSnapshot(worldId, image, size) == size, "a snapshot is written");
		var hashBefore = b2World_GetStateHash(worldId);
		for (step in 0...30)
			b2World_Step(worldId, 1 / 60, 4);
		var hashAfter = b2World_GetStateHash(worldId);
		check(b2World_RestoreFromSnapshot(worldId, image, size), "a snapshot is restored");
		check(b2World_GetStateHash(worldId) == hashBefore, "a restored world hashes as it did");
		for (step in 0...30)
			b2World_Step(worldId, 1 / 60, 4);
		check(b2World_GetStateHash(worldId) == hashAfter, "the same steps from a restored world reach the same state");

		// An explosion, then destroying.
		var explosion = b2DefaultExplosionDef();
		explosion.position = new B2Vec2(0, 0);
		explosion.radius = 5;
		explosion.impulsePerLength = 2;
		b2World_Explode(worldId, explosion);
		for (step in 0...60)
			b2World_Step(worldId, 1 / 60, 4);
		digests.push(digest(worldId, bodies));
		b2DestroyBody(balls[2]);
		check(!b2Body_IsValid(balls[2]), "a destroyed body is gone");
		check(b2Body_IsValid(balls[1]), "another body stays");
		b2DestroyWorld(worldId);
		check(!b2World_IsValid(worldId), "a destroyed world is gone");
		return true;
	}

	/** Box2D's state hash, and a CRC-32 of every body's position and rotation as the 32-bit floats Box2D holds. */
	static function digest(worldId:B2WorldId, bodies:Array<B2BodyId>):String {
		var bytes = haxe.io.Bytes.alloc(bodies.length * 16);
		var p = new B2Vec2(), q = new B2Rot();
		for (i in 0...bodies.length) {
			b2Body_GetPosition(bodies[i], p);
			b2Body_GetRotation(bodies[i], q);
			bytes.setInt32(i * 16, FPHelper.floatToI32(p.x));
			bytes.setInt32(i * 16 + 4, FPHelper.floatToI32(p.y));
			bytes.setInt32(i * 16 + 8, FPHelper.floatToI32(q.c));
			bytes.setInt32(i * 16 + 12, FPHelper.floatToI32(q.s));
		}
		var hash = b2World_GetStateHash(worldId);
		return StringTools.hex(hash.high, 8) + StringTools.hex(hash.low, 8) + "/" + StringTools.hex(haxe.crypto.Crc32.make(bytes), 8);
	}
}
