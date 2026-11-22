package helix.box2d.internal;

import helix.box2d.*;

/** Written by tools/gen_box2d.py: each struct's fields made by its constructor, numbers zero and structs new. */
@:noCompletion
class Init {
	public static function initB2AABB(v:B2AABB):Void {
		v.lowerBound = new B2Vec2();
		v.upperBound = new B2Vec2();
	}

	public static function makeB2AABB():B2AABB {
		var v = Type.createEmptyInstance(B2AABB);
		initB2AABB(v);
		return v;
	}

	public static function initB2BodyDef(v:B2BodyDef):Void {
		v.type = cast 0;
		v.position = new B2Vec2();
		v.rotation = Init.makeB2Rot();
		v.linearVelocity = new B2Vec2();
		v.angularVelocity = 0.;
		v.linearDamping = 0.;
		v.angularDamping = 0.;
		v.gravityScale = 0.;
		v.sleepThreshold = 0.;
		v.safetyFactor = 0.;
		v.name = null;
		v.userData = null;
		v.motionLocks = Init.makeB2MotionLocks();
		v.enableSleep = false;
		v.isAwake = false;
		v.isBullet = false;
		v.isEnabled = false;
		v.allowFastRotation = false;
		v.enableContactRecycling = false;
	}

	public static function makeB2BodyDef():B2BodyDef {
		var v = Type.createEmptyInstance(B2BodyDef);
		initB2BodyDef(v);
		return v;
	}

	public static function initB2BodyEvents(v:B2BodyEvents):Void {
		v.moveEvents = [];
		v.moveCount = 0;
	}

	public static function makeB2BodyEvents():B2BodyEvents {
		var v = Type.createEmptyInstance(B2BodyEvents);
		initB2BodyEvents(v);
		return v;
	}

	public static function initB2BodyId(v:B2BodyId):Void {
		v.index1 = 0;
		v.world0 = 0;
		v.generation = 0;
	}

	public static function makeB2BodyId():B2BodyId {
		var v = Type.createEmptyInstance(B2BodyId);
		initB2BodyId(v);
		return v;
	}

	public static function initB2BodyMoveEvent(v:B2BodyMoveEvent):Void {
		v.userData = null;
		v.transform = Init.makeB2Transform();
		v.bodyId = Init.makeB2BodyId();
		v.fellAsleep = false;
	}

	public static function makeB2BodyMoveEvent():B2BodyMoveEvent {
		var v = Type.createEmptyInstance(B2BodyMoveEvent);
		initB2BodyMoveEvent(v);
		return v;
	}

	public static function initB2Capacity(v:B2Capacity):Void {
		v.staticShapeCount = 0;
		v.dynamicShapeCount = 0;
		v.staticBodyCount = 0;
		v.dynamicBodyCount = 0;
		v.contactCount = 0;
		v.arenaByteCount = 0;
	}

	public static function makeB2Capacity():B2Capacity {
		var v = Type.createEmptyInstance(B2Capacity);
		initB2Capacity(v);
		return v;
	}

	public static function initB2Capsule(v:B2Capsule):Void {
		v.center1 = new B2Vec2();
		v.center2 = new B2Vec2();
		v.radius = 0.;
	}

	public static function makeB2Capsule():B2Capsule {
		var v = Type.createEmptyInstance(B2Capsule);
		initB2Capsule(v);
		return v;
	}

	public static function initB2CastOutput(v:B2CastOutput):Void {
		v.normal = new B2Vec2();
		v.point = new B2Vec2();
		v.fraction = 0.;
		v.iterations = 0;
		v.hit = false;
	}

	public static function makeB2CastOutput():B2CastOutput {
		var v = Type.createEmptyInstance(B2CastOutput);
		initB2CastOutput(v);
		return v;
	}

	public static function initB2ChainDef(v:B2ChainDef):Void {
		v.userData = null;
		v.points = [];
		v.pointCount = 0;
		v.ghost1 = new B2Vec2();
		v.ghost2 = new B2Vec2();
		v.materials = [];
		v.materialCount = 0;
		v.filter = Init.makeB2Filter();
		v.isLoop = false;
		v.enableSensorEvents = false;
	}

	public static function makeB2ChainDef():B2ChainDef {
		var v = Type.createEmptyInstance(B2ChainDef);
		initB2ChainDef(v);
		return v;
	}

