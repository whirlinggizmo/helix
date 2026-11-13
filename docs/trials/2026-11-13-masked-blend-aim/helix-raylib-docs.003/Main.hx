import helix.raylib.Raylib.*;
import helix.raylib.*;
import helix.raylib.extras.Models.*;

class Main {
	static function findAnim(anims:Array<ModelAnimation>, name:String):ModelAnimation {
		for (a in anims)
			if (a.name == name)
				return a;
		throw "no animation " + name;
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

		var names = ["Head", "Body", "Legs", "Feet"];
		var parts:Array<Model> = [];
		var anims:Array<ModelAnimation> = null;
		var failed:String = null;
		for (i in 0...names.length)
			LoadModelAsync('assets/characters/Adventurer_${names[i]}.glb', m -> parts[i] = m, e -> failed = e);
		LoadModelAnimationsAsync("assets/characters/Animations.glb", a -> anims = a, e -> failed = e);
		var model:Model = null;
		var run:ModelAnimation = null;
		var aim:ModelAnimation = null;
		var mask:Array<Float> = null;

		var camera = new Camera3D();
		camera.position = new Vector3(0, 1.2, 4.5);
		camera.target = new Vector3(0, 1.0, 0);
		camera.up = new Vector3(0, 1, 0);
		camera.fovy = 45;
		camera.projection = CAMERA_PERSPECTIVE;

		var aiming = false;
		var blend = 0.0;
		var t = 0.0;
		var autoTimer = 0.0;
		var frame = 0;
		var dt = 1.0 / 60.0;
		var fps = 30.0;
		var aimOnlyView = false;

		while (!WindowShouldClose()) {
			if (model == null) {
				var n = 0;
				for (i in 0...names.length) if (parts[i] != null) n++;
				if (failed != null) throw failed;
				if (n == names.length && anims != null) {
					model = LoadModelFromModels(parts, parts[2]);
					run = findAnim(anims, "CharacterArmature|Run_Left");
					aim = findAnim(anims, "CharacterArmature|Idle_Gun_Pointing");
					mask = GetModelBoneMask(model, "Abdomen");
				} else {
					BeginDrawing();
					ClearBackground(RAYWHITE);
					DrawText("Loading...", 10, 10, 30, DARKGRAY);
					EndDrawing();
					continue;
				}
			}
			if (maxFrames >= 0 && frame >= maxFrames) break;

			if (shots) {
				// scripted: run, then aim, then aim alone
				aiming = frame >= 90;
				aimOnlyView = frame >= 180;
			} else {
				if (IsKeyPressed(KEY_SPACE)) aiming = !aiming;
				if (auto) {
					autoTimer += dt;
					if (autoTimer >= 2.0) {
						autoTimer -= 2.0;
						aiming = !aiming;
					}
				}
			}

			var target = aiming ? 1.0 : 0.0;
			var step = dt / 0.2;
			if (blend < target) blend = Math.min(target, blend + step);
			else if (blend > target) blend = Math.max(target, blend - step);
			var eased = blend * blend * (3 - 2 * blend);

			t += dt;
			var fr = t * fps;
			if (aimOnlyView) {
				UpdateModelAnimation(model, aim, Std.int(fr) % aim.frameCount);
			} else {
				UpdateModelAnimationMasked(model, run, fr, aim, fr, mask, eased, BLEND_ROTATION_MODEL);
			}

			BeginDrawing();
			ClearBackground(RAYWHITE);
			BeginMode3D(camera);
			DrawModel(model, new Vector3(0, 0, 0), 1.0, WHITE);
			DrawGrid(10, 1.0);
			EndMode3D();
			DrawText(aimOnlyView ? "Aiming: yes (aim alone, legs still)" : (aiming ? "Aiming: yes" : "Aiming: no"), 10, 10, 30, DARKGRAY);
			EndDrawing();

			if (shots && (frame == 80 || frame == 170 || frame == 200))
				TakeScreenshotAsync('shot_${frame == 80 ? "run" : frame == 170 ? "aim" : "aimalone"}.png');
			frame++;
		}
		CloseWindow();
	}
}
