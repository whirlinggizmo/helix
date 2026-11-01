import helix.ray.Raylib.*;
import helix.ray.Camera2D;
import helix.ray.Color;
import helix.ray.Rectangle;
import helix.ray.Sound;
import helix.ray.Texture2D;
import helix.ray.Vector2;

/** A level's settings, read from its file. */
typedef LevelData = {
	seed:Int,
	width:Int,
	height:Int,
	rocks:Int,
	crystals:Int,
	seconds:Float,
	target:Int
}

/** A crystal in the field. */
typedef Crystal = {
	x:Float,
	y:Float,
	gathered:Bool
}

/** The screens the game moves between. */
enum abstract Screen(Int) {
	var Title;
	var Loading;
	var Play;
	var Message;
}

/** Drift Field: a ship gathering crystals in a field larger than the window. */
class Main {
	static inline var SPEED = 300.0;
	static inline var SHIP_SIZE = 32.0;
	static inline var CRYSTAL_RADIUS = 8.0;
	static inline var MAP_W = 200;
	static inline var MAP_H = 120;
	static inline var BEST_FILE = "best.txt";

	static var screen:Screen = Title;
	static var best = 0;
	static var score = 0;
	static var levelNumber = 1;
	static var custom = false;
	static var level:LevelData;
	static var rocks:Array<Rectangle> = [];
	static var crystals:Array<Crystal> = [];
	static var gathered = 0;
	static var timeLeft = 0.0;
	static var shipX = 0.0;
	static var shipY = 0.0;
	static var shipAngle = 0.0;
	static var hasTarget = false;
	static var targetX = 0.0;
	static var targetY = 0.0;
	static var stuckTime = 0.0;
	static var zoom = 1.0;
	static var turn = 0.0;
	static var camera:Camera2D;
	static var shipTexture:Null<Texture2D> = null;
	static var coinSound:Null<Sound> = null;
	static var messageText = "";
	static var messageTime = 0.0;
	static var noticeText = "";
	static var noticeTime = 0.0;
	static var loadToken = 0;

	static var fieldColor = new Color(12, 20, 52, 255);
	static var rockColor = new Color(130, 130, 130, 255);
	static var crystalColor = new Color(0, 230, 255, 255);

	/** Opens the window, loads the assets and runs the game until the window closes. */
	static function main() {
		SetConfigFlags(FLAG_WINDOW_RESIZABLE);
		InitWindow(960, 540, "Drift Field");
		InitAudioDevice();
		SetTargetFPS(60);
		SetExitKey(KEY_NULL); // Escape returns to the title rather than closing the window
		camera = new Camera2D(new Vector2(480, 270), new Vector2(0, 0), 0, 1);

		LoadTextureAsync("assets/player.png", t -> shipTexture = t);
		LoadSoundAsync("assets/coin.wav", s -> coinSound = s);
		LoadFileTextAsync(BEST_FILE, text -> {
			var n = Std.parseInt(StringTools.trim(text));
			if (n != null && n > best)
				best = n;
		}, _ -> {});

		while (!WindowShouldClose()) {
			update(Math.min(GetFrameTime(), 0.1));
			draw();
		}
		CloseAudioDevice();
		CloseWindow();
	}

	// ---- input helpers ----

