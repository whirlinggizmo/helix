// helix-box2d's size ladder (tools/gen_sizes.py): each rung adds one thing to the one before; this one a door on a revolute joint turned by its motor, and a wheel on a wheel joint.
import helix.box2d.*;
import helix.box2d.Box2D.*;

/** A program on helix-box2d alone, constructing only what it uses. */
@:adds("helix.box2d.B2JointDef", "helix.box2d.B2RevoluteJointDef", "helix.box2d.B2WheelJointDef")
class Main {
	static function main():Void {
		Box2D.loadAsync(() -> {
			var worldId = b2CreateWorld(b2DefaultWorldDef());
			var groundDef = b2DefaultBodyDef();
			groundDef.position = new B2Vec2(0, -10);
			var groundId = b2CreateBody(worldId, groundDef);
			b2CreatePolygonShape(groundId, b2DefaultShapeDef(), b2MakeBox(50, 10));
			var boxDef = b2DefaultBodyDef();
			boxDef.type = b2_dynamicBody;
			boxDef.position = new B2Vec2(0, 4);
			var boxId = b2CreateBody(worldId, boxDef);
			b2CreatePolygonShape(boxId, b2DefaultShapeDef(), b2MakeBox(1, 1));
			var position = new B2Vec2();
			var ballDef = b2DefaultBodyDef();
			ballDef.type = b2_dynamicBody;
			ballDef.position = new B2Vec2(3, 4);
			var ballId = b2CreateBody(worldId, ballDef);
			var ballShape = b2DefaultShapeDef();
			b2CreateCircleShape(ballId, ballShape, new B2Circle(new B2Vec2(), 0.5));
			b2CreateCapsuleShape(b2CreateBody(worldId, boxDef), b2DefaultShapeDef(), new B2Capsule(new B2Vec2(-0.5, 0), new B2Vec2(0.5, 0), 0.25));
			var chainDef = b2DefaultChainDef();
			chainDef.points = [new B2Vec2(-20, 0), new B2Vec2(20, 0), new B2Vec2(20, 10), new B2Vec2(-20, 10)];
			chainDef.pointCount = 4;
			chainDef.isLoop = true;
			b2CreateChain(groundId, chainDef);
			var doorDef = b2DefaultBodyDef();
			doorDef.type = b2_dynamicBody;
			doorDef.position = new B2Vec2(10, 1);
			var doorId = b2CreateBody(worldId, doorDef);
			b2CreatePolygonShape(doorId, b2DefaultShapeDef(), b2MakeBox(0.1, 1));
			var hinge = b2DefaultRevoluteJointDef();
			hinge.base.bodyIdA = groundId;
			hinge.base.bodyIdB = doorId;
			hinge.base.localFrameA.p = new B2Vec2(10, 10);
			hinge.base.localFrameB.p = new B2Vec2(0, -1);
			hinge.enableMotor = true;
			hinge.motorSpeed = 1;
			hinge.maxMotorTorque = 500;
			b2CreateRevoluteJoint(worldId, hinge);
			var wheelDef = b2DefaultBodyDef();
			wheelDef.type = b2_dynamicBody;
			wheelDef.position = new B2Vec2(0, 2.5);
			var wheelId = b2CreateBody(worldId, wheelDef);
			b2CreateCircleShape(wheelId, b2DefaultShapeDef(), new B2Circle(new B2Vec2(), 0.4));
			var axle = b2DefaultWheelJointDef();
			axle.base.bodyIdA = boxId;
			axle.base.bodyIdB = wheelId;
			axle.base.localFrameA.p = new B2Vec2(0, -1.5);
			axle.base.localFrameA.q = b2MakeRot(Math.PI / 2);
			axle.base.localFrameB.q = b2MakeRot(Math.PI / 2);
			b2CreateWheelJoint(worldId, axle);
			for (step in 0...60) {
				b2World_Step(worldId, 1 / 60, 4);
			}
			trace(b2Body_GetPosition(boxId, position).y);
			b2DestroyWorld(worldId);
		});
	}
}
