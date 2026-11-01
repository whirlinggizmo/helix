import helix.ray.*;
import helix.ray.Raylib;
import helix.ray.Raylib.*;

typedef Rock = {x:Float, y:Float, w:Float, h:Float};
typedef Crystal = {x:Float, y:Float, got:Bool};

class Main {
	static inline var SPEED = 300.0;
	static inline var CR = 8.0;

	static var title = true;
	static var level = 0; // 0 = custom
	static var custom = false;
	static var score = 0;
	static var best = 0;
	static var gathered = 0;
	static var target = 0;
	static var timeLeft = 0.0;
	static var fw = 0.0;
	static var fh = 0.0;
	static var rocks:Array<Rock> = [];
	static var crystals:Array<Crystal> = [];
	static var px = 0.0;
	static var py = 0.0;
	static var hasTarget = false;
	static var tx = 0.0;
	static var ty = 0.0;
	static var zoom = 1.0;
	static var turn = 0.0;
	static var msg = "";
	static var msgTime = 0.0;
	static var banner = "";
	static var player:Texture;
	static var coin:Sound;
	static var rngState = 1;

	static function rnd():Float {
		// small deterministic LCG (31 bit), same on every target
		rngState = (rngState * 1103515245 + 12345) & 0x7fffffff;
		return ((rngState >> 8) & 0xffffff) / 16777216.0;
	}

	static function parseLevel(text:String):Map<String, Float> {
		if (text == null)
			return null;
		var m = new Map<String, Float>();
		for (line in text.split("\n")) {
			var l = StringTools.trim(line);
			var i = l.indexOf("=");
			if (i < 0)
				continue;
			m.set(StringTools.trim(l.substr(0, i)), Std.parseFloat(StringTools.trim(l.substr(i + 1))));
		}
		for (k in ["seed", "width", "height", "rocks", "crystals", "seconds", "target"]) {
			if (!m.exists(k) || Math.isNaN(m.get(k)))
				return null;
		}
		return m;
	}

	static function overlapsRock(x:Float, y:Float, hw:Float, hh:Float):Bool {
		for (r in rocks)
			if (x + hw > r.x && x - hw < r.x + r.w && y + hh > r.y && y - hh < r.y + r.h)
				return true;
		return false;
	}

	static function startLevel(m:Map<String, Float>) {
		rngState = Std.int(m.get("seed")) & 0x7fffffff;
		for (i in 0...5)
			rnd();
		fw = m.get("width");
		fh = m.get("height");
		target = Std.int(m.get("target"));
		timeLeft = m.get("seconds");
		gathered = 0;
		rocks = [];
		crystals = [];
		for (i in 0...Std.int(m.get("rocks"))) {
			var w = 40 + rnd() * 120;
			var h = 40 + rnd() * 120;
			rocks.push({x: rnd() * Math.max(1, fw - w), y: rnd() * Math.max(1, fh - h), w: w, h: h});
		}
		var n = Std.int(m.get("crystals"));
		var tries = 0;
		while (crystals.length < n && tries < n * 200) {
			tries++;
			var x = CR + rnd() * (fw - 2 * CR);
			var y = CR + rnd() * (fh - 2 * CR);
			if (!overlapsRock(x, y, CR + 2, CR + 2))
				crystals.push({x: x, y: y, got: false});
		}
		// ship at center, moved off rocks
		px = fw / 2;
		py = fh / 2;
		var hw = player.width / 2;
		var hh = player.height / 2;
		var step = 8.0;
		var found = !overlapsRock(px, py, hw, hh);
		var radius = step;
		while (!found && radius < Math.max(fw, fh)) {
			var k = 0;
			while (k < 16 && !found) {
				var a = k / 16 * 6.283185307;
				var cx = fw / 2 + Math.cos(a) * radius;
				var cy = fh / 2 + Math.sin(a) * radius;
				if (cx > hw && cx < fw - hw && cy > hh && cy < fh - hh && !overlapsRock(cx, cy, hw, hh)) {
					px = cx;
					py = cy;
					found = true;
				}
				k++;
			}
			radius += step;
		}
		hasTarget = false;
		zoom = 1;
		turn = 0;
		title = false;
	}

	static var loading = false;
	static var ready = 0;

	// Loads level n's file; then calls done(parsed or null). Frames go on meanwhile.
	static function loadLevelFile(n:Int, done:Map<String, Float>->Void) {
		loading = true;
		LoadFileTextAsync("assets/levels/level" + n + ".txt", function(text) {
			loading = false;
			done(parseLevel(text));
		}, function(err) {
			loading = false;
			done(null);
		});
	}

	static function endToTitle(text:String) {
		banner = text;
		title = true;
	}

