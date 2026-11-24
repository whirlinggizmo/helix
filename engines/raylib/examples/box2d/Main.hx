import helix.box2d.*;
import helix.box2d.Box2D.*;
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.extras.Screen.*;

/** Box2D: a pyramid of boxes, stepped by helix-box2d and drawn with raylib's shapes. Pressing on a box drags it, pressing on empty space
	throws a ball down from there, and Reset (or R) builds the pyramid again. A body Box2D has put to sleep is drawn dimmer: the pyramid starts
	asleep, and wakes where it is hit. The `quit_after_frame` option (`--quit_after_frame=60` natively, `?quit_after_frame=60` in a page)
	quits it after that frame. */
class Main {
	/** Pixels a meter. */
	static inline final SCALE = 30.0;

	/** The ground's top, in design pixels. */
	static inline final GROUND = 420.0;

	static inline final ROWS = 10;
	static inline final MOST_BALLS = 40;

	static var world:B2WorldId;
	static var boxes:Array<B2BodyId> = [];
	static var balls:Array<B2BodyId> = [];
	static var dragged:Null<B2BodyId> = null;
	static var pressed = new B2Vec2();
	static var found:Null<B2BodyId> = null;

	static function main():Void {
		InitWindow(800, 450, "helix-raylib: box2d");
		// The 800 x 450 design fitted to any window, a phone's too (helix.raylib.extras.Screen).
		SetScreenFit(800, 450, SCREEN_STRETCH_CANVAS, SCREEN_FIT_EXPAND, false);
		SetTargetFPS(60);
		GuiSetStyle(DEFAULT, TEXT_SIZE, 20);
		var ready = false;
		Box2D.loadAsync(() -> {
			build();
			ready = true;
		});
		var visible = new Rectangle(0, 0, 0, 0),
			reset = new Rectangle(0, 0, 120, 48),
			area = new Rectangle(0, 0, 0, 0);
		var mouse = new Vector2(0, 0),
			point = new B2Vec2(),
			velocity = new B2Vec2(),
			position = new B2Vec2(),
			rotation = new B2Rot();
		// Each box drawn a pixel in from its edges, so the boxes read apart.
		var box = new Rectangle(0, 0, SCALE - 2, SCALE - 2),
			half = new Vector2(SCALE / 2 - 1, SCALE / 2 - 1),
			center = new Vector2(0, 0),
			rim = new Vector2(0, 0);
		while (!WindowShouldClose()) {
			GetScreenVisibleArea(visible);
			reset.x = visible.x + visible.width - reset.width - 10;
			reset.y = visible.y + 10;
			GetMousePosition(mouse);
			toWorld(mouse, point);
			if (ready) {
				if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT) && !CheckCollisionPointRec(mouse, reset)) {
					dragged = bodyAt(point);
					if (dragged == null && point.y > 0.5)
						dropBall(point);
				}
				if (!IsMouseButtonDown(MOUSE_BUTTON_LEFT))
					dragged = null;
				if (dragged != null) {
					// Steered toward the pointer: its velocity set each step to close the gap in a fifth of a second.
					b2Body_GetPosition(dragged, position);
					velocity.x = (point.x - position.x) * 5;
					velocity.y = (point.y - position.y) * 5;
					b2Body_SetLinearVelocity(dragged, velocity);
				}
				b2World_Step(world, 1 / 60, 4);
			}

