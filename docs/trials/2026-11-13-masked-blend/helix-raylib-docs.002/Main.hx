import helix.raylib.Raylib.*;
import helix.raylib.*;
import helix.raylib.extras.Models.*;

class Main {
	static inline var FPS = 60.0; // animations are 60 frames a second (raylib logs their durations)
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

		var names = ["Head", "Body", "Legs", "Feet"];
		var parts:Array<Model> = [];
		var loaded = 0;
		for (i in 0...4) {
			parts.push(null);
			LoadModelAsync('assets/characters/Adventurer_${names[i]}.glb', m -> { parts[i] = m; loaded++; }, e -> trace(e));
		}
		var anims:Array<ModelAnimation> = null;
		LoadModelAnimationsAsync("assets/characters/Animations.glb", l -> anims = l, e -> trace(e));
		while (loaded < 4 || anims == null) {
			if (WindowShouldClose()) return;
			BeginDrawing();
			ClearBackground(RAYWHITE);
			DrawText("Loading...", 10, 10, 24, DARKGRAY);
			EndDrawing();
		}
		var model = LoadModelFromModels(parts, parts[1]);
		var run:ModelAnimation = null;
		var slash:ModelAnimation = null;
		for (a in anims) {
			if (a.name == "CharacterArmature|Run") run = a;
			else if (a.name == "CharacterArmature|Sword_Slash") slash = a;
		}
		var mask = GetModelBoneMask(model, "Abdomen");

		var cam = new Camera3D();
		cam.position = new Vector3(2.5, 1.6, 4.0);
		cam.target = new Vector3(0, 1.0, 0);
		cam.up = new Vector3(0, 1, 0);
		cam.fovy = 45;
		cam.projection = CAMERA_PERSPECTIVE;

		var runT = 0.0;
		var slashT = 0.0;
		var slashing = false;
		var slashLen = slash.frameCount / FPS;
		var nextAuto = 2.0;
		var clock = 0.0;
		var frame = 0;
		while (!WindowShouldClose()) {
			var dt = GetFrameTime();
			if (maxFrames >= 0) dt = 1 / 60;
			clock += dt;
			runT += dt;
			var trigger = IsKeyPressed(KEY_SPACE);
			if (auto && clock >= nextAuto) {
				nextAuto += 2.0;
				trigger = true;
			}
			if (trigger && !slashing) {
				slashing = true;
				slashT = 0;
			}
			var w = 0.0;
			if (slashing) {
				slashT += dt;
				if (slashT >= slashLen) slashing = false;
				else {
					var up = Math.min(1, slashT / EASE);
					var down = Math.min(1, (slashLen - slashT) / EASE);
					var m = Math.min(up, down);
					w = m * m * (3 - 2 * m);
				}
			}
			var fr = (runT * FPS) % run.frameCount;
			var fs = Math.min(slashT * FPS, slash.frameCount - 1);
			UpdateModelAnimationMasked(model, run, fr, slash, fs, mask, w);

			BeginDrawing();
			ClearBackground(RAYWHITE);
			BeginMode3D(cam);
			DrawModel(model, new Vector3(0, 0, 0), 1.0, WHITE);
			DrawGrid(10, 1.0);
			EndMode3D();
			var txt = slashing ? 'Slash: playing ${Std.int(slashT / slashLen * 100)}%' : "Slash: idle";
			DrawText(txt, 10, 10, 24, DARKGRAY);
			EndDrawing();

			frame++;
			if (maxFrames >= 0) {
				// before a slash, mid-slash, easing out (auto: slashes start at 2s = frame 120)
				var out = 120 + Std.int((slashLen - EASE * 0.5) * 60);
				if (frame == 60 || frame == 120 + Std.int(slashLen * 30) || frame == out)
					TakeScreenshotAsync('shot_$frame.png');
				if (frame >= maxFrames) break;
			}
		}
		CloseWindow();
	}
}
