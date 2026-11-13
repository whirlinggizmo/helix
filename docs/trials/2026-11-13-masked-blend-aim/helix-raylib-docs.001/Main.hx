import helix.raylib.Raylib.*;
import helix.raylib.*;
import helix.raylib.extras.Models.*;

class Main {
	static function findAnim(anims:Array<ModelAnimation>, name:String):ModelAnimation {
		for (a in anims)
			if (a.name == name)
				return a;
		return null;
	}

	static function main() {
		var auto = false;
		var frames = -1;
		for (a in Sys.args()) {
			if (a == "--auto")
				auto = true;
			else if (StringTools.startsWith(a, "--frames="))
				frames = Std.parseInt(a.substr(9));
		}

		InitWindow(1280, 720, "Aiming on the run");
		SetTargetFPS(60);

		var names = ["Head", "Body", "Legs", "Feet"];
		var parts:Array<Model> = [];
		var loadedParts = 0;
		for (i in 0...names.length)
			LoadModelAsync('assets/characters/Adventurer_${names[i]}.glb', m -> {
				parts[i] = m;
				loadedParts++;
			});
		var anims:Array<ModelAnimation> = null;
		LoadModelAnimationsAsync("assets/characters/Animations.glb", a -> anims = a);
		while (loadedParts < names.length || anims == null) {
			BeginDrawing();
			ClearBackground(RAYWHITE);
			DrawText("Loading...", 20, 20, 30, BLACK);
			EndDrawing();
		}
		var model = LoadModelFromModels(parts, parts[1]);
		var run = findAnim(anims, "CharacterArmature|Run_Left");
		var aim = findAnim(anims, "CharacterArmature|Idle_Gun_Pointing");
		var mask = GetModelBoneMask(model, "Abdomen");
		var nonzero = 0;
		for (w in mask)
			if (w > 0)
				nonzero++;
		trace('bones ${model.boneCount} masked $nonzero run ${run.frameCount} aim ${aim.frameCount}');

		var cam = new Camera3D();
		cam.position = new Vector3(0, 1.2, 4.5);
		cam.target = new Vector3(0, 1.0, 0);
		cam.up = new Vector3(0, 1, 0);
		cam.fovy = 45;
		cam.projection = CAMERA_PERSPECTIVE;

		var aiming = false;
		var blend = 0.0;
		var t = 0.0; // seconds
		var sinceToggle = 0.0;
		var frame = 0;
		var shots = [];
		// screenshot plan (frame number -> file), with the aim-only pose last
		var n = 0;
		while (!WindowShouldClose()) {
			var dt = 1.0 / 60.0;
			if (IsKeyPressed(KEY_SPACE))
				aiming = !aiming;
			if (auto) {
				sinceToggle += dt;
				if (sinceToggle >= 2.0) {
					sinceToggle -= 2.0;
					aiming = !aiming;
				}
			}
			var target = aiming ? 1.0 : 0.0;
			var step = dt / 0.2;
			if (blend < target)
				blend = Math.min(target, blend + step);
			else if (blend > target)
				blend = Math.max(target, blend - step);
			t += dt;

			// the aim-only view: whole body in the aim animation
			var aimOnly = frames > 0 && n >= frames - 10 && frames >= 30;
			UpdateModelAnimationMasked(model, aimOnly ? aim : run, t * 30.0, aim, t * 30.0, mask, aimOnly ? 0.0 : smooth(blend), BLEND_ROTATION_MODEL);

			BeginDrawing();
			ClearBackground(RAYWHITE);
			BeginMode3D(cam);
			DrawModel(model, new Vector3(0, 0, 0), 1.0, WHITE);
			DrawGrid(10, 1.0);
			EndMode3D();
			DrawText((aiming ? "Aiming: YES" : "Aiming: NO") + (aimOnly ? " (aim pose alone)" : ""), 20, 20, 30, BLACK);
			EndDrawing();
			n++;
			if (frames > 0) {
				if (n == 30) TakeScreenshotAsync("shot_run.png");
				if (n == 150) TakeScreenshotAsync("shot_aim.png");
				if (n == frames - 1) TakeScreenshotAsync("shot_aimonly.png");
				if (n >= frames)
					break;
			}
		}
		CloseWindow();
	}

	static function smooth(x:Float):Float
		return x * x * (3 - 2 * x);
}
