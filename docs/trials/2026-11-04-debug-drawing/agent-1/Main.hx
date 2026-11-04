import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Debug.*;
import helix.raylib.extras.Models.*;

class Main {
	static var model:Null<Model>;
	static var anims:Array<ModelAnimation> = [];
	static var animIndex = 0;
	static var frame = 0.0;
	static var camAngle = 0.0;
	static var camera:Camera3D;
	static var showSkeleton = false;
	static var showBounds = false;
	static var wires = false;
	static var hidden = false;
	static var many = false;

	static function main() {
		InitWindow(1280, 720, "Animation inspector");
		SetTargetFPS(30);

		camera = new Camera3D(new Vector3(6, 4, 6), new Vector3(0, 1, 0), new Vector3(0, 1, 0), 45, CAMERA_PERSPECTIVE);

		LoadModelAsync("assets/robot.glb", m -> model = m);
		LoadModelAnimationsAsync("assets/robot.glb", a -> anims = a);

		while (!WindowShouldClose()) {
			update();
			draw();
		}
		CloseWindow();
	}

	static function update() {
		var dt = GetFrameTime();
		camAngle += dt * 0.3;
		camera.position = new Vector3(Math.cos(camAngle) * 7, 4, Math.sin(camAngle) * 7);

		for (i in 0...9)
			if (IsKeyPressed(KEY_ONE + i) && i < anims.length) {
				animIndex = i;
				frame = 0;
			}
		if (IsKeyPressed(KEY_S)) showSkeleton = !showSkeleton;
		if (IsKeyPressed(KEY_B)) showBounds = !showBounds;
		if (IsKeyPressed(KEY_W)) wires = !wires;
		if (IsKeyPressed(KEY_H)) hidden = !hidden;
		if (IsKeyPressed(KEY_C)) many = !many;

		if (anims.length > 0) {
			var a = anims[animIndex];
			frame += dt * 30;
			if (frame >= a.frameCount) frame = 0;
		}
	}

	static function pose(f:Float) {
		if (model != null && anims.length > 0) UpdateModelAnimation(model, anims[animIndex], Std.int(f));
	}

	static function drawOne(pos:Vector3, f:Float) {
		if (model == null) return;
		pose(f);
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
		if (many) {
			var n = anims.length > 0 ? anims[animIndex].frameCount : 1;
			for (i in 0...5)
				drawOne(new Vector3((i - 2) * 2.5, 0, 0), (frame + i * n / 5) % n);
		} else {
			drawOne(new Vector3(0, 0, 0), frame);
		}
		EndMode3D();
		DrawFrameStatsEx(new Vector2(10, 10), {fontSize: 28, targetFps: 30, backgroundColor: Fade(BLACK, 0.5)});
		EndDrawing();
	}
}