	public static function initB2ChainId(v:B2ChainId):Void {
		v.index1 = 0;
		v.world0 = 0;
		v.generation = 0;
	}

	public static function makeB2ChainId():B2ChainId {
		var v = Type.createEmptyInstance(B2ChainId);
		initB2ChainId(v);
		return v;
	}

	public static function initB2ChainSegment(v:B2ChainSegment):Void {
		v.ghost1 = new B2Vec2();
		v.segment = Init.makeB2Segment();
		v.ghost2 = new B2Vec2();
		v.chainId = 0;
	}

	public static function makeB2ChainSegment():B2ChainSegment {
		var v = Type.createEmptyInstance(B2ChainSegment);
		initB2ChainSegment(v);
		return v;
	}

	public static function initB2Circle(v:B2Circle):Void {
		v.center = new B2Vec2();
		v.radius = 0.;
	}

	public static function makeB2Circle():B2Circle {
		var v = Type.createEmptyInstance(B2Circle);
		initB2Circle(v);
		return v;
	}

	public static function initB2ContactBeginTouchEvent(v:B2ContactBeginTouchEvent):Void {
		v.shapeIdA = Init.makeB2ShapeId();
		v.shapeIdB = Init.makeB2ShapeId();
		v.contactId = Init.makeB2ContactId();
	}

	public static function makeB2ContactBeginTouchEvent():B2ContactBeginTouchEvent {
		var v = Type.createEmptyInstance(B2ContactBeginTouchEvent);
		initB2ContactBeginTouchEvent(v);
		return v;
	}

	public static function initB2ContactData(v:B2ContactData):Void {
		v.contactId = Init.makeB2ContactId();
		v.shapeIdA = Init.makeB2ShapeId();
		v.shapeIdB = Init.makeB2ShapeId();
		v.manifold = Init.makeB2Manifold();
	}

	public static function makeB2ContactData():B2ContactData {
		var v = Type.createEmptyInstance(B2ContactData);
		initB2ContactData(v);
		return v;
	}

	public static function initB2ContactEndTouchEvent(v:B2ContactEndTouchEvent):Void {
		v.shapeIdA = Init.makeB2ShapeId();
		v.shapeIdB = Init.makeB2ShapeId();
		v.contactId = Init.makeB2ContactId();
	}

	public static function makeB2ContactEndTouchEvent():B2ContactEndTouchEvent {
		var v = Type.createEmptyInstance(B2ContactEndTouchEvent);
		initB2ContactEndTouchEvent(v);
		return v;
	}

	public static function initB2ContactEvents(v:B2ContactEvents):Void {
		v.beginEvents = [];
		v.endEvents = [];
		v.hitEvents = [];
		v.beginCount = 0;
		v.endCount = 0;
		v.hitCount = 0;
	}

	public static function makeB2ContactEvents():B2ContactEvents {
		var v = Type.createEmptyInstance(B2ContactEvents);
		initB2ContactEvents(v);
		return v;
	}

	public static function initB2ContactHitEvent(v:B2ContactHitEvent):Void {
		v.shapeIdA = Init.makeB2ShapeId();
		v.shapeIdB = Init.makeB2ShapeId();
		v.contactId = Init.makeB2ContactId();
		v.point = new B2Vec2();
		v.normal = new B2Vec2();
		v.approachSpeed = 0.;
	}

	public static function makeB2ContactHitEvent():B2ContactHitEvent {
		var v = Type.createEmptyInstance(B2ContactHitEvent);
		initB2ContactHitEvent(v);
		return v;
	}

	public static function initB2ContactId(v:B2ContactId):Void {
		v.index1 = 0;
		v.world0 = 0;
		v.padding = 0;
		v.generation = 0;
	}

	public static function makeB2ContactId():B2ContactId {
		var v = Type.createEmptyInstance(B2ContactId);
		initB2ContactId(v);
		return v;
	}

	public static function initB2CosSin(v:B2CosSin):Void {
		v.cosine = 0.;
		v.sine = 0.;
	}

	public static function makeB2CosSin():B2CosSin {
		var v = Type.createEmptyInstance(B2CosSin);
		initB2CosSin(v);
		return v;
	}