	static function anyStartInput():Bool {
		if (GetKeyPressed() != 0)
			return true;
		if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT) || IsMouseButtonPressed(MOUSE_BUTTON_RIGHT))
			return true;
		if (IsGestureDetected(GESTURE_TAP))
			return true;
		for (pad in 0...4) {
			if (!IsGamepadAvailable(pad))
				continue;
			for (button in 1...18)
				if (IsGamepadButtonPressed(pad, button))
					return true;
		}
		return false;
	}

	// ---- levels ----

	static function parseLevel(text:Null<String>):Null<LevelData> {
		if (text == null)
			return null;
		var values = new Map<String, Float>();
		for (line in text.split("\n")) {
			var l = StringTools.trim(line);
			if (l == "")
				continue;
			var eq = l.indexOf("=");
			if (eq < 0)
				continue;
			var key = StringTools.trim(l.substr(0, eq));
			var value = Std.parseFloat(StringTools.trim(l.substr(eq + 1)));
			if (Math.isNaN(value))
				return null;
			values.set(key, value);
		}
		for (k in ["seed", "width", "height", "rocks", "crystals", "seconds", "target"])
			if (!values.exists(k))
				return null;
		var w = Std.int(values.get("width"));
		var h = Std.int(values.get("height"));
		if (w < 100 || h < 100)
			return null;
		return {
			seed: Std.int(values.get("seed")),
			width: w,
			height: h,
			rocks: Std.int(Math.max(0, values.get("rocks"))),
			crystals: Std.int(Math.max(0, values.get("crystals"))),
			seconds: values.get("seconds"),
			target: Std.int(values.get("target"))
		};
	}

	static function loadLevel(n:Int) {
		levelNumber = n;
		custom = false;
		screen = Loading;
		var token = ++loadToken;
		LoadFileTextAsync('assets/levels/level$n.txt', text -> {
			if (token != loadToken)
				return;
			var data = parseLevel(text);
			if (data == null)
				showMessage('You win! Score: $score');
			else
				startLevel(data);
		}, _ -> {
			if (token != loadToken)
				return;
			showMessage('You win! Score: $score');
		});
	}

	static function handleDrop() {
		if (!IsFileDropped())
			return;
		var files = LoadDroppedFiles();
		if (files.count > 0) {
			var path = files.paths[0];
			var name = GetFileName(path);
			var wasPlaying = screen == Play;
			LoadFileTextAsync(path, text -> {
				var data = parseLevel(text);
				if (data == null) {
					notLevel(name);
					return;
				}
				++loadToken; // cancels any level still loading
				if (!wasPlaying)
					score = 0;
				custom = true;
				startLevel(data);
			}, _ -> notLevel(name));
		}
		UnloadDroppedFiles(files);
	}

	static function notLevel(name:String) {
		noticeText = 'Not a level: $name';
		noticeTime = 3;
	}

	static function startLevel(data:LevelData) {
		level = data;
		SetRandomSeed(data.seed);
		rocks = [];
		for (i in 0...data.rocks) {
			var w = GetRandomValue(40, 160);
			var h = GetRandomValue(40, 160);
			var x = GetRandomValue(0, Std.int(Math.max(0, data.width - w)));
			var y = GetRandomValue(0, Std.int(Math.max(0, data.height - h)));
			rocks.push(new Rectangle(x, y, w, h));
		}
		crystals = [];
		for (i in 0...data.crystals) {
			var placed = false;
			var tries = 0;
			while (!placed && tries < 200) {
				tries++;
				var x = GetRandomValue(20, data.width - 20);
				var y = GetRandomValue(20, data.height - 20);
				var c = new Vector2(x, y);
				var clear = true;
				for (r in rocks)
					if (CheckCollisionCircleRec(c, CRYSTAL_RADIUS + 6, r)) {
						clear = false;
						break;
					}
				if (clear) {
					crystals.push({x: x, y: y, gathered: false});
					placed = true;
				}
			}
		}
		gathered = 0;
		timeLeft = data.seconds;
		hasTarget = false;
		stuckTime = 0;
		shipAngle = 0;
		placeShip(data.width / 2, data.height / 2);
		screen = Play;
	}

	/** Puts the ship at (x, y), or the nearest place clear of rocks, searched in rings. */
	static function placeShip(x:Float, y:Float) {
		var ring = 0;
		while (ring < 200) {
			var steps = ring == 0 ? 1 : ring * 8;
			for (s in 0...steps) {
				var a = s / steps * Math.PI * 2;
				var px = x + Math.cos(a) * ring * 16;
				var py = y + Math.sin(a) * ring * 16;
				if (px < SHIP_SIZE / 2 || py < SHIP_SIZE / 2 || px > level.width - SHIP_SIZE / 2 || py > level.height - SHIP_SIZE / 2)
					continue;
				if (!hitsRock(px, py)) {
					shipX = px;
					shipY = py;
					return;
				}
			}
			ring++;
		}
		shipX = x;
		shipY = y;
	}

	static function shipRect(x:Float, y:Float):Rectangle {
		return new Rectangle(x - SHIP_SIZE / 2 + 2, y - SHIP_SIZE / 2 + 2, SHIP_SIZE - 4, SHIP_SIZE - 4);
	}

	static function hitsRock(x:Float, y:Float):Bool {
		var s = shipRect(x, y);
		for (r in rocks)
			if (CheckCollisionRecs(s, r))
				return true;
		return false;
	}

	static function showMessage(text:String) {
		messageText = text;
		messageTime = 3;
		screen = Message;
	}

	static function endLevel() {
		if (custom) {
			showMessage('Level done! Score: $score');
		} else if (gathered >= level.target) {
			loadLevel(levelNumber + 1);
		} else {
			showMessage('Time! Score: $score');
		}
	}

	static function addScore() {
		score++;
		if (score > best) {
			best = score;
			SaveFileText(BEST_FILE, Std.string(best));
		}
	}

	// ---- update ----

	static function update(dt:Float) {
		if (noticeTime > 0)
			noticeTime -= dt;
		handleDrop();
		switch (screen) {
			case Title:
				if (anyStartInput()) {
					score = 0;
					loadLevel(1);
				}
			case Loading:
			case Message:
				messageTime -= dt;
				if (messageTime <= 0 || (messageTime < 2 && anyStartInput()))
					screen = Title;
			case Play:
				updatePlay(dt);
		}
	}

	static function updatePlay(dt:Float) {
		if (IsKeyPressed(KEY_ESCAPE)) {
			screen = Title;
			return;
		}

		// View controls.
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
		updateCamera();

		// Direction from keys and stick.
		var dx = 0.0, dy = 0.0;
		if (IsKeyDown(KEY_RIGHT) || IsKeyDown(KEY_D))
			dx += 1;
		if (IsKeyDown(KEY_LEFT) || IsKeyDown(KEY_A))
			dx -= 1;
		if (IsKeyDown(KEY_DOWN) || IsKeyDown(KEY_S))
			dy += 1;
		if (IsKeyDown(KEY_UP) || IsKeyDown(KEY_W))
			dy -= 1;
		if (IsGamepadAvailable(0)) {
			var sx = GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_X);
			var sy = GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_Y);
			if (Math.sqrt(sx * sx + sy * sy) > 0.25) {
				dx += sx;
				dy += sy;
			}
		}
		var len = Math.sqrt(dx * dx + dy * dy);
		if (len > 0) {
			hasTarget = false;
			if (len > 1) {
				dx /= len;
				dy /= len;
			}
		}

		// Click or tap sends the ship to that world point.
		if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT) && len == 0) {
			var w = GetScreenToWorld2D(GetMousePosition(), camera);
			if (w.x >= 0 && w.y >= 0 && w.x <= level.width && w.y <= level.height) {
				targetX = w.x;
				targetY = w.y;
				hasTarget = true;
				stuckTime = 0;
			}
		}

		var step = SPEED * dt;
		var mx = 0.0, my = 0.0;
		if (len > 0) {
			mx = dx * step;
			my = dy * step;
		} else if (hasTarget) {
			var tx = targetX - shipX, ty = targetY - shipY;
			var d = Math.sqrt(tx * tx + ty * ty);
			if (d <= step) {
				mx = tx;
				my = ty;
				hasTarget = false;
			} else {
				mx = tx / d * step;
				my = ty / d * step;
			}
		}
		if (mx != 0 || my != 0) {
			shipAngle = Math.atan2(my, mx) * 180 / Math.PI + 90;
			var beforeX = shipX, beforeY = shipY;
			moveShip(mx, my);
			if (hasTarget) {
				var moved = Math.abs(shipX - beforeX) + Math.abs(shipY - beforeY);
				if (moved < step * 0.05) {
					stuckTime += dt;
					if (stuckTime > 0.5)
						hasTarget = false;
				} else
					stuckTime = 0;
			}
		}
		updateCamera();

		// Gather crystals.
		var shipCircle = new Vector2(shipX, shipY);
		for (c in crystals) {
			if (c.gathered)
				continue;
			if (CheckCollisionCircles(shipCircle, SHIP_SIZE / 2 - 2, new Vector2(c.x, c.y), CRYSTAL_RADIUS)) {
				c.gathered = true;
				gathered++;
				addScore();
				if (coinSound != null)
					PlaySound(coinSound);
			}
		}

		timeLeft -= dt;
		if (timeLeft <= 0) {
			timeLeft = 0;
			endLevel();
		} else if (gathered >= crystals.length) {
			endLevel();
		}
	}

	/** Moves one axis at a time so rocks and edges stop that axis only: the ship slides along them. */
	static function moveShip(mx:Float, my:Float) {
		var half = SHIP_SIZE / 2;
		var nx = Math.max(half, Math.min(level.width - half, shipX + mx));
		if (!hitsRock(nx, shipY))
			shipX = nx;
		else
			shipX = slideTo(shipX, nx, true);
		var ny = Math.max(half, Math.min(level.height - half, shipY + my));
		if (!hitsRock(shipX, ny))
			shipY = ny;
		else
			shipY = slideTo(shipY, ny, false);
	}

	/** Moves as far from `from` toward `to` as rocks allow, on one axis. */
	static function slideTo(from:Float, to:Float, xAxis:Bool):Float {
		var lo = 0.0, hi = 1.0;
		for (i in 0...10) {
			var mid = (lo + hi) / 2;
			var p = from + (to - from) * mid;
			var hit = xAxis ? hitsRock(p, shipY) : hitsRock(shipX, p);
			if (hit)
				hi = mid;
			else
				lo = mid;
		}
		return from + (to - from) * lo;
	}

	static function updateCamera() {
		camera = new Camera2D(new Vector2(GetScreenWidth() / 2, GetScreenHeight() / 2), new Vector2(shipX, shipY), turn, zoom);
	}

	// ---- drawing ----

	static function centerText(text:String, y:Int, size:Int, color:Color) {
		DrawText(text, Std.int((GetScreenWidth() - MeasureText(text, size)) / 2), y, size, color);
	}

	static function draw() {
		BeginDrawing();
		ClearBackground(BLACK);
		var sh = GetScreenHeight();
		switch (screen) {
			case Title:
				centerText("Drift Field", Std.int(sh / 2) - 90, 60, RAYWHITE);
				centerText("Press any key, click or tap to start", Std.int(sh / 2) - 10, 24, LIGHTGRAY);
				centerText('Best: $best', Std.int(sh / 2) + 30, 24, GOLD);
				centerText("Drop a level file to play it", Std.int(sh / 2) + 70, 20, GRAY);
			case Loading:
				centerText("Loading...", Std.int(sh / 2) - 10, 24, LIGHTGRAY);
			case Message:
				centerText(messageText, Std.int(sh / 2) - 20, 40, RAYWHITE);
			case Play:
				drawPlay();
		}
		if (noticeTime > 0)
			centerText(noticeText, sh - 60, 24, RED);
		EndDrawing();
	}

	static function drawPlay() {
		var sw = GetScreenWidth();
		var sh = GetScreenHeight();

		BeginMode2D(camera);
		DrawRectangle(0, 0, level.width, level.height, fieldColor);
		for (r in rocks)
			DrawRectangleRec(r, rockColor);
		for (c in crystals)
			if (!c.gathered)
				DrawCircleV(new Vector2(c.x, c.y), CRYSTAL_RADIUS, crystalColor);
		DrawRectangleLinesEx(new Rectangle(-2, -2, level.width + 4, level.height + 4), 2, WHITE);
		if (hasTarget) {
			DrawLineEx(new Vector2(targetX - 6, targetY - 6), new Vector2(targetX + 6, targetY + 6), 2, YELLOW);
			DrawLineEx(new Vector2(targetX - 6, targetY + 6), new Vector2(targetX + 6, targetY - 6), 2, YELLOW);
		}
		if (shipTexture != null) {
			var t:Texture2D = shipTexture;
			DrawTexturePro(t, new Rectangle(0, 0, t.width, t.height), new Rectangle(shipX, shipY, SHIP_SIZE, SHIP_SIZE),
				new Vector2(SHIP_SIZE / 2, SHIP_SIZE / 2), shipAngle, WHITE);
		} else {
			DrawCircleV(new Vector2(shipX, shipY), SHIP_SIZE / 2, WHITE);
		}
		EndMode2D();

		drawMap(sw, sh);

		// Text, in screen space.
		var levelName = custom ? "Custom" : Std.string(levelNumber);
		DrawText('Score: $score', 10, 10, 24, RAYWHITE);
		DrawText('Level: $levelName', 10, 40, 20, RAYWHITE);
		DrawText('Crystals: $gathered / ${level.target}', 10, 66, 20, RAYWHITE);
		var timeText = 'Time: ${Math.ceil(timeLeft)}';
		DrawText(timeText, sw - MeasureText(timeText, 24) - 10, 10, 24, RAYWHITE);
	}

	static function drawMap(sw:Int, sh:Int) {
		var mx = sw - MAP_W - 10;
		var my = sh - MAP_H - 10;
		var scale = Math.min(MAP_W / level.width, MAP_H / level.height);
		var ox = mx + (MAP_W - level.width * scale) / 2;
		var oy = my + (MAP_H - level.height * scale) / 2;

		DrawRectangle(mx, my, MAP_W, MAP_H, new Color(0, 0, 0, 200));
		BeginScissorMode(mx, my, MAP_W, MAP_H);
		DrawRectangleRec(new Rectangle(ox, oy, level.width * scale, level.height * scale), fieldColor);
		for (r in rocks)
			DrawRectangleRec(new Rectangle(ox + r.x * scale, oy + r.y * scale, Math.max(1, r.width * scale), Math.max(1, r.height * scale)),
				rockColor);
		for (c in crystals)
			if (!c.gathered)
				DrawRectangleRec(new Rectangle(ox + c.x * scale - 1, oy + c.y * scale - 1, 2, 2), crystalColor);
		DrawCircleV(new Vector2(ox + shipX * scale, oy + shipY * scale), 3, YELLOW);
		EndScissorMode();
		DrawRectangleLines(mx - 1, my - 1, MAP_W + 2, MAP_H + 2, WHITE);
	}
}
