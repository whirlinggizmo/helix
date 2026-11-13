import helix.raylib.Raylib.*;
import helix.raylib.*;
import helix.raylib.extras.Models.*;

class Main {
	static final FPS_ANIM = 30.0;
	static final BLEND_TIME = 0.2;

	static function findAnim(anims:Array<ModelAnimation>, name:String):ModelAnimation {
		for (a in anims) if (a.name == name) return a;
		return null;
	}

	static function main() {
		var auto = false;
		var maxFrames = -1;
		var shots = false;
		for (a in Sys.args()) {
			if (a == "--auto") auto = true;
			else if (a == "--shots") shots = true;
			else if (StringTools.startsWith(a, "--frames=")) maxFrames = Std.parseInt(a.substr(9));
		}

		InitWindow(1280, 720, "Aiming on the run");
		SetTargetFPS(60);

		var parts:Array<Model> = [];
		var names = ["Body", "Head", "Legs", "Feet"];
		var pending = names.length;
		for (i in 0...names.length) {
			LoadModelAsync("assets/characters/Adventurer_" + names[i] + ".glb", m -> { parts[i] = m; pending--; }, e -> trace("load failed: " + e));
		}
		var anims:Array<ModelAnimation> = null;
		LoadModelAnimationsAsync("assets/characters/Animations.glb", a -> anims = a, e -> trace("anim load failed: " + e));
		while (!WindowShouldClose() && (pending > 0 || anims == null)) {
			BeginDrawing();
			ClearBackground(RAYWHITE);
			DrawText("Loading...", 20, 20, 20, DARKGRAY);
			EndDrawing();
		}
		if (pending > 0 || anims == null) { CloseWindow(); return; }

		var model = LoadModelFromModels(parts, parts[0]);
		var run = findAnim(anims, "CharacterArmature|Run_Left");
		var aimAnim = findAnim(anims, "CharacterArmature|Idle_Gun_Pointing");
		var mask = GetModelBoneMask(model, "Abdomen");

		var camera = new Camera3D(new Vector3(0, 1.1, 4.5), new Vector3(0, 0.95, 0), new Vector3(0, 1, 0), 40, CAMERA_PERSPECTIVE);

		var aiming = false;
		var aimOnly = false;
		var blend = 0.0;
		var timer = 0.0;
		var runT = 0.0;
		var aimT = 0.0;
		var frame = 0;

		while (!WindowShouldClose() && (maxFrames < 0 || frame < maxFrames)) {
			var dt = GetFrameTime();
			if (IsKeyPressed(KEY_SPACE)) aiming = !aiming;
			if (auto) {
				timer += dt;
				if (timer >= 2.0) { timer -= 2.0; aiming = !aiming; }
			}
			if (shots) {
				// scripted: run, aim, aim alone
				if (frame == 0) aiming = false;
				if (frame == 40) aiming = true;
				if (frame == 100) aimOnly = true;
			}

			var target = aiming ? 1.0 : 0.0;
			var step = dt / BLEND_TIME;
			if (blend < target) blend = Math.min(target, blend + step);
			else if (blend > target) blend = Math.max(target, blend - step);
			var w = blend * blend * (3 - 2 * blend);

			runT += dt * FPS_ANIM;
			aimT += dt * FPS_ANIM;

			if (aimOnly) UpdateModelAnimation(model, aimAnim, Std.int(aimT) % aimAnim.frameCount);
			else UpdateModelAnimationMasked(model, run, runT, aimAnim, aimT, mask, w, BLEND_ROTATION_MODEL);

			BeginDrawing();
			ClearBackground(RAYWHITE);
			BeginMode3D(camera);
			DrawModel(model, new Vector3(0, 0, 0), 1.0, WHITE);
			DrawGrid(10, 1.0);
			EndMode3D();
			DrawText(aimOnly ? "Aiming: YES (aim alone)" : (aiming ? "Aiming: YES" : "Aiming: NO"), 20, 20, 30, DARKGRAY);
			EndDrawing();

			if (shots) {
				if (frame == 30) TakeScreenshotAsync("shot_run.png");
				if (frame == 90) TakeScreenshotAsync("shot_aim.png");
				if (frame == 150) TakeScreenshotAsync("shot_aim_alone.png");
			}
			frame++;
		}
		CloseWindow();
	}
}
