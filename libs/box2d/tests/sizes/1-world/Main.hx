// helix-box2d's size ladder (tools/gen_sizes.py): each rung adds one thing to the one before; this one a world stepped.
import helix.box2d.*;
import helix.box2d.Box2D.*;

/** A program on helix-box2d alone, constructing only what it uses. */
@:adds("helix.box2d.B2AABB", "helix.box2d.B2BodyId", "helix.box2d.B2Capacity", "helix.box2d.B2DebugDraw", "helix.box2d.B2JointId", "helix.box2d.B2Manifold",
	"helix.box2d.B2ManifoldPoint", "helix.box2d.B2Plane", "helix.box2d.B2PlaneResult", "helix.box2d.B2Rot", "helix.box2d.B2ShapeId",
	"helix.box2d.B2Transform", "helix.box2d.B2WorldDef", "helix.box2d.B2WorldId", "helix.box2d.Box2D", "helix.box2d.internal.Callbacks",
	"helix.box2d.internal.Calls", "helix.box2d.internal.Data", "helix.box2d.internal.Dispatch", "helix.box2d.internal.Init", "helix.box2d.internal.Io",
	"helix.math.Vector2")
class Main {
	static function main():Void {
		Box2D.loadAsync(() -> {
			var worldId = b2CreateWorld(b2DefaultWorldDef());
			for (step in 0...60) {
				b2World_Step(worldId, 1 / 60, 4);
			}
			b2DestroyWorld(worldId);
		});
	}
}
