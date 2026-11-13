import helix.raylib.Raylib.*;
import helix.raylib.*;
import helix.raylib.extras.Models.*;

class Main {
	static function find(anims:Array<ModelAnimation>, name:String):ModelAnimation {
		for (a in anims) if (a.name == name) return a;
		return null;
	}

	static function main() {
		var maxFrames = -1;
		var auto = false;
		for (a in Sys.args()) {
			if (a == "--auto") auto = true;
			else if (StringTools.startsWith(a, "--frames=")) maxFrames = Std.parseInt(a.substr(9));
		}
		InitWindow(1280, 720, "aim on the run");
		SetTargetFPS(60);

		var parts:Array<Model> = [];
		var anims:Array<ModelAnimation> = null;
		for (n in ["Body", "Head", "Legs", "Feet"])
			LoadModelAsync("assets/characters/Adventurer_" + n + ".glb", m -> parts.push(m), e -> Sys.println("load failed: " + e));
		LoadModelAnimationsAsync("assets/characters/Animations.glb", a -> anims = a, e -> Sys.println("load failed: " + e));
		var waited = 0;
		while (!WindowShouldClose() && waited < 600 && (parts.length < 4 || anims == null)) {
			BeginDrawing();
			ClearBackground(RAYWHITE);
			DrawText("Loading...", 20, 20, 20, DARKGRAY);
			EndDrawing();
			waited++;
		}
		// Body first: its skeleton is the shared one
		var model = LoadModelFromModels(parts, parts[0]);
		var run = find(anims, "CharacterArmature|Run_Left");
		var aim = find(anims, "CharacterArmature|Idle_Gun_Pointing");
		var mask = GetModelBoneMask(model, "Abdomen");

		var camera = new Camera3D(new Vector3(0, 1.1, 4.5), new Vector3(0, 1.0, 0), new Vector3(0, 1, 0), 40, CAMERA_PERSPECTIVE);

		var aiming = false;
		var aimOnly = false; // screenshot aid: the aim animation alone, legs still
		var blend = 0.0;
		var t = 0.0;
		var autoTimer = 0.0;
		var frame = 0;
		while (!WindowShouldClose() && (maxFrames < 0 || frame < maxFrames)) {
			var dt = maxFrames >= 0 ? 1.0 / 60 : GetFrameTime();
			t += dt;
			if (IsKeyPressed(KEY_SPACE)) aiming = !aiming;
			if (auto) {
				autoTimer += dt;
				if (autoTimer >= 2.0) { autoTimer -= 2.0; aiming = !aiming; }
			}
			if (maxFrames >= 0) {
				// scripted for screenshots: aim on at frame 40, aim alone from frame 120
				aiming = frame >= 40;
				aimOnly = frame >= 120;
			}
			var target = aiming ? 1.0 : 0.0;
			var step = dt / 0.2;
			if (blend < target) blend = Math.min(target, blend + step);
			else if (blend > target) blend = Math.max(target, blend - step);
			// smoothstep so there is no snap at either end
			var eased = blend * blend * (3 - 2 * blend);

			// both animations are 60 frames a second and loop
			var fRun = (t * 60) % run.frameCount;
			var fAim = (t * 60) % aim.frameCount;
			if (aimOnly) UpdateModelAnimation(model, aim, Std.int(fAim));
			else UpdateModelAnimationMasked(model, run, fRun, aim, fAim, mask, eased, BLEND_ROTATION_MODEL);

			BeginDrawing();
			ClearBackground(RAYWHITE);
			BeginMode3D(camera);
			DrawModel(model, new Vector3(0, 0, 0), 1.0, WHITE);
			DrawGrid(10, 1.0);
			EndMode3D();
			DrawText(aiming ? "Aiming: YES" : "Aiming: no", 20, 20, 30, BLACK);
			EndDrawing();

			if (maxFrames >= 0 && (frame == 30 || frame == 100 || frame == 150)) {
				var name = frame == 30 ? "run" : frame == 100 ? "aim" : "aim_alone";
				TakeScreenshotAsync("shot_" + name + ".png");
			}
			frame++;
		}
		CloseWindow();
	}
}
