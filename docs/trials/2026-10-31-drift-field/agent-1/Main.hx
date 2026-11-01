import helix.ray.Raylib.*;
import helix.ray.*;

/** A level's settings, read from a key=value file. */
class Level {
	public var seed:Int;
	public var width:Float;
	public var height:Float;
	public var rocks:Int;
	public var crystals:Int;
	public var seconds:Float;
	public var target:Int;

	public function new() {}

	/** Parses a level file; null when a key is missing or not a number. */
	public static function parse(text:String):Null<Level> {
		var values = new Map<String, Float>();
		for (raw in text.split("\n")) {
			var line = StringTools.trim(raw);
			if (line.length == 0 || line.charAt(0) == "#")
				continue;
			var eq = line.indexOf("=");
			if (eq < 0)
				continue;
			var key = StringTools.trim(line.substr(0, eq));
			var value = StringTools.trim(line.substr(eq + 1));
			var n = Std.parseFloat(value);
			if (Math.isNaN(n) || !~/^-?[0-9]+(\.[0-9]+)?$/.match(value))
				continue;
			values.set(key, n);
		}
		for (k in ["seed", "width", "height", "rocks", "crystals", "seconds", "target"])
			if (!values.exists(k))
				return null;
		var l = new Level();
		l.seed = Std.int(values.get("seed"));
		l.width = values.get("width");
		l.height = values.get("height");
		l.rocks = Std.int(values.get("rocks"));
		l.crystals = Std.int(values.get("crystals"));
		l.seconds = values.get("seconds");
		l.target = Std.int(values.get("target"));
		if (l.width <= 0 || l.height <= 0)
			return null;
		return l;
	}
}

enum State {
	Title;
	Loading;
	Playing;
	Message;
}

class Main {
	static inline var SPEED = 300.0;
	static inline var SHIP_HALF = 12.0;
	static inline var CRYSTAL_RADIUS = 8.0;
	static inline var MAP_W = 200;
	static inline var MAP_H = 120;
	static inline var BEST_FILE = "driftfield_best.txt";

	static var state:State = Title;
	static var playerTex:Null<Texture2D> = null;
	static var coinSound:Null<Sound> = null;

	static var best = 0;
	static var score = 0;
	static var levelNumber = 0; // 0 = custom
	static var level:Null<Level> = null;
	static var timeLeft = 0.0;
	static var gathered = 0;
	static var loadGeneration = 0;

	static var rocks:Array<Rectangle> = [];
	static var crystals:Array<Vector2> = [];
	static var ship = new Vector2(0, 0);
	static var hasTarget = false;
	static var moveTarget = new Vector2(0, 0);

	static var zoom = 1.0;
	static var turn = 0.0;
	static var camera = new Camera2D(new Vector2(0, 0), new Vector2(0, 0), 0, 1);

	static var messageText = "";
	static var messageTime = 0.0;
	static var noticeText = "";
	static var noticeTime = 0.0;

	static var fieldColor = new Color(16, 24, 64, 255);
	static var rockColor = new Color(130, 130, 130, 255);

	static function main() {
		SetConfigFlags(FLAG_WINDOW_RESIZABLE);
		InitWindow(960, 540, "Drift Field");
		InitAudioDevice();
		SetExitKey(KEY_NULL);
		SetTargetFPS(60);

		LoadTextureAsync("assets/player.png", t -> playerTex = t);
		LoadSoundAsync("assets/coin.wav", s -> coinSound = s);
		LoadFileTextAsync(BEST_FILE, text -> {
			var n = Std.parseInt(StringTools.trim(text));
			if (n != null && n > best)
				best = n;
		}, _ -> {});

		while (!WindowShouldClose()) {
			var dt = GetFrameTime();
			if (dt > 0.1)
				dt = 0.1;
			handleDrop();
			if (noticeTime > 0)
				noticeTime -= dt;
			switch (state) {
				case Title:
					if (anyStartPressed())
						startCampaign();
				case Loading:
					if (IsKeyPressed(KEY_ESCAPE))
						toTitle();
				case Playing:
					updatePlay(dt);
				case Message:
					messageTime -= dt;
					if (messageTime <= 0 || (messageTime < 2.5 && anyStartPressed()))
						toTitle();
			}
			draw();
		}
		CloseAudioDevice();
		CloseWindow();
	}

