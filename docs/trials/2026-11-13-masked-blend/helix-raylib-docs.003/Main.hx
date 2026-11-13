import helix.raylib.Raylib.*;
import helix.raylib.*;
import helix.raylib.extras.Models.*;

class Main {
	static inline var FPS_ANIM = 60.0;
	static inline var EASE = 0.15;

	static function main() {
		var auto = false;
		var maxFrames = -1;
		for (a in Sys.args()) {
			if (a == "--auto") auto = true;
			else if (StringTools.startsWith(a, "--frames=")) maxFrames = Std.parseInt(a.substr(9));
		}

		InitWindow(1280, 720, "Slashing on the run");
		SetTargetFPS(60);

		var parts:Array<Model> = [];
		var anims:Array<ModelAnimation> = null;
		for (n in ["Head", "Body", "Legs", "Feet"]) {
			LoadModelAsync('assets/characters/Adventurer_$n.glb', m -> parts.push(m), e -> trace(e));
		}
		LoadModelAnimationsAsync("assets/characters/Animations.glb", a -> anims = a, e -> trace(e));
		var model:Model = null;
		var run:ModelAnimation = null;
		var slash:ModelAnimation = null;
		var mask:Array<Float> = null;
		var slashDur = 1.0;

		var camera = new Camera3D();
		camera.position = new Vector3(2.5, 1.6, 4.0);
		camera.target = new Vector3(0, 0.9, 0);
		camera.up = new Vector3(0, 1, 0);
		camera.fovy = 45;
		camera.projection = CAMERA_PERSPECTIVE;

		var runT = 0.0;
		var slashT = 0.0;
		var slashing = false;
		var autoTimer = 0.0;
		var frame = 0;
		var shots = 0;

		while (!WindowShouldClose()) {
			if (model == null) {
				if (parts.length == 4 && anims != null) {
					// loads may finish in any order: put Body first as the skeleton
					var body = parts.filter(p -> p.boneCount > 0 && p.meshCount > 0)[0];
					model = LoadModelFromModels(parts, body);
					for (a in anims) {
						if (a.name == "CharacterArmature|Run") run = a;
						if (a.name == "CharacterArmature|Sword_Slash") slash = a;
					}
					mask = GetModelBoneMask(model, "Abdomen");
					var nm = [for (i in 0...run.boneCount) run.bones[i].name];
					trace(nm.join(",") + " dur=" + slash.frameCount + " run=" + run.frameCount + " masked=" + mask.filter(w -> w > 0).length);
					slashDur = (slash.frameCount - 1) / FPS_ANIM;
				}
				BeginDrawing();
				ClearBackground(RAYWHITE);
				DrawText("Loading...", 10, 10, 20, DARKGRAY);
				EndDrawing();
				continue;
			}
			var dt = GetFrameTime();
			if (maxFrames >= 0 && frame >= maxFrames) break;
			// fixed step when scripted, so screenshots are reproducible
			if (maxFrames >= 0) dt = 1.0 / 60.0;

			if (auto) {
				autoTimer += dt;
				if (autoTimer >= 2.0) { autoTimer -= 2.0; if (!slashing) { slashing = true; slashT = 0; } }
			}
			if (IsKeyPressed(KEY_SPACE) && !slashing) { slashing = true; slashT = 0; }

			runT += dt * FPS_ANIM;
			var blend = 0.0;
			if (slashing) {
				slashT += dt;
				if (slashT >= slashDur) slashing = false;
				else blend = Math.min(1.0, Math.min(slashT / EASE, (slashDur - slashT) / EASE));
			}
			var slashFrame = Math.min(slashT * FPS_ANIM, slash.frameCount - 1.0);
			UpdateModelAnimationMasked(model, run, runT, slash, slashFrame, mask, blend);

			BeginDrawing();
			ClearBackground(RAYWHITE);
			BeginMode3D(camera);
			DrawGrid(10, 1.0);
			DrawModel(model, new Vector3(0, 0, 0), 1.0, WHITE);
			EndMode3D();
			var txt = slashing ? "Slash: playing " + Std.int(100 * slashT / slashDur) + "%" : "Slash: idle";
			DrawText(txt, 10, 10, 20, DARKGRAY);
			EndDrawing();

			frame++;
			// before slash, mid-slash, easing out
			// frame 30 is before the first (auto) slash at 2 s; then mid-slash and easing out
			if (maxFrames >= 0 && (frame == 30 || (slashing && slashT >= slashDur / 2 && shots == 0) || (slashing && slashT >= slashDur - EASE / 2 && shots == 1))) {
				if (frame != 30) shots++;
				TakeScreenshotAsync('shot_$frame.png');
			}
		}
		CloseWindow();
	}
}
