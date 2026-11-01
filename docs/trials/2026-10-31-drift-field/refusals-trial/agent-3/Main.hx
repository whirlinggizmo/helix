import helix.ray.*;
import helix.ray.Raylib.*;

typedef Level = {
	seed:Int,
	width:Float,
	height:Float,
	rocks:Int,
	crystals:Int,
	seconds:Float,
	target:Int
}

enum Mode {
	Boot;
	Title;
	Loading;
	Play;
}

class Main {
	static inline var SPEED = 300.0;
	static inline var CR = 8.0;
	static inline var BEST_FILE = "best.txt";

	static var mode:Mode = Boot;
	static var pendingBoot = 3;
	static var score = 0;
	static var best = 0;
	static var levelNo = 1;
	static var custom = false;
	static var level:Level;
	static var rocks:Array<Rectangle> = [];
	static var crystals:Array<Vector2> = [];
	static var gathered = 0;
	static var timeLeft = 0.0;
	static var shipX = 0.0;
	static var shipY = 0.0;
	static var hasTarget = false;
	static var tx = 0.0;
	static var ty = 0.0;
	static var zoom = 1.0;
	static var turn = 0.0;
	static var message = "";
	static var messageTime = 0.0;
	static var loadToken = 0;
	static var tex:Texture2D;
	static var coin:Sound;
	static var rng = 1;
	static var cam:Camera2D;

	static function rand():Float {
		var x = rng;
		x ^= x << 13;
		x ^= x >>> 17;
		x ^= x << 5;
		rng = x;
		return (x & 0xFFFFFF) / 16777216.0;
	}

	static function randRange(a:Float, b:Float):Float {
		return a + rand() * (b - a);
	}

	static function parseNum(s:String):Null<Float> {
		var t = StringTools.trim(s);
		if (!~/^-?[0-9]+(\.[0-9]+)?$/.match(t))
			return null;
		var f = Std.parseFloat(t);
		return Math.isNaN(f) ? null : f;
	}

	static function parseLevel(text:String):Null<Level> {
		var vals = new Map<String, Float>();
		for (line in text.split("\n")) {
			var i = line.indexOf("=");
			if (i < 0)
				continue;
			var k = StringTools.trim(line.substr(0, i));
			var v = parseNum(line.substr(i + 1));
			if (v != null)
				vals.set(k, v);
		}
		for (k in ["seed", "width", "height", "rocks", "crystals", "seconds", "target"])
			if (!vals.exists(k))
				return null;
		if (vals.get("width") < 1 || vals.get("height") < 1)
			return null;
		return {
			seed: Std.int(vals.get("seed") % 2147483647.0),
			width: vals.get("width"),
			height: vals.get("height"),
			rocks: Std.int(Math.max(0, Math.min(5000, vals.get("rocks")))),
			crystals: Std.int(Math.max(0, Math.min(5000, vals.get("crystals")))),
			seconds: vals.get("seconds"),
			target: Std.int(vals.get("target"))
		};
	}

	static function shipHW():Float {
		return tex.width / 2;
	}

	static function shipHH():Float {
		return tex.height / 2;
	}

	static function hitsRock(x:Float, y:Float):Bool {
		var hw = shipHW(), hh = shipHH();
		for (r in rocks)
			if (x + hw > r.x && x - hw < r.x + r.width && y + hh > r.y && y - hh < r.y + r.height)
				return true;
		return false;
	}

