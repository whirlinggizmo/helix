// helix-box2d's size ladder (tools/gen_sizes.py): each rung adds one thing to the one before; this one a circle, a capsule and a chain.
import helix.box2d.*;
import helix.box2d.Box2D.*;

/** A program on helix-box2d alone, constructing only what it uses. */
@:adds("helix.box2d.B2Capsule", "helix.box2d.B2ChainDef", "helix.box2d.B2ChainId", "helix.box2d.B2Circle")
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
			for (step in 0...60) {
				b2World_Step(worldId, 1 / 60, 4);
			}
			trace(b2Body_GetPosition(boxId, position).y);
			b2DestroyWorld(worldId);
		});
	}
}
