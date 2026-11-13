import helix.raylib.Raylib.*;
import helix.raylib.Raymath.*;
import helix.raylib.*;

class Main {
	static inline var FPS_ANIM:Float = 60.0; // glTF sampling rate in raylib 5.5 (frames/duration in its log)
	static inline var BLEND:Float = 0.15;

	static function smooth(x:Float):Float {
		x = x < 0 ? 0 : (x > 1 ? 1 : x);
		return x * x * (3 - 2 * x);
	}

	static function main() {
		var frames = -1;
		var auto = false;
		for (a in Sys.args()) {
			if (a == "--auto") auto = true;
			else if (StringTools.startsWith(a, "--frames=")) frames = Std.parseInt(a.substr(9));
		}

		InitWindow(1280, 720, "Slashing on the run");
		SetTargetFPS(60);

		var names = ["Head", "Body", "Legs", "Feet"];
		var models:Array<Model> = [];
		var anims:Array<ModelAnimation> = null;
		var scratch:Array<ModelAnimation> = null;
		var next:Int->Void = null;
		next = function(i:Int) {
			if (i == names.length) {
				LoadModelAnimationsAsync("assets/characters/Animations.glb", function(a) {
					anims = a;
					LoadModelAnimationsAsync("assets/characters/Animations.glb", function(b) scratch = b, function(e) trace("anim load failed " + e));
				}, function(e) trace("anim load failed " + e));
				return;
			}
			LoadModelAsync("assets/characters/Adventurer_" + names[i] + ".glb", function(m) {
				models.push(m);
				next(i + 1);
			}, function(e) trace("model load failed " + e));
		};
		next(0);
		while (scratch == null && !WindowShouldClose()) {
			BeginDrawing();
			ClearBackground(RAYWHITE);
			DrawText("Loading...", 10, 10, 24, DARKGRAY);
			EndDrawing();
		}
		var animCount = anims.length;
		var runIdx = -1, slashIdx = -1;
		for (i in 0...animCount) {
			var n = anims[i].name;
			if (n == "CharacterArmature|Run") runIdx = i;
			if (n == "CharacterArmature|Sword_Slash") slashIdx = i;
		}
		var run = anims[runIdx];
		var slash = anims[slashIdx];
		var out = scratch[runIdx];
		var bones = run.boneCount;

		// Upper-body mask: bones that descend from the first child of the hips other than the legs.
		var upper = [for (i in 0...bones) false];
		var parents = [for (i in 0...bones) run.bones[i].parent];
		var isLeg = function(n:String) {
			var l = n.toLowerCase();
			return l.indexOf("leg") >= 0 || l.indexOf("foot") >= 0 || l.indexOf("toe") >= 0 || l.indexOf("thigh") >= 0 || l.indexOf("calf") >= 0 || l.indexOf("shin") >= 0;
		};
		for (i in 0...bones) {
			var nm = run.bones[i].name;
		}
		for (i in 0...bones) {
			var nm:String = run.bones[i].name;
			var l = nm.toLowerCase();
			if (l.indexOf("abdomen") >= 0 || l.indexOf("torso") >= 0 || l.indexOf("spine") >= 0 || l.indexOf("chest") >= 0) upper[i] = true;
			else if (parents[i] >= 0 && upper[parents[i]] && !isLeg(nm)) upper[i] = true;
		}
		trace("run frames " + run.frameCount + " slash frames " + slash.frameCount);

		var cam = new Camera3D();
		cam.position = new Vector3(1.8, 1.4, 3.0);
		cam.target = new Vector3(0, 0.85, 0);
		cam.up = new Vector3(0, 1, 0);
		cam.fovy = 45;
		cam.projection = CAMERA_PERSPECTIVE;

		var runTime = 0.0;
		var slashing = false;
		var slashTime = 0.0;
		var slashDur = (slash.frameCount - 1) / FPS_ANIM;
		var autoTimer = 0.0;
		var frame = 0;
		var shotMid = false, shotOut = false;

		var sample = function(a:ModelAnimation, t:Float, b:Int):Transform {
			var f = t * FPS_ANIM;
			var n = a.frameCount - 1; // last frame repeats the first
			var i0 = Std.int(Math.floor(f));
			var k = f - i0;
			i0 = ((i0 % n) + n) % n;
			var i1 = (i0 + 1) % n;
			var p = a.framePoses[i0][b];
			var q = a.framePoses[i1][b];
			var r = new Transform();
			r.translation = Vector3Lerp(p.translation, q.translation, k);
			r.rotation = QuaternionSlerp(p.rotation, q.rotation, k);
			r.scale = Vector3Lerp(p.scale, q.scale, k);
			return r;
		};

		while (!WindowShouldClose()) {
			var dt = GetFrameTime();
			if (frames >= 0) dt = 1.0 / 60.0; // deterministic when capturing
			runTime += dt;
			if (auto) {
				autoTimer += dt;
				if (autoTimer >= 2.0) {
					autoTimer -= 2.0;
					if (!slashing) { slashing = true; slashTime = 0; }
				}
			}
			if (IsKeyPressed(KEY_SPACE) && !slashing) { slashing = true; slashTime = 0; }
			if (slashing) {
				slashTime += dt;
				if (slashTime >= slashDur) { slashing = false; slashTime = 0; }
			}
			var w = 0.0;
			if (slashing) w = smooth(Math.min(slashTime / BLEND, (slashDur - slashTime) / BLEND));

			// Blend in local space, then rebuild model-space poses (framePoses are model-space).
			var g:Array<Transform> = [];
			var runG:Array<Transform> = [];
			var slG:Array<Transform> = [];
			for (b in 0...bones) {
				runG.push(sample(run, runTime, b));
				slG.push(slashing ? sample(slash, slashTime, b) : runG[b]);
			}
			var toLocal = function(arr:Array<Transform>, b:Int):Transform {
				var p = parents[b];
				var c = arr[b];
				var r = new Transform();
				if (p < 0) { r.translation = c.translation; r.rotation = c.rotation; r.scale = c.scale; return r; }
				var pg = arr[p];
				var inv = QuaternionInvert(pg.rotation);
				var d = Vector3Subtract(c.translation, pg.translation);
				d = Vector3RotateByQuaternion(d, inv);
				r.translation = new Vector3(d.x / pg.scale.x, d.y / pg.scale.y, d.z / pg.scale.z);
				r.rotation = QuaternionMultiply(inv, c.rotation);
				r.scale = new Vector3(c.scale.x / pg.scale.x, c.scale.y / pg.scale.y, c.scale.z / pg.scale.z);
				return r;
			};
			for (b in 0...bones) {
				var lr = toLocal(runG, b);
				var l = lr;
				if (slashing && upper[b]) {
					var ls = toLocal(slG, b);
					l = new Transform();
					l.translation = Vector3Lerp(lr.translation, ls.translation, w);
					l.rotation = QuaternionSlerp(lr.rotation, ls.rotation, w);
					l.scale = Vector3Lerp(lr.scale, ls.scale, w);
				}
				var p = parents[b];
				var r = new Transform();
				if (p < 0) { r = l; }
				else {
					var pg = g[p];
					var t = Vector3RotateByQuaternion(new Vector3(l.translation.x * pg.scale.x, l.translation.y * pg.scale.y, l.translation.z * pg.scale.z), pg.rotation);
					r.translation = Vector3Add(pg.translation, t);
					r.rotation = QuaternionMultiply(pg.rotation, l.rotation);
					r.scale = new Vector3(pg.scale.x * l.scale.x, pg.scale.y * l.scale.y, pg.scale.z * l.scale.z);
				}
				g.push(r);
				out.framePoses[0][b] = r;
			}
			for (m in models) UpdateModelAnimation(m, out, 0);

			BeginDrawing();
			ClearBackground(RAYWHITE);
			BeginMode3D(cam);
			for (m in models) DrawModel(m, new Vector3(0, 0, 0), 1.0, WHITE);
			DrawGrid(10, 1.0);
			EndMode3D();
			var txt = slashing ? "Slash: playing " + Std.int(slashTime / slashDur * 100) + "%" : "Slash: not playing (0%)";
			DrawText(txt, 10, 10, 24, DARKGRAY);
			DrawText("Space: slash", 10, 40, 16, GRAY);
			EndDrawing();

			if (frames >= 0) {
				if (frame == 60) TakeScreenshotAsync("shot_before.png");
				if (slashing && !shotMid && slashTime >= slashDur / 2) { shotMid = true; TakeScreenshotAsync("shot_mid.png"); }
				if (slashing && !shotOut && slashTime >= slashDur - BLEND / 2) { shotOut = true; TakeScreenshotAsync("shot_out.png"); }
			}
			frame++;
			if (frames >= 0 && frame >= frames) break;
		}
		CloseWindow();
	}
}
