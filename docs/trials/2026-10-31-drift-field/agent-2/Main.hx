import helix.ray.Raylib.*;
import helix.ray.*;

/** A level as read from its file. */
typedef LevelDef = {
	seed:Int,
	width:Int,
	height:Int,
	rocks:Int,
	crystals:Int,
	seconds:Float,
	target:Int
}

enum GameState {
	Title;
	Loading;
	Playing;
	Message;
}

class Main {
	static inline var SPEED = 300.0;
	static inline var CRYSTAL_RADIUS = 8.0;
	static inline var BEST_FILE = "driftfield_best.txt";

	static var state:GameState = Title;
	static var playerTex:Texture2D = null;
	static var coinSound:Sound = null;
	static var audioReady = false;

	static var best = 0;
	static var score = 0;
	static var levelNumber = 1; // 0 means a custom (dropped) level
	static var levelDef:LevelDef = null;
	static var gathered = 0;
	static var timeLeft = 0.0;

	static var rocks:Array<Rectangle> = [];
	static var crystals:Array<Vector2> = [];

	static var shipX = 0.0;
	static var shipY = 0.0;
	static var shipW = 32.0;
	static var shipH = 32.0;
	static var hasTarget = false;
	static var targetX = 0.0;
	static var targetY = 0.0;

	static var zoom = 1.0;
	static var rotation = 0.0;

	static var messageText = "";
	static var messageTimer = 0.0;
	static var notLevelText = "";
	static var notLevelTimer = 0.0;

	/** Increments on each level request, so a late answer for an old request is ignored. */
	static var loadToken = 0;

	static var touchWasDown = false;

	static function main() {
		SetConfigFlags(FLAG_WINDOW_RESIZABLE);
		InitWindow(960, 540, "Drift Field");
		InitAudioDevice();
		audioReady = true;
		SetExitKey(KEY_NULL);
		SetTargetFPS(60);

		LoadTextureAsync("assets/player.png", function(t) {
			playerTex = t;
			shipW = t.width;
			shipH = t.height;
		});
		LoadSoundAsync("assets/coin.wav", function(s) coinSound = s);
		LoadFileTextAsync(BEST_FILE, function(text) {
			var n = Std.parseInt(StringTools.trim(text));
			if (n != null && n > best)
				best = n;
		}, function(_) {});

		while (!WindowShouldClose()) {
			update(GetFrameTime());
			draw();
		}

		if (playerTex != null)
			UnloadTexture(playerTex);
		if (coinSound != null)
			UnloadSound(coinSound);
		CloseAudioDevice();
		CloseWindow();
	}

	// ---------------------------------------------------------------- levels

	static function parseLevel(text:String):Null<LevelDef> {
		var values = new Map<String, Float>();
		for (raw in text.split("\n")) {
			var line = StringTools.trim(raw);
			if (line.length == 0)
				continue;
			var eq = line.indexOf("=");
			if (eq < 0)
				continue;
			var key = StringTools.trim(line.substr(0, eq));
			var valueText = StringTools.trim(line.substr(eq + 1));
			var value = Std.parseFloat(valueText);
			if (Math.isNaN(value) || !~/^-?[0-9]+(\.[0-9]+)?$/.match(valueText))
				continue;
			values.set(key, value);
		}
		for (key in ["seed", "width", "height", "rocks", "crystals", "seconds", "target"])
			if (!values.exists(key))
				return null;
		var def:LevelDef = {
			seed: Std.int(values.get("seed")),
			width: Std.int(values.get("width")),
			height: Std.int(values.get("height")),
			rocks: Std.int(values.get("rocks")),
			crystals: Std.int(values.get("crystals")),
			seconds: values.get("seconds"),
			target: Std.int(values.get("target"))
		};
		if (def.width <= 0 || def.height <= 0)
			return null;
		return def;
	}

	static function levelFileName(n:Int):String {
		return "assets/levels/level" + n + ".txt";
	}

	/** Loads numbered level n; a missing file means the player has won. */
	static function requestLevel(n:Int) {
		var token = ++loadToken;
		state = Loading;
		LoadFileTextAsync(levelFileName(n), function(text) {
			if (token != loadToken)
				return;
			var def = parseLevel(text);
			if (def == null)
				win();
			else
				startLevel(def, n);
		}, function(_) {
			if (token != loadToken)
				return;
			win();
		});
	}

	static function win() {
		showMessage("You win! Score: " + score);
	}

	static function showMessage(text:String) {
		saveBest();
		messageText = text;
		messageTimer = 3.0;
		state = Message;
	}