	static function finishLevel() {
		if (custom || gathered < target) {
			endToTitle("Time! Score: " + score);
			return;
		}
		level++;
		loadLevelFile(level, function(m) {
			if (m == null) {
				endToTitle("You win! Score: " + score);
				return;
			}
			startLevel(m);
		});
	}

	static function saveBest() {
		if (score > best) {
			best = score;
			SaveFileText("best.txt", Std.string(best));
		}
	}

	static function move(dx:Float, dy:Float) {
		var hw = player.width / 2;
		var hh = player.height / 2;
		var nx = px + dx;
		nx = Math.max(hw, Math.min(fw - hw, nx));
		if (!overlapsRock(nx, py, hw, hh))
			px = nx;
		var ny = py + dy;
		ny = Math.max(hh, Math.min(fh - hh, ny));
		if (!overlapsRock(px, ny, hw, hh))
			py = ny;
	}

	static function update(dt:Float) {
		var ix = 0.0;
		var iy = 0.0;
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
		// view controls
		var wheel = GetMouseWheelMove();
		if (wheel != 0)
			zoom = Math.max(0.5, Math.min(2, zoom + wheel * 0.1));
		if (IsKeyDown(KEY_Q))
			turn -= 90 * dt;
		if (IsKeyDown(KEY_E))
			turn += 90 * dt;
		if (IsKeyPressed(KEY_R)) {
			zoom = 1;
			turn = 0;
		}
		var sw = GetScreenWidth();
		var sh = GetScreenHeight();
		var cam = new Camera2D(new Vector2(sw / 2, sh / 2), new Vector2(px, py), turn, zoom);
		if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT)) {
			var wp = GetScreenToWorld2D(GetMousePosition(), cam);
			tx = Math.max(0, Math.min(fw, wp.x));
			ty = Math.max(0, Math.min(fh, wp.y));
			hasTarget = true;
		}
		var len = Math.sqrt(ix * ix + iy * iy);
		if (len > 0.001) {
			hasTarget = false;
			if (len > 1) {
				ix /= len;
				iy /= len;
			}
			move(ix * SPEED * dt, iy * SPEED * dt);
		} else if (hasTarget) {
			var dx = tx - px;
			var dy = ty - py;
			var d = Math.sqrt(dx * dx + dy * dy);
			var s = SPEED * dt;
			if (d <= s) {
				var ox = px;
				var oy = py;
				move(dx, dy);
				hasTarget = false;
				if (Math.abs(px - ox) < 0.0001 && Math.abs(py - oy) < 0.0001) {}
			} else {
				var ox = px;
				var oy = py;
				move(dx / d * s, dy / d * s);
				// blocked completely: give up
				if (Math.abs(px - ox) < 0.0001 && Math.abs(py - oy) < 0.0001)
					hasTarget = false;
			}
		}
		// crystals
		var hw = player.width / 2;
		var hh = player.height / 2;
		var remaining = 0;
		for (c in crystals) {
			if (c.got)
				continue;
			var cx = Math.max(px - hw, Math.min(c.x, px + hw));
			var cy = Math.max(py - hh, Math.min(c.y, py + hh));
			var ddx = c.x - cx;
			var ddy = c.y - cy;
			if (ddx * ddx + ddy * ddy <= CR * CR) {
				c.got = true;
				gathered++;
				score++;
				PlaySound(coin);
			} else
				remaining++;
		}
		timeLeft -= dt;
		if (timeLeft <= 0 || remaining == 0) {
			saveBest();
			finishLevel();
		}
	}

	static function drawWorld() {
		var sw = GetScreenWidth();
		var sh = GetScreenHeight();
		var cam = new Camera2D(new Vector2(sw / 2, sh / 2), new Vector2(px, py), turn, zoom);
		BeginMode2D(cam);
		DrawRectangle(0, 0, Std.int(fw), Std.int(fh), new Color(10, 20, 60, 255));
		for (r in rocks)
			DrawRectangle(Std.int(r.x), Std.int(r.y), Std.int(r.w), Std.int(r.h), GRAY);
		for (c in crystals)
			if (!c.got)
				DrawCircle(Std.int(c.x), Std.int(c.y), CR, SKYBLUE);
		DrawRectangleLines(0, 0, Std.int(fw), Std.int(fh), WHITE);
		if (hasTarget) {
			DrawLine(Std.int(tx - 6), Std.int(ty), Std.int(tx + 6), Std.int(ty), YELLOW);
			DrawLine(Std.int(tx), Std.int(ty - 6), Std.int(tx), Std.int(ty + 6), YELLOW);
		}
		DrawTexture(player, Std.int(px - player.width / 2), Std.int(py - player.height / 2), WHITE);
		EndMode2D();
	}

	static function drawMap() {
		var sw = GetScreenWidth();
		var sh = GetScreenHeight();
		var mw = 200;
		var mh = 120;
		var mx = sw - mw - 10;
		var my = sh - mh - 10;
		DrawRectangle(mx, my, mw, mh, new Color(0, 0, 0, 255));
		var s = Math.min(mw / fw, mh / fh);
		var ox = mx + (mw - fw * s) / 2;
		var oy = my + (mh - fh * s) / 2;
		BeginScissorMode(mx, my, mw, mh);
		DrawRectangle(Std.int(ox), Std.int(oy), Std.int(fw * s), Std.int(fh * s), new Color(10, 20, 60, 255));
		for (r in rocks)
			DrawRectangle(Std.int(ox + r.x * s), Std.int(oy + r.y * s), Std.int(Math.max(1, r.w * s)), Std.int(Math.max(1, r.h * s)), GRAY);
		for (c in crystals)
			if (!c.got)
				DrawRectangle(Std.int(ox + c.x * s), Std.int(oy + c.y * s), 2, 2, SKYBLUE);
		DrawCircle(Std.int(ox + px * s), Std.int(oy + py * s), 3, RED);
		EndScissorMode();
		DrawRectangleLines(mx, my, mw, mh, WHITE);
	}

	static function centered(text:String, y:Int, size:Int, c:Color) {
		DrawText(text, Std.int((GetScreenWidth() - MeasureText(text, size)) / 2), y, size, c);
	}

	static function drawHud() {
		var sw = GetScreenWidth();
		var lv = custom ? "Custom" : Std.string(level);
		DrawText("Score: " + score, 10, 10, 20, WHITE);
		DrawText("Level: " + lv, 10, 34, 20, WHITE);
		DrawText("Crystals: " + gathered + " / " + target, 10, 58, 20, WHITE);
		var t = "Time: " + Std.int(Math.ceil(Math.max(0, timeLeft)));
		DrawText(t, sw - MeasureText(t, 20) - 10, 10, 20, WHITE);
	}

	static function drawTitle() {
		var sh = GetScreenHeight();
		var y = Std.int(sh / 2) - 100;
		centered("Drift Field", y, 48, WHITE);
		if (banner != "")
			centered(banner, y + 56, 24, YELLOW);
		centered("Press any key, click or tap to start", y + 96, 24, WHITE);
		centered("Best: " + best, y + 130, 24, WHITE);
		centered("Drop a level file to play it", y + 164, 20, GRAY);
		if (msgTime > 0)
			centered(msg, y + 200, 20, RED);
	}

	static function anyStart():Bool {
		if (GetKeyPressed() != 0)
			return true;
		if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT))
			return true;
		if (IsGamepadAvailable(0) && GetGamepadButtonPressed() != 0)
			return true;
		return false;
	}

	static function main() {
		SetConfigFlags(FLAG_WINDOW_RESIZABLE);
		InitWindow(960, 540, "Drift Field");
		InitAudioDevice();
		SetExitKey(KEY_NULL);
		SetTargetFPS(60);
		LoadTextureAsync("assets/player.png", function(t) {
			player = t;
			ready++;
		});
		LoadSoundAsync("assets/coin.wav", function(snd) {
			coin = snd;
			ready++;
		});
		LoadFileTextAsync("best.txt", function(saved) {
			var b = Std.parseInt(StringTools.trim(saved));
			if (b != null)
				best = b;
		}, function(err) {});
		while (!WindowShouldClose()) {
			var dt = GetFrameTime();
			if (dt > 0.1)
				dt = 0.1;
			if (msgTime > 0)
				msgTime -= dt;
			if (IsFileDropped()) {
				var files = LoadDroppedFiles();
				if (files.count > 0) {
					var path = files.paths[0];
					var name = GetFileName(path);
					LoadFileTextAsync(path, function(text) {
						var m = parseLevel(text);
						if (m == null) {
							msg = "Not a level: " + name;
							msgTime = 3;
						} else {
							custom = true;
							banner = "";
							startLevel(m);
						}
					}, function(err) {
						msg = "Not a level: " + name;
						msgTime = 3;
					});
				}
				UnloadDroppedFiles(files);
			}
			if (title) {
				if (ready >= 2 && !loading && anyStart()) {
					loadLevelFile(1, function(m) {
						if (m != null) {
							level = 1;
							custom = false;
							score = 0;
							banner = "";
							startLevel(m);
						}
					});
				}
			} else if (!loading) {
				if (IsKeyPressed(KEY_ESCAPE)) {
					saveBest();
					banner = "";
					title = true;
				} else
					update(dt);
			}
			BeginDrawing();
			ClearBackground(BLACK);
			if (title)
				drawTitle();
			else {
				drawWorld();
				drawMap();
				drawHud();
			}
			EndDrawing();
		}
		UnloadTexture(player);
		UnloadSound(coin);
		CloseAudioDevice();
		CloseWindow();
	}
}
