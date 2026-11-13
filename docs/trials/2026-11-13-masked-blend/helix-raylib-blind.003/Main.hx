import helix.raylib.Raylib.*;
import helix.raylib.Raymath.*;
import helix.raylib.*;

class Main {
	static inline var EASE = 0.15;

	static function smooth(x:Float):Float {
		if (x < 0) x = 0;
		if (x > 1) x = 1;
		return x * x * (3 - 2 * x);
	}

	// pose of an animation at time t (seconds, looping or clamped) into out, lerping between frames
	static function sample(anim:ModelAnimation, t:Float, dur:Float, loop:Bool, b:Int):Transform {
		var n = anim.frameCount;
		var f = t / dur * (n - 1);
		if (loop) {
			f = f % n;
			if (f < 0) f += n;
		} else if (f > n - 1) f = n - 1;
		var i0 = Std.int(f);
		var i1 = loop ? (i0 + 1) % n : (i0 + 1 > n - 1 ? n - 1 : i0 + 1);
		var k = f - i0;
		var a = anim.framePoses[i0][b];
		var c = anim.framePoses[i1][b];
		var r = new Transform();
		r.translation = Vector3Lerp(a.translation, c.translation, k);
		r.rotation = QuaternionSlerp(a.rotation, c.rotation, k);
		r.scale = Vector3Lerp(a.scale, c.scale, k);
		return r;
	}

	static function main() {
		var frames = -1;
		var auto = false;
		var shots:Array<Int> = [];
		for (a in Sys.args()) {
			if (StringTools.startsWith(a, "--frames=")) frames = Std.parseInt(a.substr(9));
			else if (a == "--auto") auto = true;
			else if (StringTools.startsWith(a, "--shots=")) for (s in a.substr(8).split(",")) shots.push(Std.parseInt(s));
		}

		InitWindow(1280, 720, "slashing on the run");
		SetTargetFPS(60);

		var names = ["Head", "Body", "Legs", "Feet"];
		var models:Array<Model> = [];
		var anims:Array<ModelAnimation> = null;
		for (n in names) LoadModelAsync('assets/characters/Adventurer_$n.glb', function(m) models.push(m));
		LoadModelAnimationsAsync("assets/characters/Animations.glb", function(a) anims = a);
		while (!WindowShouldClose() && (models.length < 4 || anims == null)) {
			BeginDrawing();
			ClearBackground(RAYWHITE);
			DrawText("Loading...", 10, 10, 24, DARKGRAY);
			EndDrawing();
		}
		var count = anims.length;
		var run:ModelAnimation = null;
		var slash:ModelAnimation = null;
		for (i in 0...count) {
			var nm = anims[i].name;
			if (nm == "CharacterArmature|Run") run = anims[i];
			if (nm == "CharacterArmature|Sword_Slash") slash = anims[i];
		}
		var runDur = 0.8333333;
		var slashDur = 1.0666667;

		// which bones belong to the upper body: Abdomen and everything below it in the hierarchy
		var bc = run.boneCount;
		var upper = [for (i in 0...bc) false];
		for (i in 0...bc) {
			var j = i;
			while (j >= 0) {
				if (run.bones[j].name == "Abdomen") {
					upper[i] = true;
					break;
				}
				j = run.bones[j].parent;
			}
		}

		var cam = new Camera3D();
		cam.position = new Vector3(2.2, 1.8, 4.0);
		cam.target = new Vector3(0, 0.9, 0);
		cam.up = new Vector3(0, 1, 0);
		cam.fovy = 45;
		cam.projection = CAMERA_PERSPECTIVE;

		var runT = 0.0;
		var slashing = false;
		var slashT = 0.0;
		var autoTimer = 0.0;
		var frame = 0;

		while (!WindowShouldClose()) {
			var dt = GetFrameTime();
			if (frames >= 0) dt = 1 / 60;
			runT += dt;
			if (auto) {
				autoTimer += dt;
				if (autoTimer >= 2.0) {
					autoTimer -= 2.0;
					if (!slashing) { slashing = true; slashT = 0; }
				}
			}
			if (IsKeyPressed(KEY_SPACE) && !slashing) {
				slashing = true;
				slashT = 0;
			}
			if (slashing) {
				slashT += dt;
				if (slashT >= slashDur) slashing = false;
			}

			var w = 0.0;
			if (slashing) w = Math.min(smooth(slashT / EASE), smooth((slashDur - slashT) / EASE));

			for (b in 0...bc) {
				var r = sample(run, runT, runDur, true, b);
				if (upper[b] && w > 0) {
					var s = sample(slash, slashT, slashDur, false, b);
					r.translation = Vector3Lerp(r.translation, s.translation, w);
					r.rotation = QuaternionSlerp(r.rotation, s.rotation, w);
					r.scale = Vector3Lerp(r.scale, s.scale, w);
				}
				var dst = run.framePoses[0][b];
				dst.translation = r.translation;
				dst.rotation = r.rotation;
				dst.scale = r.scale;
				run.framePoses[0][b] = dst;
			}
			for (m in models) UpdateModelAnimation(m, run, 0);

			BeginDrawing();
			ClearBackground(RAYWHITE);
			BeginMode3D(cam);
			DrawGrid(10, 1.0);
			for (m in models) DrawModel(m, new Vector3(0, 0, 0), 1.0, WHITE);
			EndMode3D();
			var pct = slashing ? Std.int(slashT / slashDur * 100) : 0;
			DrawText(slashing ? 'Slash: PLAYING  ${pct}%' : "Slash: idle (running)", 10, 10, 24, DARKGRAY);
			DrawText("Space: slash", 10, 40, 16, GRAY);
			EndDrawing();

			frame++;
			if (shots.indexOf(frame) >= 0) TakeScreenshotAsync('shot_$frame.png');
			if (frames >= 0 && frame >= frames) break;
		}
		CloseWindow();
	}
}
