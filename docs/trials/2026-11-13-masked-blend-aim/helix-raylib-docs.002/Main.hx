import helix.raylib.Raylib.*;
import helix.raylib.Model;
import helix.raylib.ModelAnimation;
import helix.raylib.Camera3D;
import helix.raylib.Vector3;
import helix.raylib.extras.Models.*;

class Main {
	static inline var FPS = 60;
	static inline var BLEND_TIME = 0.2;
	static final PARTS = ["Body", "Head", "Legs", "Feet"];

	static var parts:Array<Model> = [];
	static var anims:Array<ModelAnimation> = null;

	static function main() {
		var autoAim = false;
		var maxFrames = -1;
		var shots = false;
		var solo = false;
		for (a in Sys.args()) {
			if (a == "--auto") autoAim = true;
			else if (a == "--shots") shots = true;
			else if (StringTools.startsWith(a, "--frames=")) maxFrames = Std.parseInt(a.substr(9));
		}

		InitWindow(1280, 720, "Aiming on the run");
		SetTargetFPS(FPS);

		for (p in PARTS) {
			LoadModelAsync("assets/characters/Adventurer_" + p + ".glb", function(m) parts.push(m), function(e) trace("load failed: " + e));
		}
		LoadModelAnimationsAsync("assets/characters/Animations.glb", function(a) anims = a, function(e) trace("load failed: " + e));

		var camera = new Camera3D();
		camera.position = new Vector3(0, 1.1, 4.5);
		camera.target = new Vector3(0, 0.95, 0);
		camera.up = new Vector3(0, 1, 0);
		camera.fovy = 40;
		camera.projection = CAMERA_PERSPECTIVE;

		var model:Model = null;
		var run:ModelAnimation = null;
		var aim:ModelAnimation = null;
		var mask:Array<Float> = null;

		var aiming = false;
		var blend = 0.0;
		var time = 0.0;
		var autoTimer = 0.0;
		var frame = 0;
		var shotsTaken = 0;

		while (!WindowShouldClose() && (maxFrames < 0 || frame < maxFrames)) {
			if (model == null && parts.length == PARTS.length && anims != null) {
				// Order by PARTS is irrelevant for merging; the skeleton is any of them.
				model = LoadModelFromModels(parts, parts[0]);
				for (a in anims) {
					if (a.name == "CharacterArmature|Run_Left") run = a;
					else if (a.name == "CharacterArmature|Idle_Gun_Pointing") aim = a;
				}
				mask = GetModelBoneMask(model, "Abdomen");
			}

			var dt = shots ? 1.0 / FPS : GetFrameTime();
			if (model != null) {
				if (IsKeyPressed(KEY_SPACE)) aiming = !aiming;
				if (autoAim) {
					autoTimer += dt;
					if (autoTimer >= 2.0) { autoTimer -= 2.0; aiming = !aiming; }
				}
				// Scripted screenshot run: run, aim, then the aim alone.
				if (shots) {
					if (frame == 30) aiming = false;
					if (frame == 31) aiming = true;
					if (frame == 100) solo = true;
				}
				var target = aiming ? 1.0 : 0.0;
				var step = dt / BLEND_TIME;
				blend = blend < target ? Math.min(target, blend + step) : Math.max(target, blend - step);
				time += dt;

				var fRun = (time * FPS) % run.frameCount;
				var fAim = (time * FPS) % aim.frameCount;
				if (solo) {
					UpdateModelAnimation(model, aim, Std.int(fAim));
				} else {
					UpdateModelAnimationMasked(model, run, fRun, aim, fAim, mask, blend, BLEND_ROTATION_MODEL);
				}
			}

			BeginDrawing();
			ClearBackground(RAYWHITE);
			if (model != null) {
				BeginMode3D(camera);
				DrawModel(model, new Vector3(0, 0, 0), 1.0, WHITE);
				DrawGrid(10, 1.0);
				EndMode3D();
			}
			var label = solo ? "Aiming: yes (aim alone)" : (aiming ? "Aiming: yes" : "Aiming: no");
			DrawText(label, 10, 10, 30, DARKGRAY);
			EndDrawing();

			if (shots && model != null) {
				if (frame == 29) TakeScreenshotAsync("shot_run.png");
				if (frame == 90) TakeScreenshotAsync("shot_aim.png");
				if (frame == 130) TakeScreenshotAsync("shot_aim_alone.png");
			}
			frame++;
		}
		CloseWindow();
	}
}
