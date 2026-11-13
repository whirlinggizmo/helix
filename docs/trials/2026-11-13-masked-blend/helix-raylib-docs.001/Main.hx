import helix.raylib.Raylib.*;
import helix.raylib.*;
import helix.raylib.extras.Models.*;

class Main {
	static function findAnim(anims:Array<ModelAnimation>, name:String):ModelAnimation {
		for (a in anims) if (a.name == name) return a;
		trace("animation not found: " + name);
		return anims[0];
	}

	static function main() {
		var auto = false, maxFrames = -1, shots = false;
		for (a in Sys.args()) {
			if (a == "--auto") auto = true;
			else if (a == "--shots") shots = true;
			else if (StringTools.startsWith(a, "--frames=")) maxFrames = Std.parseInt(a.substr(9));
		}

		InitWindow(1280, 720, "slashing on the run");
		SetTargetFPS(60);

		var fps = 24.0;
		var names = ["Head", "Body", "Legs", "Feet"];
		var parts:Array<Model> = [];
		var anims:Array<ModelAnimation> = null;
		for (n in names) LoadModelAsync('assets/characters/Adventurer_$n.glb', function(m) parts.push(m), function(e) trace(e));
		LoadModelAnimationsAsync("assets/characters/Animations.glb", function(a) anims = a, function(e) trace(e));
		var model:Model = null;
		var run:ModelAnimation = null;
		var slash:ModelAnimation = null;
		var mask:Array<Float> = null;
		var slashDur = 1.0;
		var shotPending = 0;

		var camera = new Camera3D();
		camera.position = new Vector3(1.5, 1.4, 4.0);
		camera.target = new Vector3(0, 1.0, 0);
		camera.up = new Vector3(0, 1, 0);
		camera.fovy = 45;
		camera.projection = CAMERA_PERSPECTIVE;

		var slashT = -1.0; // < 0: not slashing
		var runFrame = 0.0;
		var autoTimer = 0.0;
		var frame = 0;
		var shotsTaken = [false, false, false];

		while (!WindowShouldClose()) {
			var dt = 1.0 / 60.0;
			if (model == null) {
				if (parts.length == 4 && anims != null) {
					// the four share one skeleton, so any of them can stand for it
					model = LoadModelFromModels(parts, parts[0]);
					run = findAnim(anims, "CharacterArmature|Run");
					slash = findAnim(anims, "CharacterArmature|Sword_Slash");
					mask = GetModelBoneMask(model, "Abdomen");
					slashDur = slash.frameCount / fps;
				}
				BeginDrawing();
				ClearBackground(RAYWHITE);
				DrawText("Loading...", 10, 10, 20, DARKGRAY);
				EndDrawing();
				continue;
			}
			if (maxFrames >= 0 && frame >= maxFrames) break;

			var trigger = IsKeyPressed(KEY_SPACE);
			if (auto) {
				autoTimer += dt;
				if (autoTimer >= 2.0) { autoTimer -= 2.0; trigger = true; }
			}
			if (shots && frame == 30) trigger = true;
			if (trigger && slashT < 0) slashT = 0;

			runFrame = (runFrame + dt * fps) % run.frameCount;

			var blend = 0.0;
			var slashFrame = 0.0;
			var progress = 0.0;
			if (slashT >= 0) {
				slashT += dt;
				if (slashT >= slashDur) slashT = -1;
				else {
					var e = Math.min(slashT / 0.15, (slashDur - slashT) / 0.15);
					e = Math.max(0, Math.min(1, e));
					blend = e * e * (3 - 2 * e);
					slashFrame = slashT * fps;
					progress = slashT / slashDur;
				}
			}
			UpdateModelAnimationMasked(model, run, runFrame, slash, slashFrame, mask, blend);

			BeginDrawing();
			ClearBackground(RAYWHITE);
			BeginMode3D(camera);
			DrawModel(model, new Vector3(0, 0, 0), 1.0, WHITE);
			DrawGrid(10, 1.0);
			EndMode3D();
			if (slashT >= 0) DrawText("Slash: playing " + Std.int(progress * 100) + "%", 10, 10, 20, DARKGRAY);
			else DrawText("Slash: idle", 10, 10, 20, DARKGRAY);
			EndDrawing();

			if (shots) {
				if (frame == 20 && !shotsTaken[0]) { TakeScreenshotAsync("shot_before.png"); shotsTaken[0] = true; }
				if (slashT >= slashDur * 0.5 && !shotsTaken[1]) { TakeScreenshotAsync("shot_mid.png"); shotsTaken[1] = true; }
				if (slashT >= slashDur - 0.08 && !shotsTaken[2]) { TakeScreenshotAsync("shot_out.png"); shotsTaken[2] = true; }
			}
			frame++;
		}
		CloseWindow();
	}
}
