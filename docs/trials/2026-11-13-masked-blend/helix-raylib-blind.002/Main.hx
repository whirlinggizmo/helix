import helix.raylib.Raylib.*;
import helix.raylib.Raymath.*;
import helix.raylib.*;

class Main {
	static inline var FPS = 60.0;
	static inline var BLEND = 0.15;
	static inline var UPPER_ROOT = 3; // Abdomen: everything below it in the skeleton is waist-up

	static function smooth(x:Float):Float {
		var t = x < 0 ? 0 : (x > 1 ? 1 : x);
		return t * t * (3 - 2 * t);
	}

	static function main() {
		var maxFrames = -1;
		var auto = false;
		for (a in Sys.args()) {
			if (a == "--auto") auto = true;
			else if (StringTools.startsWith(a, "--frames=")) maxFrames = Std.parseInt(a.substr(9));
		}
		InitWindow(1280, 720, "Slashing on the run");
		SetTargetFPS(60);

		var models:Array<Model> = [];
		var anims:Array<ModelAnimation> = null;
		for (n in ["Head", "Body", "Legs", "Feet"])
			LoadModelAsync('assets/characters/Adventurer_$n.glb', m -> models.push(m), e -> trace(e));
		LoadModelAnimationsAsync("assets/characters/Animations.glb", a -> anims = a, e -> trace(e));
		while (!WindowShouldClose() && (anims == null || models.length < 4)) {
			BeginDrawing();
			ClearBackground(RAYWHITE);
			DrawText("Loading...", 20, 20, 20, DARKGRAY);
			EndDrawing();
		}
		if (anims == null) return;

		var run:ModelAnimation = null;
		var slash:ModelAnimation = null;
		var scratch:ModelAnimation = anims[0]; // carrier for the blended pose
		for (a in anims) {
			if (a.name == "CharacterArmature|Run") run = a;
			if (a.name == "CharacterArmature|Sword_Slash") slash = a;
		}
		var bc = run.boneCount;
		var upper = [for (b in 0...bc) false];
		for (b in 0...bc) {
			var p = b;
			while (p >= 0) {
				if (p == UPPER_ROOT) upper[b] = true;
				p = run.bones[p].parent;
			}
		}

		var camera = new Camera3D();
		camera.position = new Vector3(2.6, 1.6, 4.2);
		camera.target = new Vector3(0, 0.9, 0);
		camera.up = new Vector3(0, 1, 0);
		camera.fovy = 45;
		camera.projection = CAMERA_PERSPECTIVE;

		var dt = 1.0 / 60.0;
		var runTime = 0.0;
		var slashing = false;
		var slashTime = 0.0;
		var slashDur = (slash.frameCount - 1) / FPS;
		var sinceSlash = 0.0;
		var frame = 0;

		while (!WindowShouldClose()) {
			if (maxFrames >= 0 && frame >= maxFrames) break;
			runTime += dt;
			sinceSlash += dt;
			var trigger = IsKeyPressed(KEY_SPACE) || (auto && sinceSlash >= 2.0);
			if (trigger && !slashing) {
				slashing = true;
				slashTime = 0;
			}
			if (trigger) sinceSlash = 0;
			var w = 0.0;
			if (slashing) {
				slashTime += dt;
				if (slashTime >= slashDur) {
					slashing = false;
				} else {
					w = smooth(slashTime / BLEND) * smooth((slashDur - slashTime) / BLEND);
				}
			}

			var rf = Std.int(runTime * FPS) % (run.frameCount - 1);
			var sf = slashing ? Std.int(Math.min(slashTime * FPS, slash.frameCount - 1)) : 0;
			var out = scratch.framePoses[0];
			for (b in 0...bc) {
				var r = run.framePoses[rf][b];
				var o = out[b];
				if (upper[b] && w > 0) {
					var s = slash.framePoses[sf][b];
					o.translation = Vector3Lerp(r.translation, s.translation, w);
					o.rotation = QuaternionSlerp(r.rotation, s.rotation, w);
					o.scale = Vector3Lerp(r.scale, s.scale, w);
				} else {
					o.translation = r.translation;
					o.rotation = r.rotation;
					o.scale = r.scale;
				}
			}
			for (m in models) UpdateModelAnimation(m, scratch, 0);

			BeginDrawing();
			ClearBackground(RAYWHITE);
			BeginMode3D(camera);
			DrawGrid(10, 1.0);
			for (m in models) DrawModel(m, new Vector3(0, 0, 0), 1.0, WHITE);
			EndMode3D();
			var pct = slashing ? Std.int(slashTime / slashDur * 100) : 0;
			DrawText(slashing ? 'Slash: PLAYING  ${pct}%' : 'Slash: idle  (Space)', 20, 20, 24, BLACK);
			DrawText('blend ${Std.int(w * 100)}%', 20, 50, 20, DARKGRAY);
			EndDrawing();

			if (maxFrames >= 0) {
				if (frame == 90) TakeScreenshotAsync("shot_before.png");
				if (frame == 150) TakeScreenshotAsync("shot_mid.png");
				if (frame == 178) TakeScreenshotAsync("shot_out.png");
			}
			frame++;
		}
		CloseWindow();
	}
}