	public static function initB2Counters(v:B2Counters):Void {
		v.byteCount = 0;
		v.bodyCount = 0;
		v.shapeCount = 0;
		v.contactCount = 0;
		v.jointCount = 0;
		v.islandCount = 0;
		v.stackUsed = 0;
		v.staticTreeHeight = 0;
		v.treeHeight = 0;
		v.taskCount = 0;
		v.colorCounts = [for (k in 0...24) 0];
		v.awakeContactCount = 0;
		v.recycledContactCount = 0;
	}

	public static function makeB2Counters():B2Counters {
		var v = Type.createEmptyInstance(B2Counters);
		initB2Counters(v);
		return v;
	}

	public static function initB2DebugDraw(v:B2DebugDraw):Void {
		v.DrawPolygonFcn = null;
		v.DrawSolidPolygonFcn = null;
		v.DrawCircleFcn = null;
		v.DrawSolidCircleFcn = null;
		v.DrawSolidCapsuleFcn = null;
		v.DrawLineFcn = null;
		v.DrawTransformFcn = null;
		v.DrawPointFcn = null;
		v.DrawStringFcn = null;
		v.DrawBoundsFcn = null;
		v.drawingBounds = Init.makeB2AABB();
		v.forceScale = 0.;
		v.jointScale = 0.;
		v.drawContacts = false;
		v.drawAnchorA = false;
		v.drawShapes = false;
		v.drawChainNormals = false;
		v.drawJoints = false;
		v.drawJointExtras = false;
		v.drawBounds = false;
		v.drawMass = false;
		v.drawBodyNames = false;
		v.drawGraphColors = false;
		v.drawContactFeatures = false;
		v.drawContactNormals = false;
		v.drawContactForces = false;
		v.drawFrictionForces = false;
		v.drawIslands = false;
		v.context = null;
	}

	public static function makeB2DebugDraw():B2DebugDraw {
		var v = Type.createEmptyInstance(B2DebugDraw);
		initB2DebugDraw(v);
		return v;
	}

	public static function initB2DistanceInput(v:B2DistanceInput):Void {
		v.proxyA = Init.makeB2ShapeProxy();
		v.proxyB = Init.makeB2ShapeProxy();
		v.transform = Init.makeB2Transform();
		v.useRadii = false;
	}

	public static function makeB2DistanceInput():B2DistanceInput {
		var v = Type.createEmptyInstance(B2DistanceInput);
		initB2DistanceInput(v);
		return v;
	}

	public static function initB2DistanceJointDef(v:B2DistanceJointDef):Void {
		v.base = Init.makeB2JointDef();
		v.length = 0.;
		v.enableSpring = false;
		v.lowerSpringForce = 0.;
		v.upperSpringForce = 0.;
		v.hertz = 0.;
		v.dampingRatio = 0.;
		v.enableLimit = false;
		v.minLength = 0.;
		v.maxLength = 0.;
		v.enableMotor = false;
		v.maxMotorForce = 0.;
		v.motorSpeed = 0.;
	}

	public static function makeB2DistanceJointDef():B2DistanceJointDef {
		var v = Type.createEmptyInstance(B2DistanceJointDef);
		initB2DistanceJointDef(v);
		return v;
	}

	public static function initB2DistanceOutput(v:B2DistanceOutput):Void {
		v.pointA = new B2Vec2();
		v.pointB = new B2Vec2();
		v.normal = new B2Vec2();
		v.distance = 0.;
		v.iterations = 0;
		v.simplexCount = 0;
	}

	public static function makeB2DistanceOutput():B2DistanceOutput {
		var v = Type.createEmptyInstance(B2DistanceOutput);
		initB2DistanceOutput(v);
		return v;
	}

	public static function initB2ExplosionDef(v:B2ExplosionDef):Void {
		v.maskBits = haxe.Int64.make(0, 0);
		v.position = new B2Vec2();
		v.radius = 0.;
		v.falloff = 0.;
		v.impulsePerLength = 0.;
	}

	public static function makeB2ExplosionDef():B2ExplosionDef {
		var v = Type.createEmptyInstance(B2ExplosionDef);
		initB2ExplosionDef(v);
		return v;
	}

	public static function initB2Filter(v:B2Filter):Void {
		v.categoryBits = haxe.Int64.make(0, 0);
		v.maskBits = haxe.Int64.make(0, 0);
		v.groupIndex = 0;
	}