	static function buildField() {
		rng = level.seed;
		if (rng == 0)
			rng = 1;
		for (i in 0...8)
			rand();
		rocks = [];
		crystals = [];
		for (i in 0...level.rocks) {
			var w = randRange(40, 160), h = randRange(40, 160);
			var x = randRange(0, Math.max(0, level.width - w));
			var y = randRange(0, Math.max(0, level.height - h));
			rocks.push(new Rectangle(x, y, w, h));
		}
		for (i in 0...level.crystals) {
			for (attempt in 0...100) {
				var x = randRange(CR, Math.max(CR, level.width - CR));
				var y = randRange(CR, Math.max(CR, level.height - CR));
				var ok = true;
				for (r in rocks)
					if (x > r.x - CR - 4 && x < r.x + r.width + CR + 4 && y > r.y - CR - 4 && y < r.y + r.height + CR + 4) {
						ok = false;
						break;
					}
				if (ok) {
					crystals.push(new Vector2(x, y));
					break;
				}
			}
		}
		shipX = level.width / 2;
		shipY = level.height / 2;
		if (hitsRock(shipX, shipY)) {
			var found = false;
			var rad = 10.0;
			while (!found && rad < level.width + level.height) {
				for (k in 0...24) {
					var a = k * Math.PI * 2 / 24;
					var px = level.width / 2 + Math.cos(a) * rad;
					var py = level.height / 2 + Math.sin(a) * rad;
					if (px >= shipHW() && px <= level.width - shipHW() && py >= shipHH() && py <= level.height - shipHH() && !hitsRock(px, py)) {
						shipX = px;
						shipY = py;
						found = true;
						break;
					}
				}
				rad += 10;
			}
		}
		gathered = 0;
		timeLeft = level.seconds;
		hasTarget = false;
		zoom = 1;
		turn = 0;
		mode = Play;
	}

	static function bootDone() {
		pendingBoot--;
		if (pendingBoot <= 0 && mode == Boot)
			mode = Title;
	}

	static function setMessage(m:String, t:Float) {
		message = m;
		messageTime = t;
	}

	static function toTitle() {
		mode = Title;
		loadToken++;
	}

	static function startLevel(n:Int) {
		levelNo = n;
		custom = false;
		mode = Loading;
		var token = ++loadToken;
		LoadFileTextAsync("assets/levels/level" + n + ".txt", function(text:String) {
			if (token != loadToken)
				return;
			var l = parseLevel(text);
			if (l == null) {
				finishWin();
				return;
			}
			level = l;
			buildField();
		}, function(err:String) {
			if (token != loadToken)
				return;
			finishWin();
		});
	}

	static function finishWin() {
		setMessage("You win! Score: " + score, 3.0);
		toTitle();
	}

	static function playDropped(path:String) {
		var name = GetFileName(path);
		var token = ++loadToken;
		var prev = mode;
		LoadFileTextAsync(path, function(text:String) {
			if (token != loadToken)
				return;
			var l = parseLevel(text);
			if (l == null) {
				notLevel(name, prev);
				return;
			}
			if (prev == Title || prev == Loading)
				score = 0;
			custom = true;
			level = l;
			buildField();
		}, function(err:String) {
			if (token != loadToken)
				return;
			notLevel(name, prev);
		});
	}

	static function notLevel(name:String, prev:Mode) {
		// leave the game as it was
		if (prev == Play) {
			mode = Play;
			return;
		}
		mode = Title;
		setMessage("Not a level: " + name, 3.0);
	}

	static function saveBest() {
		if (score > best) {
			best = score;
			SaveFileText(BEST_FILE, Std.string(best));
		}
	}