			BeginDrawing();
			ClearBackground(new Color(24, 28, 38, 255));
			area.x = visible.x;
			area.y = GROUND;
			area.width = visible.width;
			area.height = visible.y + visible.height - GROUND;
			DrawRectangleRec(area, new Color(70, 76, 92, 255));
			if (!ready)
				DrawText("Loading Box2D...", 320, 200, 20, LIGHTGRAY);
			else {
				for (body in boxes) {
					b2Body_GetPosition(body, position);
					b2Body_GetRotation(body, rotation);
					box.x = 400 + position.x * SCALE;
					box.y = GROUND - position.y * SCALE;
					DrawRectanglePro(box, half, -b2Rot_GetAngle(rotation) * RAD2DEG,
						b2Body_IsAwake(body) ? new Color(240, 160, 60, 255) : new Color(150, 100, 50, 255));
				}
				for (body in balls) {
					b2Body_GetPosition(body, position);
					b2Body_GetRotation(body, rotation);
					center.x = 400 + position.x * SCALE;
					center.y = GROUND - position.y * SCALE;
					rim.x = center.x + rotation.c * SCALE * 0.5;
					rim.y = center.y - rotation.s * SCALE * 0.5;
					DrawCircleV(center, SCALE * 0.5, b2Body_IsAwake(body) ? new Color(90, 180, 240, 255) : new Color(60, 110, 150, 255));
					DrawLineV(center, rim, new Color(24, 28, 38, 255));
				}
				var count = boxes.length + balls.length;
				DrawText('$count bodies, ${b2World_GetAwakeBodyCount(world)} awake, ${GetFPS()} fps', Std.int(visible.x) + 10, Std.int(visible.y) + 10, 20,
					LIGHTGRAY);
				DrawText("Drag a box. Press empty space for a ball.", Std.int(visible.x) + 10, Std.int(visible.y + visible.height) - 28, 20, LIGHTGRAY);
				if (GuiButton(reset, "Reset") == 1 || IsKeyPressed(KEY_R))
					build();
			}
			EndDrawing();
		}
		if (ready)
			b2DestroyWorld(world);
		CloseWindow();
	}

	/** Builds the world again: the ground and the pyramid, its boxes asleep until something hits them. */
	static function build():Void {
		if (boxes.length > 0 || balls.length > 0)
			b2DestroyWorld(world);
		boxes.resize(0);
		balls.resize(0);
		dragged = null;
		world = b2CreateWorld(b2DefaultWorldDef());

		var groundDef = b2DefaultBodyDef();
		groundDef.position = new B2Vec2(0, -1);
		b2CreatePolygonShape(b2CreateBody(world, groundDef), b2DefaultShapeDef(), b2MakeBox(60, 1));

		var square = b2MakeBox(0.5, 0.5);
		var shapeDef = b2DefaultShapeDef();
		shapeDef.material.friction = 0.6;
		for (row in 0...ROWS)
			for (column in 0...ROWS - row) {
				var bodyDef = b2DefaultBodyDef();
				bodyDef.type = b2_dynamicBody;
				bodyDef.isAwake = false;
				bodyDef.position = new B2Vec2(column - (ROWS - row - 1) / 2, 0.5 + row);
				var body = b2CreateBody(world, bodyDef);
				b2CreatePolygonShape(body, shapeDef, square);
				boxes.push(body);
			}
	}

	/** Throws a ball down from a point, the oldest ball removed past `MOST_BALLS`. */
	static function dropBall(at:B2Vec2):Void {
		if (balls.length == MOST_BALLS)
			b2DestroyBody(balls.shift());
		var bodyDef = b2DefaultBodyDef();
		bodyDef.type = b2_dynamicBody;
		bodyDef.position = new B2Vec2(at.x, at.y);
		// Thrown down, as a drop from rest reaches the pyramid too slowly to break it.
		bodyDef.linearVelocity = new B2Vec2(0, -15);
		var body = b2CreateBody(world, bodyDef);
		var shapeDef = b2DefaultShapeDef();
		// Twenty times a box's density, so a ball breaks the pyramid rather than bouncing off it.
		shapeDef.density = 20;
		var circle = new B2Circle();
		circle.radius = 0.5;
		b2CreateCircleShape(body, shapeDef, circle);
		balls.push(body);
	}

	/** The dynamic body under a point, or null. */
	static function bodyAt(point:B2Vec2):Null<B2BodyId> {
		pressed.x = point.x;
		pressed.y = point.y;
		found = null;
		var aabb = new B2AABB();
		aabb.lowerBound = new B2Vec2(-0.01, -0.01);
		aabb.upperBound = new B2Vec2(0.01, 0.01);
		b2World_OverlapAABB(world, point, aabb, b2DefaultQueryFilter(), hit, null);
		return found;
	}

	static function hit(shapeId:B2ShapeId, context:Dynamic):Bool {
		if (!b2Shape_TestPoint(shapeId, pressed))
			return true;
		var body = b2Shape_GetBody(shapeId);
		if (b2Body_GetType(body) != b2_dynamicBody)
			return true;
		found = body;
		return false;
	}

	/** A design pixel's point in the world, in meters. */
	static function toWorld(pixel:Vector2, out:B2Vec2):Void {
		out.x = (pixel.x - 400) / SCALE;
		out.y = (GROUND - pixel.y) / SCALE;
	}
}