	static function anyStartPressed():Bool {
		if (GetKeyPressed() != 0)
			return true;
		if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT) || IsMouseButtonPressed(MOUSE_BUTTON_RIGHT))
			return true;
		if (GetTouchPointCount() > 0 && GetGestureDetected() == GESTURE_TAP)
			return true;
		for (g in 0...4) {
			if (!IsGamepadAvailable(g))
				continue;
			for (b in 1...18)
				if (IsGamepadButtonPressed(g, b))
					return true;
		}
		return false;
	}

	static function toTitle() {
		loadGeneration++;
		state = Title;
		hasTarget = false;
	}

	static function startCampaign() {
		score = 0;
		loadNumberedLevel(1);
	}

	static function loadNumberedLevel(n:Int) {
		var gen = ++loadGeneration;
		state = Loading;
		levelNumber = n;
		LoadFileTextAsync("assets/levels/level" + n + ".txt", text -> {
			if (gen != loadGeneration)
				return;
			var l = Level.parse(text);
			if (l == null) {
				showMessage("Level " + n + " is not a level file");
				return;
			}
			startLevel(l, n);
		}, _ -> {
			if (gen != loadGeneration)
				return;
			showMessage("You win! Score: " + score);
		});
	}

	static function showMessage(text:String) {
		loadGeneration++;
		messageText = text;
		messageTime = 3.0;
		state = Message;
		hasTarget = false;
	}

	static function handleDrop() {
		if (!IsFileDropped())
			return;
		var files = LoadDroppedFiles();
		var path = files.count > 0 ? files.paths[0] : null;
		UnloadDroppedFiles(files);
		if (path == null)
			return;
		var name = GetFileName(path);
		LoadFileTextAsync(path, text -> {
			var l = Level.parse(text);
			if (l == null) {
				notice("Not a level: " + name);
				return;
			}
			loadGeneration++;
			if (state != Playing)
				score = 0; // from the title a custom level starts a fresh score; in play it carries on
			startLevel(l, 0);
		}, _ -> notice("Not a level: " + name));
	}

	static function notice(text:String) {
		noticeText = text;
		noticeTime = 3.0;
	}

	static function updateBest() {
		if (score > best) {
			best = score;
			SaveFileText(BEST_FILE, Std.string(best));
		}
	}

	// ---- the field ----

	static function startLevel(l:Level, number:Int) {
		level = l;
		levelNumber = number;
		timeLeft = l.seconds;
		gathered = 0;
		hasTarget = false;
		buildField(l);
		state = Playing;
	}

	static function buildField(l:Level) {
		SetRandomSeed(l.seed);
		var w = Std.int(l.width);
		var h = Std.int(l.height);
		rocks = [];
		for (i in 0...l.rocks) {
			var rw = GetRandomValue(40, 160);
			var rh = GetRandomValue(40, 160);
			var rx = GetRandomValue(0, Std.int(Math.max(0, w - rw)));
			var ry = GetRandomValue(0, Std.int(Math.max(0, h - rh)));
			rocks.push(new Rectangle(rx, ry, rw, rh));
		}
		crystals = [];
		var r = Std.int(CRYSTAL_RADIUS);
		for (i in 0...l.crystals) {
			var tries = 0;
			while (tries < 200) {
				tries++;
				var cx = GetRandomValue(r, Std.int(Math.max(r, w - r)));
				var cy = GetRandomValue(r, Std.int(Math.max(r, h - r)));
				var c = new Vector2(cx, cy);
				var clear = true;
				for (rock in rocks)
					if (CheckCollisionCircleRec(c, CRYSTAL_RADIUS + 2, rock)) {
						clear = false;
						break;
					}
				if (clear) {
					crystals.push(c);
					break;
				}
			}
		}
		// The ship starts at the centre, moved off any rock.
		ship = new Vector2(l.width / 2, l.height / 2);
		if (blocked(ship.x, ship.y)) {
			var found = false;
			var radius = 8.0;
			while (!found && radius < Math.max(l.width, l.height)) {
				var steps = 32;
				for (s in 0...steps) {
					var a = s * Math.PI * 2 / steps;
					var x = l.width / 2 + Math.cos(a) * radius;
					var y = l.height / 2 + Math.sin(a) * radius;
					if (!blocked(x, y)) {
						ship = new Vector2(x, y);
						found = true;
						break;
					}
				}
				radius += 8;
			}
		}
	}

	static function shipRect(x:Float, y:Float):Rectangle {
		return new Rectangle(x - SHIP_HALF, y - SHIP_HALF, SHIP_HALF * 2, SHIP_HALF * 2);
	}

	static function blocked(x:Float, y:Float):Bool {
		if (x - SHIP_HALF < 0 || y - SHIP_HALF < 0 || x + SHIP_HALF > level.width || y + SHIP_HALF > level.height)
			return true;
		var r = shipRect(x, y);
		for (rock in rocks)
			if (CheckCollisionRecs(r, rock))
				return true;
		return false;
	}

	/** Moves the ship by (dx, dy), an axis at a time, sliding along what stops it. */
	static function moveShip(dx:Float, dy:Float) {
		if (dx != 0) {
			var nx = ship.x + dx;
			if (!blocked(nx, ship.y))
				ship.x = nx;
			else {
				// Close in on the obstacle.
				var lo = 0.0, hi = 1.0;
				for (i in 0...10) {
					var mid = (lo + hi) / 2;
					if (blocked(ship.x + dx * mid, ship.y))
						hi = mid
					else
						lo = mid;
				}
				ship.x += dx * lo;
			}
		}
		if (dy != 0) {
			var ny = ship.y + dy;
			if (!blocked(ship.x, ny))
				ship.y = ny;
			else {
				var lo = 0.0, hi = 1.0;
				for (i in 0...10) {
					var mid = (lo + hi) / 2;
					if (blocked(ship.x, ship.y + dy * mid))
						hi = mid
					else
						lo = mid;
				}
				ship.y += dy * lo;
			}
		}
	}

	static function updatePlay(dt:Float) {
		if (IsKeyPressed(KEY_ESCAPE)) {
			toTitle();
			return;
		}

		// View controls.
		var wheel = GetMouseWheelMove();
		if (wheel != 0)
			zoom = Math.max(0.5, Math.min(2.0, zoom * Math.pow(1.1, wheel)));
		if (IsKeyDown(KEY_Q))
			turn -= 90 * dt;
		if (IsKeyDown(KEY_E))
			turn += 90 * dt;
		if (IsKeyPressed(KEY_R)) {
			zoom = 1;
			turn = 0;
		}
		updateCamera();

		// Input direction.
		var ix = 0.0, iy = 0.0;
		if (IsKeyDown(KEY_LEFT) || IsKeyDown(KEY_A))
			ix -= 1;
		if (IsKeyDown(KEY_RIGHT) || IsKeyDown(KEY_D))
			ix += 1;
		if (IsKeyDown(KEY_UP) || IsKeyDown(KEY_W))
			iy -= 1;
		if (IsKeyDown(KEY_DOWN) || IsKeyDown(KEY_S))
			iy += 1;
		var len = Math.sqrt(ix * ix + iy * iy);
		if (len > 0) {
			ix /= len;
			iy /= len;
		} else {
			for (g in 0...4) {
				if (!IsGamepadAvailable(g))
					continue;
				var sx = GetGamepadAxisMovement(g, GAMEPAD_AXIS_LEFT_X);
				var sy = GetGamepadAxisMovement(g, GAMEPAD_AXIS_LEFT_Y);
				var m = Math.sqrt(sx * sx + sy * sy);
				if (m > 0.2) {
					if (m > 1) {
						sx /= m;
						sy /= m;
					}
					ix = sx;
					iy = sy;
					len = Math.min(m, 1);
					break;
				}
			}
		}

		if (len > 0) {
			hasTarget = false;
			moveShip(ix * SPEED * dt, iy * SPEED * dt);
		} else {
			if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT)) {
				var p = GetScreenToWorld2D(GetMousePosition(), camera);
				if (p.x >= 0 && p.y >= 0 && p.x <= level.width && p.y <= level.height && !inMap(GetMousePosition())) {
					moveTarget = p;
					hasTarget = true;
				}
			}
			if (hasTarget) {
				var tx = moveTarget.x - ship.x;
				var ty = moveTarget.y - ship.y;
				var d = Math.sqrt(tx * tx + ty * ty);
				var step = SPEED * dt;
				if (d <= step) {
					moveShip(tx, ty);
					hasTarget = false;
				} else {
					var bx = ship.x, by = ship.y;
					moveShip(tx / d * step, ty / d * step);
					var moved = Math.abs(ship.x - bx) + Math.abs(ship.y - by);
					if (moved < step * 0.05)
						hasTarget = false; // stuck against a rock
				}
			}
		}
		updateCamera();

		// Crystals.
		var r = shipRect(ship.x, ship.y);
		var i = crystals.length - 1;
		while (i >= 0) {
			if (CheckCollisionCircleRec(crystals[i], CRYSTAL_RADIUS, r)) {
				crystals.splice(i, 1);
				gathered++;
				score++;
				if (coinSound != null)
					PlaySound(coinSound);
				updateBest();
			}
			i--;
		}

		timeLeft -= dt;
		if (timeLeft <= 0 || crystals.length == 0) {
			if (timeLeft < 0)
				timeLeft = 0;
			endLevel();
		}
	}

	static function endLevel() {
		updateBest();
		if (levelNumber == 0) {
			toTitle();
			return;
		}
		if (gathered >= level.target)
			loadNumberedLevel(levelNumber + 1);
		else
			showMessage("Time! Score: " + score);
	}

	static function updateCamera() {
		camera.target = new Vector2(ship.x, ship.y);
		camera.offset = new Vector2(GetScreenWidth() / 2, GetScreenHeight() / 2);
		camera.rotation = turn;
		camera.zoom = zoom;
	}

	static function mapRect():Rectangle {
		var sw = GetScreenWidth(), sh = GetScreenHeight();
		return new Rectangle(sw - MAP_W - 10, sh - MAP_H - 10, MAP_W, MAP_H);
	}

	static function inMap(p:Vector2):Bool {
		return CheckCollisionPointRec(p, mapRect());
	}

	// ---- drawing ----

	static function draw() {
		BeginDrawing();
		ClearBackground(BLACK);
		var sw = GetScreenWidth(), sh = GetScreenHeight();
		switch (state) {
			case Title:
				drawCentered("Drift Field", sh / 2 - 90, 48, RAYWHITE);
				drawCentered("Press any key, click or tap to start", sh / 2 - 20, 20, LIGHTGRAY);
				drawCentered("Best: " + best, sh / 2 + 20, 20, GOLD);
				drawCentered("Drop a level file to play it", sh / 2 + 55, 20, GRAY);
			case Loading:
				drawCentered("Loading...", sh / 2 - 10, 20, LIGHTGRAY);
			case Playing:
				drawPlay();
			case Message:
				drawCentered(messageText, sh / 2 - 20, 36, RAYWHITE);
		}
		if (noticeTime > 0)
			drawCentered(noticeText, sh - 40, 20, RED);
		EndDrawing();
	}

	static function drawCentered(text:String, y:Float, size:Int, color:Color) {
		var w = MeasureText(text, size);
		DrawText(text, Std.int((GetScreenWidth() - w) / 2), Std.int(y), size, color);
	}

	static function drawPlay() {
		updateCamera();
		BeginMode2D(camera);
		DrawRectangleRec(new Rectangle(0, 0, level.width, level.height), fieldColor);
		for (rock in rocks)
			DrawRectangleRec(rock, rockColor);
		for (c in crystals)
			DrawCircleV(c, CRYSTAL_RADIUS, SKYBLUE);
		DrawRectangleLinesEx(new Rectangle(0, 0, level.width, level.height), 2 / zoom, WHITE);
		if (hasTarget) {
			var s = 6.0;
			DrawLineV(new Vector2(moveTarget.x - s, moveTarget.y - s), new Vector2(moveTarget.x + s, moveTarget.y + s), YELLOW);
			DrawLineV(new Vector2(moveTarget.x - s, moveTarget.y + s), new Vector2(moveTarget.x + s, moveTarget.y - s), YELLOW);
		}
		if (playerTex != null) {
			var tw = playerTex.width, th = playerTex.height;
			DrawTexturePro(playerTex, new Rectangle(0, 0, tw, th), new Rectangle(ship.x, ship.y, 32, 32), new Vector2(16, 16), 0, WHITE);
		} else
			DrawRectangleRec(shipRect(ship.x, ship.y), WHITE);
		EndMode2D();

		drawMap();

		// HUD.
		var sw = GetScreenWidth();
		var levelName = levelNumber == 0 ? "Custom" : Std.string(levelNumber);
		DrawText("Score: " + score, 10, 10, 20, RAYWHITE);
		DrawText("Level: " + levelName, 10, 34, 20, RAYWHITE);
		DrawText("Crystals: " + gathered + " / " + level.target, 10, 58, 20, RAYWHITE);
		var t = "Time: " + Std.int(Math.ceil(timeLeft));
		DrawText(t, sw - MeasureText(t, 20) - 10, 10, 20, RAYWHITE);
	}

	static function drawMap() {
		var m = mapRect();
		var scale = Math.min(m.width / level.width, m.height / level.height);
		var ox = m.x + (m.width - level.width * scale) / 2;
		var oy = m.y + (m.height - level.height * scale) / 2;
		DrawRectangleRec(m, new Color(0, 0, 0, 200));
		BeginScissorMode(Std.int(m.x), Std.int(m.y), Std.int(m.width), Std.int(m.height));
		DrawRectangleRec(new Rectangle(ox, oy, level.width * scale, level.height * scale), fieldColor);
		for (rock in rocks)
			DrawRectangleRec(new Rectangle(ox + rock.x * scale, oy + rock.y * scale, Math.max(1, rock.width * scale),
				Math.max(1, rock.height * scale)), rockColor);
		for (c in crystals)
			DrawCircleV(new Vector2(ox + c.x * scale, oy + c.y * scale), 1.5, SKYBLUE);
		DrawCircleV(new Vector2(ox + ship.x * scale, oy + ship.y * scale), 3, YELLOW);
		EndScissorMode();
		DrawRectangleLinesEx(m, 1, WHITE);
	}
}