	static function goTitle() {
		loadToken++;
		state = Title;
	}

	static function saveBest() {
		if (score > best) {
			best = score;
			SaveFileText(BEST_FILE, Std.string(best));
		}
	}

	static function startLevel(def:LevelDef, number:Int) {
		levelDef = def;
		levelNumber = number;
		gathered = 0;
		timeLeft = def.seconds;
		hasTarget = false;
		buildField(def);
		placeShip();
		state = Playing;
	}

	static function buildField(def:LevelDef) {
		SetRandomSeed(def.seed);
		rocks = [];
		for (i in 0...def.rocks) {
			var w = GetRandomValue(40, 160);
			var h = GetRandomValue(40, 160);
			var x = GetRandomValue(0, Std.int(Math.max(0, def.width - w)));
			var y = GetRandomValue(0, Std.int(Math.max(0, def.height - h)));
			rocks.push(new Rectangle(x, y, w, h));
		}
		crystals = [];
		var r = Std.int(CRYSTAL_RADIUS);
		for (i in 0...def.crystals) {
			var tries = 0;
			while (tries < 200) {
				tries++;
				var x = GetRandomValue(r, Std.int(Math.max(r, def.width - r)));
				var y = GetRandomValue(r, Std.int(Math.max(r, def.height - r)));
				var p = new Vector2(x, y);
				var clear = true;
				for (rock in rocks)
					if (CheckCollisionCircleRec(p, CRYSTAL_RADIUS + 2, rock)) {
						clear = false;
						break;
					}
				if (clear) {
					crystals.push(p);
					break;
				}
			}
		}
	}

	static function shipHitsRock(x:Float, y:Float):Bool {
		var box = new Rectangle(x - shipW / 2, y - shipH / 2, shipW, shipH);
		for (rock in rocks)
			if (CheckCollisionRecs(box, rock))
				return true;
		return false;
	}

	static function placeShip() {
		var cx = levelDef.width / 2;
		var cy = levelDef.height / 2;
		shipX = cx;
		shipY = cy;
		if (!shipHitsRock(cx, cy))
			return;
		// Search outward in rings for a clear spot inside the field.
		var radius = 8.0;
		while (radius < Math.max(levelDef.width, levelDef.height)) {
			var steps = Std.int(Math.max(8, radius / 4));
			for (i in 0...steps) {
				var a = i * Math.PI * 2 / steps;
				var x = cx + Math.cos(a) * radius;
				var y = cy + Math.sin(a) * radius;
				if (x - shipW / 2 < 0 || y - shipH / 2 < 0 || x + shipW / 2 > levelDef.width || y + shipH / 2 > levelDef.height)
					continue;
				if (!shipHitsRock(x, y)) {
					shipX = x;
					shipY = y;
					return;
				}
			}
			radius += 8;
		}
	}

	// ---------------------------------------------------------------- input