	public static function makeB2Filter():B2Filter {
		var v = Type.createEmptyInstance(B2Filter);
		initB2Filter(v);
		return v;
	}

	public static function initB2FilterJointDef(v:B2FilterJointDef):Void {
		v.base = Init.makeB2JointDef();
	}

	public static function makeB2FilterJointDef():B2FilterJointDef {
		var v = Type.createEmptyInstance(B2FilterJointDef);
		initB2FilterJointDef(v);
		return v;
	}

	public static function initB2Hull(v:B2Hull):Void {
		v.points = [for (k in 0...8) new B2Vec2()];
		v.count = 0;
	}

	public static function makeB2Hull():B2Hull {
		var v = Type.createEmptyInstance(B2Hull);
		initB2Hull(v);
		return v;
	}

	public static function initB2JointDef(v:B2JointDef):Void {
		v.userData = null;
		v.bodyIdA = Init.makeB2BodyId();
		v.bodyIdB = Init.makeB2BodyId();
		v.localFrameA = Init.makeB2Transform();
		v.localFrameB = Init.makeB2Transform();
		v.forceThreshold = 0.;
		v.torqueThreshold = 0.;
		v.constraintHertz = 0.;
		v.constraintDampingRatio = 0.;
		v.drawScale = 0.;
		v.collideConnected = false;
	}

	public static function makeB2JointDef():B2JointDef {
		var v = Type.createEmptyInstance(B2JointDef);
		initB2JointDef(v);
		return v;
	}

	public static function initB2JointEvent(v:B2JointEvent):Void {
		v.jointId = Init.makeB2JointId();
		v.userData = null;
	}

	public static function makeB2JointEvent():B2JointEvent {
		var v = Type.createEmptyInstance(B2JointEvent);
		initB2JointEvent(v);
		return v;
	}

	public static function initB2JointEvents(v:B2JointEvents):Void {
		v.jointEvents = [];
		v.count = 0;
	}

	public static function makeB2JointEvents():B2JointEvents {
		var v = Type.createEmptyInstance(B2JointEvents);
		initB2JointEvents(v);
		return v;
	}

	public static function initB2JointId(v:B2JointId):Void {
		v.index1 = 0;
		v.world0 = 0;
		v.generation = 0;
	}

	public static function makeB2JointId():B2JointId {
		var v = Type.createEmptyInstance(B2JointId);
		initB2JointId(v);
		return v;
	}

	public static function initB2LocalManifold(v:B2LocalManifold):Void {
		v.normal = new B2Vec2();
		v.points = [for (k in 0...2) Init.makeB2LocalManifoldPoint()];
		v.pointCount = 0;
	}

	public static function makeB2LocalManifold():B2LocalManifold {
		var v = Type.createEmptyInstance(B2LocalManifold);
		initB2LocalManifold(v);
		return v;
	}

	public static function initB2LocalManifoldPoint(v:B2LocalManifoldPoint):Void {
		v.point = new B2Vec2();
		v.separation = 0.;
		v.id = 0;
	}

	public static function makeB2LocalManifoldPoint():B2LocalManifoldPoint {
		var v = Type.createEmptyInstance(B2LocalManifoldPoint);
		initB2LocalManifoldPoint(v);
		return v;
	}

	public static function initB2Manifold(v:B2Manifold):Void {
		v.normal = new B2Vec2();
		v.rollingImpulse = 0.;
		v.points = [for (k in 0...2) Init.makeB2ManifoldPoint()];
		v.pointCount = 0;
	}

	public static function makeB2Manifold():B2Manifold {
		var v = Type.createEmptyInstance(B2Manifold);
		initB2Manifold(v);
		return v;
	}

	public static function initB2ManifoldPoint(v:B2ManifoldPoint):Void {
		v.anchorA = new B2Vec2();
		v.anchorB = new B2Vec2();
		v.separation = 0.;
		v.normalImpulse = 0.;
		v.tangentImpulse = 0.;
		v.totalNormalImpulse = 0.;
		v.normalVelocity = 0.;
		v.baseSeparation = 0.;
		v.id = 0;
		v.persisted = false;
	}

	public static function makeB2ManifoldPoint():B2ManifoldPoint {
		var v = Type.createEmptyInstance(B2ManifoldPoint);
		initB2ManifoldPoint(v);
		return v;
	}

