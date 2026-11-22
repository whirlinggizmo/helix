import helix.box2d.*;
import helix.box2d.Box2D.*;

/** A box falling onto the ground, its height printed each quarter of a second until it rests: Box2D's hello world, with helix-box2d
	alone. */
class Main {
	static function main():Void {
		Box2D.loadAsync(() -> {
			var worldId = b2CreateWorld(b2DefaultWorldDef());

			var groundDef = b2DefaultBodyDef();
			groundDef.position = new B2Vec2(0, -10);
			var groundId = b2CreateBody(worldId, groundDef);
			b2CreatePolygonShape(groundId, b2DefaultShapeDef(), b2MakeBox(50, 10));

			var bodyDef = b2DefaultBodyDef();
			bodyDef.type = b2_dynamicBody;
			bodyDef.position = new B2Vec2(0, 4);
			var bodyId = b2CreateBody(worldId, bodyDef);
			var shapeDef = b2DefaultShapeDef();
			shapeDef.material.friction = 0.3;
			b2CreatePolygonShape(bodyId, shapeDef, b2MakeBox(1, 1));

			var position = new B2Vec2();
			var step = 0;
			while (b2Body_IsAwake(bodyId)) {
				b2World_Step(worldId, 1 / 60, 4);
				if (++step % 15 == 0)
					trace('${step / 60} s: ${Math.round(b2Body_GetPosition(bodyId, position).y * 1000) / 1000} m');
			}
			trace('at rest after ${step / 60} s');
			b2DestroyWorld(worldId);
		});
	}
}