	static function startPressed():Bool {
		var key = GetKeyPressed();
		if (key != 0 && key != KEY_ESCAPE)
			return true;
		if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT) || IsMouseButtonPressed(MOUSE_BUTTON_RIGHT))
			return true;
		if (tapPressed())
			return true;
		if (GetGamepadButtonPressed() != 0)
			return true;
		return false;
	}

	static var tapThisFrame = false;

	static function tapPressed():Bool {
		return tapThisFrame;
	}

	static function handleDrop() {
		if (!IsFileDropped())
			return;
		var list = LoadDroppedFiles();
		var paths = list.paths.copy();
		UnloadDroppedFiles(list);
		if (paths.length == 0)
			return;
		var path = paths[0];
		var name = GetFileName(path);
		LoadFileTextAsync(path, function(text) {
			var def = parseLevel(text);
			if (def == null) {
				notLevel(name);
			} else {
				loadToken++;
				score = 0;
				startLevel(def, 0);
			}
		}, function(_) notLevel(name));
	}

	static function notLevel(name:String) {
		notLevelText = "Not a level: " + name;
		notLevelTimer = 3.0;
	}

	// ---------------------------------------------------------------- update

	static function update(dt:Float) {
		var touchDown = GetTouchPointCount() > 0;
		tapThisFrame = touchDown && !touchWasDown;
		touchWasDown = touchDown;

		if (notLevelTimer > 0)
			notLevelTimer -= dt;

		handleDrop();

		switch (state) {
			case Title:
				if (startPressed()) {
					score = 0;
					requestLevel(1);
				}
			case Loading:
			case Message:
				messageTimer -= dt;
				if (messageTimer <= 0)
					goTitle();
			case Playing:
				updatePlay(dt);
		}
	}

	static function updatePlay(dt:Float) {
		if (IsKeyPressed(KEY_ESCAPE)) {
			saveBest();
			goTitle();
			return;
		}

		// View controls.
		var wheel = GetMouseWheelMove();
		if (wheel != 0)
			zoom = Math.max(0.5, Math.min(2.0, zoom * Math.pow(1.1, wheel)));
		if (IsKeyDown(KEY_Q))
			rotation -= 90 * dt;
		if (IsKeyDown(KEY_E))
			rotation += 90 * dt;
		if (IsKeyPressed(KEY_R)) {
			zoom = 1;
			rotation = 0;
		}

		// Movement input.
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
		for (pad in 0...4) {
			if (!IsGamepadAvailable(pad))
				continue;
			var ax = GetGamepadAxisMovement(pad, GAMEPAD_AXIS_LEFT_X);
			var ay = GetGamepadAxisMovement(pad, GAMEPAD_AXIS_LEFT_Y);
			if (Math.sqrt(ax * ax + ay * ay) > 0.2) {
				ix += ax;
				iy += ay;
			}
		}
		var len = Math.sqrt(ix * ix + iy * iy);
		if (len > 1) {
			ix /= len;
			iy /= len;
		}

		// A click or tap on the field sends the ship there.
		var pointer:Vector2 = null;
		if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT))
			pointer = GetMousePosition();
		else if (tapThisFrame)
			pointer = GetTouchPosition(0);
		if (pointer != null) {
			var world = GetScreenToWorld2D(pointer, makeCamera());
			if (world.x >= 0 && world.y >= 0 && world.x <= levelDef.width && world.y <= levelDef.height) {
				hasTarget = true;
				targetX = world.x;
				targetY = world.y;
			}
		}

		if (len > 0.0001) {
			hasTarget = false;
			moveShip(ix * SPEED * dt, iy * SPEED * dt);
		} else if (hasTarget) {
			var dx = targetX - shipX;
			var dy = targetY - shipY;
			var dist = Math.sqrt(dx * dx + dy * dy);
			var step = SPEED * dt;
			if (dist <= step) {
				moveShip(dx, dy);
				hasTarget = false;
			} else {
				moveShip(dx / dist * step, dy / dist * step);
			}
		}

		// Gather crystals.
		var box = new Rectangle(shipX - shipW / 2, shipY - shipH / 2, shipW, shipH);
		var i = crystals.length - 1;
		while (i >= 0) {
			if (CheckCollisionCircleRec(crystals[i], CRYSTAL_RADIUS, box)) {
				crystals.splice(i, 1);
				gathered++;
				score++;
				if (coinSound != null)
					PlaySound(coinSound);
				saveBest();
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
		saveBest();
		if (levelNumber == 0) {
			showMessage((gathered >= levelDef.target ? "Level done! Score: " : "Time! Score: ") + score);
		} else if (gathered >= levelDef.target) {
			requestLevel(levelNumber + 1);
		} else {
			showMessage("Time! Score: " + score);
		}
	}

	/** Moves the ship one axis at a time, so it slides along what it hits. */
	static function moveShip(dx:Float, dy:Float) {
		var hw = shipW / 2;
		var hh = shipH / 2;

		var nx = shipX + dx;
		nx = Math.max(hw, Math.min(levelDef.width - hw, nx));
		for (rock in rocks) {
			if (overlaps(nx, shipY, hw, hh, rock)) {
				if (dx > 0)
					nx = rock.x - hw;
				else if (dx < 0)
					nx = rock.x + rock.width + hw;
				else
					nx = shipX;
			}
		}
		shipX = nx;

		var ny = shipY + dy;
		ny = Math.max(hh, Math.min(levelDef.height - hh, ny));
		for (rock in rocks) {
			if (overlaps(shipX, ny, hw, hh, rock)) {
				if (dy > 0)
					ny = rock.y - hh;
				else if (dy < 0)
					ny = rock.y + rock.height + hh;
				else
					ny = shipY;
			}
		}
		shipY = ny;
	}

	static function overlaps(x:Float, y:Float, hw:Float, hh:Float, r:Rectangle):Bool {
		return x + hw > r.x && x - hw < r.x + r.width && y + hh > r.y && y - hh < r.y + r.height;
	}

	// ---------------------------------------------------------------- draw

	static function makeCamera():Camera2D {
		return new Camera2D(new Vector2(GetScreenWidth() / 2, GetScreenHeight() / 2), new Vector2(shipX, shipY), rotation, zoom);
	}

	static function drawCentered(text:String, y:Int, size:Int, color:Color) {
		var w = MeasureText(text, size);
		DrawText(text, Std.int((GetScreenWidth() - w) / 2), y, size, color);
	}

	static function draw() {
		BeginDrawing();
		ClearBackground(BLACK);
		var sw = GetScreenWidth();
		var sh = GetScreenHeight();

		switch (state) {
			case Title:
				var y = Std.int(sh / 2) - 90;
				drawCentered("Drift Field", y, 60, SKYBLUE);
				drawCentered("Press any key, click or tap to start", y + 80, 24, RAYWHITE);
				drawCentered("Best: " + best, y + 120, 24, GOLD);
				drawCentered("Drop a level file to play it", y + 160, 20, GRAY);
			case Loading:
				drawCentered("Loading...", Std.int(sh / 2) - 12, 24, RAYWHITE);
			case Message:
				drawCentered(messageText, Std.int(sh / 2) - 20, 40, GOLD);
			case Playing:
				drawPlay(sw, sh);
		}

		if (notLevelTimer > 0)
			drawCentered(notLevelText, sh - 40, 20, RED);

		EndDrawing();
	}

	static function drawPlay(sw:Int, sh:Int) {
		var fieldColor = new Color(10, 20, 60, 255);
		var rockColor = GRAY;
		var crystalColor = new Color(0, 255, 255, 255);

		BeginMode2D(makeCamera());
		var field = new Rectangle(0, 0, levelDef.width, levelDef.height);
		DrawRectangleRec(field, fieldColor);
		for (rock in rocks)
			DrawRectangleRec(rock, rockColor);
		for (c in crystals)
			DrawCircleV(c, CRYSTAL_RADIUS, crystalColor);
		DrawRectangleLinesEx(field, 3, WHITE);
		if (hasTarget) {
			var s = 8.0;
			DrawLineEx(new Vector2(targetX - s, targetY - s), new Vector2(targetX + s, targetY + s), 2, YELLOW);
			DrawLineEx(new Vector2(targetX - s, targetY + s), new Vector2(targetX + s, targetY - s), 2, YELLOW);
		}
		if (playerTex != null) {
			DrawTextureEx(playerTex, new Vector2(shipX - shipW / 2, shipY - shipH / 2), 0, 1, WHITE);
		} else {
			DrawRectangleRec(new Rectangle(shipX - shipW / 2, shipY - shipH / 2, shipW, shipH), ORANGE);
		}
		EndMode2D();

		// The map.
		var mw = 200;
		var mh = 120;
		var mx = sw - mw - 10;
		var my = sh - mh - 10;
		var scale = Math.min(mw / levelDef.width, mh / levelDef.height);
		var fw = levelDef.width * scale;
		var fh = levelDef.height * scale;
		var ox = mx + (mw - fw) / 2;
		var oy = my + (mh - fh) / 2;
		DrawRectangle(mx, my, mw, mh, new Color(0, 0, 0, 200));
		BeginScissorMode(mx, my, mw, mh);
		DrawRectangleRec(new Rectangle(ox, oy, fw, fh), fieldColor);
		for (rock in rocks)
			DrawRectangleRec(new Rectangle(ox + rock.x * scale, oy + rock.y * scale, Math.max(1, rock.width * scale), Math.max(1, rock.height * scale)), rockColor);
		for (c in crystals)
			DrawCircleV(new Vector2(ox + c.x * scale, oy + c.y * scale), 1.5, crystalColor);
		DrawCircleV(new Vector2(ox + shipX * scale, oy + shipY * scale), 3, YELLOW);
		EndScissorMode();
		DrawRectangleLinesEx(new Rectangle(mx - 2, my - 2, mw + 4, mh + 4), 2, WHITE);

		// Text.
		var levelName = levelNumber == 0 ? "Custom" : Std.string(levelNumber);
		DrawText("Score: " + score, 10, 10, 20, WHITE);
		DrawText("Level: " + levelName, 10, 34, 20, WHITE);
		DrawText("Crystals: " + gathered + " / " + levelDef.target, 10, 58, 20, WHITE);
		var t = "Time: " + Math.ceil(Math.max(0, timeLeft));
		DrawText(t, sw - MeasureText(t, 20) - 10, 10, 20, WHITE);
	}
}