	public static function initB2MassData(v:B2MassData):Void {
		v.mass = 0.;
		v.center = new B2Vec2();
		v.rotationalInertia = 0.;
	}

	public static function makeB2MassData():B2MassData {
		var v = Type.createEmptyInstance(B2MassData);
		initB2MassData(v);
		return v;
	}

	public static function initB2Mat22(v:B2Mat22):Void {
		v.cx = new B2Vec2();
		v.cy = new B2Vec2();
	}

	public static function makeB2Mat22():B2Mat22 {
		var v = Type.createEmptyInstance(B2Mat22);
		initB2Mat22(v);
		return v;
	}

	public static function initB2MotionLocks(v:B2MotionLocks):Void {
		v.linearX = false;
		v.linearY = false;
		v.angularZ = false;
	}

	public static function makeB2MotionLocks():B2MotionLocks {
		var v = Type.createEmptyInstance(B2MotionLocks);
		initB2MotionLocks(v);
		return v;
	}

	public static function initB2MotorJointDef(v:B2MotorJointDef):Void {
		v.base = Init.makeB2JointDef();
		v.linearVelocity = new B2Vec2();
		v.maxVelocityForce = 0.;
		v.angularVelocity = 0.;
		v.maxVelocityTorque = 0.;
		v.linearHertz = 0.;
		v.linearDampingRatio = 0.;
		v.maxSpringForce = 0.;
		v.angularHertz = 0.;
		v.angularDampingRatio = 0.;
		v.maxSpringTorque = 0.;
	}

	public static function makeB2MotorJointDef():B2MotorJointDef {
		var v = Type.createEmptyInstance(B2MotorJointDef);
		initB2MotorJointDef(v);
		return v;
	}

	public static function initB2Plane(v:B2Plane):Void {
		v.normal = new B2Vec2();
		v.offset = 0.;
	}

	public static function makeB2Plane():B2Plane {
		var v = Type.createEmptyInstance(B2Plane);
		initB2Plane(v);
		return v;
	}

	public static function initB2Polygon(v:B2Polygon):Void {
		v.vertices = [for (k in 0...8) new B2Vec2()];
		v.normals = [for (k in 0...8) new B2Vec2()];
		v.centroid = new B2Vec2();
		v.radius = 0.;
		v.count = 0;
	}

	public static function makeB2Polygon():B2Polygon {
		var v = Type.createEmptyInstance(B2Polygon);
		initB2Polygon(v);
		return v;
	}

	public static function initB2PrismaticJointDef(v:B2PrismaticJointDef):Void {
		v.base = Init.makeB2JointDef();
		v.enableSpring = false;
		v.hertz = 0.;
		v.dampingRatio = 0.;
		v.targetTranslation = 0.;
		v.enableLimit = false;
		v.lowerTranslation = 0.;
		v.upperTranslation = 0.;
		v.enableMotor = false;
		v.maxMotorForce = 0.;
		v.motorSpeed = 0.;
	}

	public static function makeB2PrismaticJointDef():B2PrismaticJointDef {
		var v = Type.createEmptyInstance(B2PrismaticJointDef);
		initB2PrismaticJointDef(v);
		return v;
	}

	public static function initB2Profile(v:B2Profile):Void {
		v.step = 0.;
		v.pairs = 0.;
		v.collide = 0.;
		v.solve = 0.;
		v.solverSetup = 0.;
		v.constraints = 0.;
		v.prepareConstraints = 0.;
		v.integrateVelocities = 0.;
		v.warmStart = 0.;
		v.solveImpulses = 0.;
		v.integratePositions = 0.;
		v.relaxImpulses = 0.;
		v.restitution = 0.;
		v.storeImpulses = 0.;
		v.splitIslands = 0.;
		v.transforms = 0.;
		v.sensorHits = 0.;
		v.jointEvents = 0.;
		v.hitEvents = 0.;
		v.refit = 0.;
		v.bullets = 0.;
		v.sleepIslands = 0.;
		v.sensors = 0.;
	}

	public static function makeB2Profile():B2Profile {
		var v = Type.createEmptyInstance(B2Profile);
		initB2Profile(v);
		return v;
	}

	public static function initB2QueryFilter(v:B2QueryFilter):Void {
		v.categoryBits = haxe.Int64.make(0, 0);
		v.maskBits = haxe.Int64.make(0, 0);
	}

