import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Debug.*;
import helix.raylib.extras.Models.*;

class Main {
	static var model:Model;
	static var anims:Array<ModelAnimation>;
	static var animIndex = 0;
	static var frame = 0.0;
	static var camera:Camera3D;
	static var angle = 0.0;
	static var showSkeleton = false;
	static var showBounds = false;
	static var wires = false;
	static var hidden = false;
	static var multi = false;

	static function main() {
		InitWindow(1280, 720, "Animation inspector");
		SetTargetFPS(30);

		anims = [];
		LoadModelAsync("assets/robot.glb", m -> model = m);
		LoadModelAnimationsAsync("assets/robot.glb", a -> anims = a);

		camera = new Camera3D(new Vector3(6, 4, 6), new Vector3(0, 1, 0), new Vector3(0, 1, 0), 45, CAMERA_PERSPECTIVE);

		while (!WindowShouldClose()) {
			update();
			draw();
		}
		CloseWindow();
	}

	static function update() {
		var dt = GetFrameTime();
		angle += dt * 0.3;
		var r = multi ? 12.0 : 7.0;
		camera.position = new Vector3(Math.cos(angle) * r, 4, Math.sin(angle) * r);

		if (IsKeyPressed(KEY_S)) showSkeleton = !showSkeleton;
		if (IsKeyPressed(KEY_B)) showBounds = !showBounds;
		if (IsKeyPressed(KEY_W)) wires = !wires;
		if (IsKeyPressed(KEY_H)) hidden = !hidden;
		if (IsKeyPressed(KEY_C)) multi = !multi;

		for (i in 0...9) {
			if (IsKeyPressed(KEY_ONE + i) && i < anims.length) {
				animIndex = i;
				frame = 0;
			}
		}
		frame += dt * 30;
	}

	static function pose(count:Int) {
		var a = anims[animIndex];
		var n = a.frameCount;
		var f = Std.int(frame + count * n / 5) % n;
		UpdateModelAnimation(model, a, f);
	}

	static function drawOne(pos:Vector3) {
		if (!hidden) {
			if (wires) DrawModelWires(model, pos, 1, WHITE);
			else DrawModel(model, pos, 1, WHITE);
		}
		if (showSkeleton) DrawModelSkeleton(model, pos, 1, YELLOW);
		if (showBounds) DrawModelBoundingBoxPosed(model, pos, 1, RED);
	}

	static function draw() {
		BeginDrawing();
		ClearBackground(DARKGRAY);
		BeginMode3D(camera);
		DrawGrid(20, 1);
		if (model != null && anims.length > 0) {
			if (multi) {
				for (i in 0...5) {
					pose(i);
					drawOne(new Vector3((i - 2) * 2.5, 0, 0));
				}
			} else {
				pose(0);
				drawOne(new Vector3(0, 0, 0));
			}
		}
		EndMode3D();
		DrawFrameStatsEx(new Vector2(10, 10), {fontSize: 28, targetFps: 30, backgroundColor: Fade(BLACK, 0.5)});
		EndDrawing();
	}
}