	static function anyStart():Bool {
		var any = false;
		while (GetKeyPressed() != 0)
			any = true;
		if (any)
			return true;
		if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT) || IsMouseButtonPressed(MOUSE_BUTTON_RIGHT))
			return true;
		if (IsGamepadAvailable(0))
			for (b in 1...18)
				if (IsGamepadButtonPressed(0, b))
					return true;
		return false;
	}

	static function moveShip(dx:Float, dy:Float):Float {
		var moved = 0.0;
		var hw = shipHW(), hh = shipHH();
		var steps = Std.int(Math.ceil(Math.max(Math.abs(dx), Math.abs(dy)) / 4));
		if (steps < 1)
			return 0;
		var sx = dx / steps, sy = dy / steps;
		for (i in 0...steps) {
			var ox = shipX, oy = shipY;
			var nx = Math.max(hw, Math.min(level.width - hw, shipX + sx));
			if (!hitsRock(nx, shipY))
				shipX = nx;
			var ny = Math.max(hh, Math.min(level.height - hh, shipY + sy));
			if (!hitsRock(shipX, ny))
				shipY = ny;
			moved += Math.abs(shipX - ox) + Math.abs(shipY - oy);
		}
		return moved;
	}

	static function updatePlay(dt:Float) {
		while (GetKeyPressed() != 0) {}
		if (IsKeyPressed(KEY_ESCAPE)) {
			toTitle();
			return;
		}
		// view
		var wheel = GetMouseWheelMove();
		if (wheel != 0)
			zoom = Math.max(0.5, Math.min(2, zoom * Math.pow(1.1, wheel)));
		if (IsKeyDown(KEY_Q))
			turn -= 90 * dt;
		if (IsKeyDown(KEY_E))
			turn += 90 * dt;
		if (IsKeyPressed(KEY_R)) {
			zoom = 1;
			turn = 0;
		}
		cam.offset = new Vector2(GetScreenWidth() / 2, GetScreenHeight() / 2);
		cam.target = new Vector2(shipX, shipY);
		cam.rotation = turn;
		cam.zoom = zoom;

		// input
		var ix = 0.0, iy = 0.0;
		if (IsKeyDown(KEY_LEFT) || IsKeyDown(KEY_A))
			ix -= 1;
		if (IsKeyDown(KEY_RIGHT) || IsKeyDown(KEY_D))
			ix += 1;
		if (IsKeyDown(KEY_UP) || IsKeyDown(KEY_W))
			iy -= 1;
		if (IsKeyDown(KEY_DOWN) || IsKeyDown(KEY_S))
			iy += 1;
		if (IsGamepadAvailable(0)) {
			var gx = GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_X);
			var gy = GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_Y);
			if (Math.sqrt(gx * gx + gy * gy) > 0.25) {
				ix += gx;
				iy += gy;
			}
		}
		if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT)) {
			var p = GetScreenToWorld2D(new Vector2(GetMouseX(), GetMouseY()), cam);
			if (p.x == p.x && p.y == p.y) {
				hasTarget = true;
				tx = Math.max(0, Math.min(level.width, p.x));
				ty = Math.max(0, Math.min(level.height, p.y));
			}
		}
		var len = Math.sqrt(ix * ix + iy * iy);
		if (len > 0.001) {
			hasTarget = false;
			if (len > 1) {
				ix /= len;
				iy /= len;
			}
			moveShip(ix * SPEED * dt, iy * SPEED * dt);
		} else if (hasTarget) {
			var ddx = tx - shipX, ddy = ty - shipY;
			var d = Math.sqrt(ddx * ddx + ddy * ddy);
			var step = SPEED * dt;
			if (d <= step) {
				var m = moveShip(ddx, ddy);
				hasTarget = false;
			} else {
				var m = moveShip(ddx / d * step, ddy / d * step);
				if (m < 0.01)
					hasTarget = false;
			}
		}

		// crystals
		var hw = shipHW(), hh = shipHH();
		var i = crystals.length;
		while (i-- > 0) {
			var c = crystals[i];
			var nx = Math.max(shipX - hw, Math.min(c.x, shipX + hw));
			var ny = Math.max(shipY - hh, Math.min(c.y, shipY + hh));
			var ddx = c.x - nx, ddy = c.y - ny;
			if (ddx * ddx + ddy * ddy <= CR * CR) {
				crystals.splice(i, 1);
				gathered++;
				score++;
				PlaySound(coin);
				saveBest();
			}
		}

		timeLeft -= dt;
		if (timeLeft <= 0 || (crystals.length == 0 && level.crystals > 0 && gathered > 0)) {
			if (custom) {
				setMessage("Time! Score: " + score, 3.0);
				toTitle();
			} else if (gathered >= level.target) {
				startLevel(levelNo + 1);
			} else {
				setMessage("Time! Score: " + score, 3.0);
				toTitle();
			}
		}
	}

	static function drawCentered(s:String, y:Int, size:Int, c:Color) {
		DrawText(s, Std.int((GetScreenWidth() - MeasureText(s, size)) / 2), y, size, c);
	}

	static function drawPlay() {
		var cyan = new Color(0, 255, 255, 255);
		BeginMode2D(cam);
		DrawRectangle(0, 0, Std.int(level.width), Std.int(level.height), DARKBLUE);
		for (r in rocks)
			DrawRectangleRec(r, GRAY);
		for (c in crystals)
			DrawCircleV(c, CR, cyan);
		if (hasTarget) {
			DrawLineEx(new Vector2(tx - 6, ty - 6), new Vector2(tx + 6, ty + 6), 2, WHITE);
			DrawLineEx(new Vector2(tx - 6, ty + 6), new Vector2(tx + 6, ty - 6), 2, WHITE);
		}
		DrawTexture(tex, Std.int(shipX - shipHW()), Std.int(shipY - shipHH()), WHITE);
		DrawRectangleLinesEx(new Rectangle(0, 0, level.width, level.height), 3, WHITE);
		EndMode2D();

		var sw = GetScreenWidth(), sh = GetScreenHeight();
		var lv = custom ? "Custom" : Std.string(levelNo);
		DrawText("Score: " + score + "  Level: " + lv + "  Crystals: " + gathered + "/" + level.target, 10, 10, 20, WHITE);
		var ts = "Time: " + Std.int(Math.ceil(Math.max(0, timeLeft)));
		DrawText(ts, sw - MeasureText(ts, 20) - 10, 10, 20, WHITE);

		// map
		var mx = sw - 200 - 10, my = sh - 120 - 10;
		DrawRectangle(mx, my, 200, 120, new Color(0, 0, 0, 255));
		BeginScissorMode(mx, my, 200, 120);
		var s = Math.min(200 / level.width, 120 / level.height);
		var ox = mx + (200 - level.width * s) / 2, oy = my + (120 - level.height * s) / 2;
		DrawRectangle(Std.int(ox), Std.int(oy), Std.int(level.width * s), Std.int(level.height * s), DARKBLUE);
		for (r in rocks)
			DrawRectangle(Std.int(ox + r.x * s), Std.int(oy + r.y * s), Std.int(Math.max(1, r.width * s)), Std.int(Math.max(1, r.height * s)), GRAY);
		for (c in crystals)
			DrawRectangle(Std.int(ox + c.x * s) - 1, Std.int(oy + c.y * s) - 1, 2, 2, cyan);
		DrawCircle(Std.int(ox + shipX * s), Std.int(oy + shipY * s), 3, WHITE);
		EndScissorMode();
		DrawRectangleLines(mx - 1, my - 1, 202, 122, WHITE);
	}

	static function main() {
		InitWindow(960, 540, "Drift Field");
		SetWindowState(FLAG_WINDOW_RESIZABLE);
		SetExitKey(KEY_NULL);
		InitAudioDevice();
		SetTargetFPS(60);
		cam = new Camera2D();
		cam.zoom = 1;
		LoadTextureAsync("assets/player.png", function(t:Texture2D) {
			tex = t;
			bootDone();
		}, function(e:String) {
			trace("player.png failed: " + e);
		});
		LoadSoundAsync("assets/coin.wav", function(s:Sound) {
			coin = s;
			bootDone();
		}, function(e:String) {
			trace("coin.wav failed: " + e);
			bootDone();
		});
		LoadFileTextAsync(BEST_FILE, function(b:String) {
			var n = parseNum(b);
			if (n != null)
				best = Std.int(n);
			bootDone();
		}, function(e:String) {
			bootDone();
		});
		level = {
			seed: 1,
			width: 100,
			height: 100,
			rocks: 0,
			crystals: 0,
			seconds: 1,
			target: 0
		};

		while (!WindowShouldClose()) {
			var dt = Math.min(GetFrameTime(), 0.25);
			var dropped = false;
			if (IsFileDropped() && mode != Boot) {
				var files = LoadDroppedFiles();
				var path = files.count > 0 ? files.paths[0] : null;
				UnloadDroppedFiles(files);
				if (path != null) {
					playDropped(path);
					dropped = true;
				}
			}
			if (messageTime > 0)
				messageTime -= dt;
			switch (mode) {
				case Title:
					if (!dropped && anyStart()) {
						score = 0;
						message = "";
						messageTime = 0;
						startLevel(1);
					}
				case Boot | Loading:
				case Play:
					if (!dropped)
						updatePlay(dt);
			}

			BeginDrawing();
			ClearBackground(BLACK);
			switch (mode) {
				case Play:
					drawPlay();
				case Boot:
					drawCentered("Loading...", Std.int(GetScreenHeight() / 2), 24, WHITE);
				case Title | Loading:
					var sh = GetScreenHeight();
					var cy = Std.int(sh / 2);
					drawCentered("Drift Field", cy - 90, 50, WHITE);
					drawCentered("Press any key, click or tap to start", cy - 20, 24, WHITE);
					drawCentered("Best: " + best, cy + 20, 24, WHITE);
					drawCentered("Drop a level file to play it", cy + 55, 20, GRAY);
					if (messageTime > 0)
						drawCentered(message, cy + 95, 24, YELLOW);
			}
			EndDrawing();
		}
		CloseWindow();
	}
}