	public static function makeB2QueryFilter():B2QueryFilter {
		var v = Type.createEmptyInstance(B2QueryFilter);
		initB2QueryFilter(v);
		return v;
	}

	public static function initB2RayCastInput(v:B2RayCastInput):Void {
		v.origin = new B2Vec2();
		v.translation = new B2Vec2();
		v.maxFraction = 0.;
	}

	public static function makeB2RayCastInput():B2RayCastInput {
		var v = Type.createEmptyInstance(B2RayCastInput);
		initB2RayCastInput(v);
		return v;
	}

	public static function initB2RayResult(v:B2RayResult):Void {
		v.shapeId = Init.makeB2ShapeId();
		v.point = new B2Vec2();
		v.normal = new B2Vec2();
		v.fraction = 0.;
		v.nodeVisits = 0;
		v.leafVisits = 0;
		v.hit = false;
	}

	public static function makeB2RayResult():B2RayResult {
		var v = Type.createEmptyInstance(B2RayResult);
		initB2RayResult(v);
		return v;
	}

	public static function initB2RevoluteJointDef(v:B2RevoluteJointDef):Void {
		v.base = Init.makeB2JointDef();
		v.targetAngle = 0.;
		v.enableSpring = false;
		v.hertz = 0.;
		v.dampingRatio = 0.;
		v.enableLimit = false;
		v.lowerAngle = 0.;
		v.upperAngle = 0.;
		v.enableMotor = false;
		v.maxMotorTorque = 0.;
		v.motorSpeed = 0.;
	}

	public static function makeB2RevoluteJointDef():B2RevoluteJointDef {
		var v = Type.createEmptyInstance(B2RevoluteJointDef);
		initB2RevoluteJointDef(v);
		return v;
	}

	public static function initB2Rot(v:B2Rot):Void {
		v.c = 1.;
		v.s = 0.;
	}

	public static function makeB2Rot():B2Rot {
		var v = Type.createEmptyInstance(B2Rot);
		initB2Rot(v);
		return v;
	}

	public static function initB2Segment(v:B2Segment):Void {
		v.point1 = new B2Vec2();
		v.point2 = new B2Vec2();
	}

	public static function makeB2Segment():B2Segment {
		var v = Type.createEmptyInstance(B2Segment);
		initB2Segment(v);
		return v;
	}

	public static function initB2SegmentDistanceResult(v:B2SegmentDistanceResult):Void {
		v.closest1 = new B2Vec2();
		v.closest2 = new B2Vec2();
		v.fraction1 = 0.;
		v.fraction2 = 0.;
		v.distanceSquared = 0.;
	}

	public static function makeB2SegmentDistanceResult():B2SegmentDistanceResult {
		var v = Type.createEmptyInstance(B2SegmentDistanceResult);
		initB2SegmentDistanceResult(v);
		return v;
	}

	public static function initB2SensorBeginTouchEvent(v:B2SensorBeginTouchEvent):Void {
		v.sensorShapeId = Init.makeB2ShapeId();
		v.visitorShapeId = Init.makeB2ShapeId();
	}

	public static function makeB2SensorBeginTouchEvent():B2SensorBeginTouchEvent {
		var v = Type.createEmptyInstance(B2SensorBeginTouchEvent);
		initB2SensorBeginTouchEvent(v);
		return v;
	}

	public static function initB2SensorEndTouchEvent(v:B2SensorEndTouchEvent):Void {
		v.sensorShapeId = Init.makeB2ShapeId();
		v.visitorShapeId = Init.makeB2ShapeId();
	}

	public static function makeB2SensorEndTouchEvent():B2SensorEndTouchEvent {
		var v = Type.createEmptyInstance(B2SensorEndTouchEvent);
		initB2SensorEndTouchEvent(v);
		return v;
	}

	public static function initB2SensorEvents(v:B2SensorEvents):Void {
		v.beginEvents = [];
		v.endEvents = [];
		v.beginCount = 0;
		v.endCount = 0;
	}

	public static function makeB2SensorEvents():B2SensorEvents {
		var v = Type.createEmptyInstance(B2SensorEvents);
		initB2SensorEvents(v);
		return v;
	}

	public static function initB2ShapeCastInput(v:B2ShapeCastInput):Void {
		v.proxy = Init.makeB2ShapeProxy();
		v.translation = new B2Vec2();
		v.maxFraction = 0.;
		v.canEncroach = false;
	}

