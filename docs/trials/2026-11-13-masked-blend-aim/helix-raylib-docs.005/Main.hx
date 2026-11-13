import helix.raylib.Raylib.*;
import helix.raylib.*;
import helix.raylib.extras.Models.*;

class Main {
	static inline var FPS_ANIM = 30.0;
	static inline var EASE = 0.2;

	static function findAnim(anims:Array<ModelAnimation>, name:String):ModelAnimation {
		// ModelAnimation.name is char[32], so long names arrive cut to 31 characters
		var want = name.substr(0, 31);
		for (a in anims)
			if (a.name.substr(0, 31) == want)
				return a;
		trace("animation not found: " + name);
		return null;
	}

	static function main() {
		var auto = false;
		var frames = -1;
		var shots = false;
		for (a in Sys.args()) {
			if (a == "--auto") auto = true;
			else if (a == "--shots") shots = true;
			else if (StringTools.startsWith(a, "--frames=")) frames = Std.parseInt(a.substr(9));
		}

		InitWindow(1280, 720, "Aiming on the run");
		SetTargetFPS(60);

		var names = ["Body", "Head", "Legs", "Feet"];
		var parts:Array<Model> = [];
		var anims:Array<ModelAnimation> = null;
		for (n in names)
			LoadModelAsync('assets/characters/Adventurer_$n.glb', m -> parts.push(m), e -> trace(e));
		LoadModelAnimationsAsync("assets/characters/Animations.glb", a -> anims = a, e -> trace(e));
		var model:Model = null;
		var run:ModelAnimation = null;
		var aim:ModelAnimation = null;
		var mask:Array<Float> = null;

		var camera = new Camera3D();
		camera.position = new Vector3(0, 1.2, 5);
		camera.target = new Vector3(0, 1.0, 0);
		camera.up = new Vector3(0, 1, 0);
		camera.fovy = 40;
		camera.projection = CAMERA_PERSPECTIVE;

		var aiming = false;
		var aimOnly = false;
		var blend = 0.0;
		var runT = 0.0;
		var aimT = 0.0;
		var autoT = 0.0;
		var frame = 0;

		while (!WindowShouldClose()) {
			if (frames >= 0 && frame >= frames) break;
			if (model == null) {
				if (parts.length == names.length && anims != null) {
					// parts arrive in any order: the body is the skeleton, found by its mesh count being the least bones-wise; use the first with bones
					var skel = parts[0];
					for (p in parts) if (p.boneCount > skel.boneCount) skel = p;
					model = LoadModelFromModels(parts, skel);
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
			var dt = GetFrameTime();
			if (shots) {
				// scripted: run, then aim, then aim alone
				aiming = frame >= 60;
				aimOnly = frame >= 120;
			} else {
				if (IsKeyPressed(KEY_SPACE)) aiming = !aiming;
				if (IsKeyPressed(KEY_A)) aimOnly = !aimOnly;
				if (auto) {
					autoT += dt;
					if (autoT >= 2.0) {
						autoT -= 2.0;
						aiming = !aiming;
					}
				}
			}
			var target = aiming ? 1.0 : 0.0;
			var step = dt / EASE;
			if (blend < target) blend = Math.min(target, blend + step);
			else if (blend > target) blend = Math.max(target, blend - step);
			var eased = blend * blend * (3 - 2 * blend);

			runT += dt * FPS_ANIM;
			aimT += dt * FPS_ANIM;

			if (aimOnly) UpdateModelAnimation(model, aim, Std.int(aimT) % aim.frameCount);
			else UpdateModelAnimationMasked(model, run, runT, aim, aimT, mask, eased, BLEND_ROTATION_MODEL);

			BeginDrawing();
			ClearBackground(RAYWHITE);
			BeginMode3D(camera);
			DrawModel(model, new Vector3(0, 0, 0), 1.0, WHITE);
			DrawGrid(10, 1.0);
			EndMode3D();
			var label = aimOnly ? "Aiming: yes (aim alone, legs still)" : (aiming ? "Aiming: yes" : "Aiming: no");
			DrawText(label, 10, 10, 30, DARKGRAY);
			EndDrawing();

			if (shots) {
				if (frame == 50) TakeScreenshotAsync("shot_run.png");
				if (frame == 110) TakeScreenshotAsync("shot_aim.png");
				if (frame == 170) TakeScreenshotAsync("shot_aim_alone.png");
			}
			frame++;
		}
		CloseWindow();
	}
}
