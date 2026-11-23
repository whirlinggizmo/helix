// helix-box2d's size ladder (tools/gen_sizes.py): each rung adds one thing to the one before; this one a box falling onto the ground and its position read.
import helix.box2d.*;
import helix.box2d.Box2D.*;

/** A program on helix-box2d alone, constructing only what it uses. */
@:adds("helix.box2d.B2BodyDef", "helix.box2d.B2Filter", "helix.box2d.B2MotionLocks", "helix.box2d.B2Polygon", "helix.box2d.B2ShapeDef",
	"helix.box2d.B2SurfaceMaterial")
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
			for (step in 0...60) {
				b2World_Step(worldId, 1 / 60, 4);
			}
			trace(b2Body_GetPosition(boxId, position).y);
			b2DestroyWorld(worldId);
		});
	}
}