	public static function makeB2ShapeCastInput():B2ShapeCastInput {
		var v = Type.createEmptyInstance(B2ShapeCastInput);
		initB2ShapeCastInput(v);
		return v;
	}

	public static function initB2ShapeCastPairInput(v:B2ShapeCastPairInput):Void {
		v.proxyA = Init.makeB2ShapeProxy();
		v.proxyB = Init.makeB2ShapeProxy();
		v.transform = Init.makeB2Transform();
		v.translationB = new B2Vec2();
		v.maxFraction = 0.;
		v.canEncroach = false;
	}

	public static function makeB2ShapeCastPairInput():B2ShapeCastPairInput {
		var v = Type.createEmptyInstance(B2ShapeCastPairInput);
		initB2ShapeCastPairInput(v);
		return v;
	}

	public static function initB2ShapeDef(v:B2ShapeDef):Void {
		v.userData = null;
		v.material = Init.makeB2SurfaceMaterial();
		v.density = 0.;
		v.filter = Init.makeB2Filter();
		v.enableCustomFiltering = false;
		v.isSensor = false;
		v.enableSensorEvents = false;
		v.enableContactEvents = false;
		v.enableHitEvents = false;
		v.enablePreSolveEvents = false;
		v.invokeContactCreation = false;
		v.updateBodyMass = false;
	}

	public static function makeB2ShapeDef():B2ShapeDef {
		var v = Type.createEmptyInstance(B2ShapeDef);
		initB2ShapeDef(v);
		return v;
	}

	public static function initB2ShapeId(v:B2ShapeId):Void {
		v.index1 = 0;
		v.world0 = 0;
		v.generation = 0;
	}

	public static function makeB2ShapeId():B2ShapeId {
		var v = Type.createEmptyInstance(B2ShapeId);
		initB2ShapeId(v);
		return v;
	}

	public static function initB2ShapeProxy(v:B2ShapeProxy):Void {
		v.points = [for (k in 0...8) new B2Vec2()];
		v.count = 0;
		v.radius = 0.;
	}

	public static function makeB2ShapeProxy():B2ShapeProxy {
		var v = Type.createEmptyInstance(B2ShapeProxy);
		initB2ShapeProxy(v);
		return v;
	}

	public static function initB2Simplex(v:B2Simplex):Void {
		v.v1 = Init.makeB2SimplexVertex();
		v.v2 = Init.makeB2SimplexVertex();
		v.v3 = Init.makeB2SimplexVertex();
		v.count = 0;
	}

	public static function makeB2Simplex():B2Simplex {
		var v = Type.createEmptyInstance(B2Simplex);
		initB2Simplex(v);
		return v;
	}

	public static function initB2SimplexCache(v:B2SimplexCache):Void {
		v.count = 0;
		v.indexA = [for (k in 0...3) 0];
		v.indexB = [for (k in 0...3) 0];
	}

	public static function makeB2SimplexCache():B2SimplexCache {
		var v = Type.createEmptyInstance(B2SimplexCache);
		initB2SimplexCache(v);
		return v;
	}

	public static function initB2SimplexVertex(v:B2SimplexVertex):Void {
		v.wA = new B2Vec2();
		v.wB = new B2Vec2();
		v.w = new B2Vec2();
		v.a = 0.;
		v.indexA = 0;
		v.indexB = 0;
	}

	public static function makeB2SimplexVertex():B2SimplexVertex {
		var v = Type.createEmptyInstance(B2SimplexVertex);
		initB2SimplexVertex(v);
		return v;
	}

	public static function initB2SurfaceMaterial(v:B2SurfaceMaterial):Void {
		v.friction = 0.;
		v.restitution = 0.;
		v.rollingResistance = 0.;
		v.tangentSpeed = 0.;
		v.userMaterialId = haxe.Int64.make(0, 0);
		v.customColor = 0;
	}

	public static function makeB2SurfaceMaterial():B2SurfaceMaterial {
		var v = Type.createEmptyInstance(B2SurfaceMaterial);
		initB2SurfaceMaterial(v);
		return v;
	}

	public static function initB2Sweep(v:B2Sweep):Void {
		v.localCenter = new B2Vec2();
		v.c1 = new B2Vec2();
		v.c2 = new B2Vec2();
		v.q1 = Init.makeB2Rot();
		v.q2 = Init.makeB2Rot();
	}

	public static function makeB2Sweep():B2Sweep {
		var v = Type.createEmptyInstance(B2Sweep);
		initB2Sweep(v);
		return v;
	}

	public static function initB2TOIInput(v:B2TOIInput):Void {
		v.proxyA = Init.makeB2ShapeProxy();
		v.proxyB = Init.makeB2ShapeProxy();
		v.sweepA = Init.makeB2Sweep();
		v.sweepB = Init.makeB2Sweep();
		v.maxFraction = 0.;
	}

	public static function makeB2TOIInput():B2TOIInput {
		var v = Type.createEmptyInstance(B2TOIInput);
		initB2TOIInput(v);
		return v;
	}

	public static function initB2TOIOutput(v:B2TOIOutput):Void {
		v.state = cast 0;
		v.point = new B2Vec2();
		v.normal = new B2Vec2();
		v.fraction = 0.;
	}

	public static function makeB2TOIOutput():B2TOIOutput {
		var v = Type.createEmptyInstance(B2TOIOutput);
		initB2TOIOutput(v);
		return v;
	}

	public static function initB2Transform(v:B2Transform):Void {
		v.p = new B2Vec2();
		v.q = Init.makeB2Rot();
	}

	public static function makeB2Transform():B2Transform {
		var v = Type.createEmptyInstance(B2Transform);
		initB2Transform(v);
		return v;
	}

	public static function initB2TreeStats(v:B2TreeStats):Void {
		v.nodeVisits = 0;
		v.leafVisits = 0;
	}

	public static function makeB2TreeStats():B2TreeStats {
		var v = Type.createEmptyInstance(B2TreeStats);
		initB2TreeStats(v);
		return v;
	}

	public static function initB2Version(v:B2Version):Void {
		v.major = 0;
		v.minor = 0;
		v.revision = 0;
	}

	public static function makeB2Version():B2Version {
		var v = Type.createEmptyInstance(B2Version);
		initB2Version(v);
		return v;
	}

	public static function initB2WeldJointDef(v:B2WeldJointDef):Void {
		v.base = Init.makeB2JointDef();
		v.linearHertz = 0.;
		v.angularHertz = 0.;
		v.linearDampingRatio = 0.;
		v.angularDampingRatio = 0.;
	}

	public static function makeB2WeldJointDef():B2WeldJointDef {
		var v = Type.createEmptyInstance(B2WeldJointDef);
		initB2WeldJointDef(v);
		return v;
	}

	public static function initB2WheelJointDef(v:B2WheelJointDef):Void {
		v.base = Init.makeB2JointDef();
		v.enableSpring = false;
		v.hertz = 0.;
		v.dampingRatio = 0.;
		v.enableLimit = false;
		v.lowerTranslation = 0.;
		v.upperTranslation = 0.;
		v.enableMotor = false;
		v.maxMotorTorque = 0.;
		v.motorSpeed = 0.;
	}

	public static function makeB2WheelJointDef():B2WheelJointDef {
		var v = Type.createEmptyInstance(B2WheelJointDef);
		initB2WheelJointDef(v);
		return v;
	}

	public static function initB2WorldDef(v:B2WorldDef):Void {
		v.gravity = new B2Vec2();
		v.restitutionThreshold = 0.;
		v.restitutionIterations = 0;
		v.enableRestitutionPropagation = false;
		v.hitEventThreshold = 0.;
		v.contactHertz = 0.;
		v.contactDampingRatio = 0.;
		v.contactSpeed = 0.;
		v.maximumLinearSpeed = 0.;
		v.frictionCallback = null;
		v.restitutionCallback = null;
		v.enableSleep = false;
		v.enableContinuous = false;
		v.workerCount = 0;
		v.userData = null;
		v.capacity = Init.makeB2Capacity();
	}

	public static function makeB2WorldDef():B2WorldDef {
		var v = Type.createEmptyInstance(B2WorldDef);
		initB2WorldDef(v);
		return v;
	}

	public static function initB2WorldId(v:B2WorldId):Void {
		v.index1 = 0;
		v.generation = 0;
	}

	public static function makeB2WorldId():B2WorldId {
		var v = Type.createEmptyInstance(B2WorldId);
		initB2WorldId(v);
		return v;
	}
}
