import helix.ray.Raylib.*;
import helix.ray.*;

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

enum GameState {
	Title;
	Loading;
	Play;
	Result;
}

class Main {
	static inline var SCREEN_W = 960;
	static inline var SCREEN_H = 540;
	static inline var SPEED = 300.0;
	static inline var CRYSTAL_R = 8.0;
	static inline var SHIP_SIZE = 32.0;
	static inline var BEST_FILE = "driftfield_best.txt";

	static var state:GameState = Title;
	static var shipTex:Texture2D;
	static var coinSound:Sound;

	static var best = 0;
	static var score = 0;
	static var levelNumber = 1; // 0 means custom
	static var level:LevelData;
	static var gathered = 0;
	static var timeLeft = 0.0;

	static var rocks:Array<Rectangle> = [];
	static var crystals:Array<Vector2> = [];
	static var crystalAlive:Array<Bool> = [];

	static var shipX = 0.0;
	static var shipY = 0.0;
	static var hasTarget = false;
	static var targetX = 0.0;
	static var targetY = 0.0;

	static var zoom = 1.0;
	static var rotation = 0.0;
	static var camera:Camera2D;

	static var resultText = "";
	static var resultTimer = 0.0;
	static var noticeText = "";
	static var noticeTimer = 0.0;
	static var loadToken = 0;

	static function main() {
		SetConfigFlags(FLAG_WINDOW_RESIZABLE);
		InitWindow(SCREEN_W, SCREEN_H, "Drift Field");
		InitAudioDevice();
		SetExitKey(KEY_NULL);
		SetTargetFPS(60);

		LoadTextureAsync("assets/player.png", function(t:Texture2D) {
			shipTex = t;
		}, function(e:String) {
			TraceLog(LOG_WARNING, "player.png failed: " + e);
		});
		LoadSoundAsync("assets/coin.wav", function(s:Sound) {
			coinSound = s;
		}, function(e:String) {
			TraceLog(LOG_WARNING, "coin.wav failed: " + e);
		});
		camera = new Camera2D(new Vector2(SCREEN_W / 2, SCREEN_H / 2), new Vector2(0, 0), 0, 1);

		FileExistsAsync(BEST_FILE, function(exists:Bool) {
			if (!exists)
				return;
			LoadFileTextAsync(BEST_FILE, function(text:String) {
				var v = Std.parseInt(StringTools.trim(text));
				if (v != null && v > best)
					best = v;
			});
		});

		while (!WindowShouldClose()) {
			update();
			draw();
		}

		if (shipTex != null)
			UnloadTexture(shipTex);
		if (coinSound != null)
			UnloadSound(coinSound);
		CloseAudioDevice();
		CloseWindow();
	}

	// ---------------------------------------------------------------- input helpers

	static function anyStartInput():Bool {
		if (GetKeyPressed() != 0)
			return true;
		if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT) || IsMouseButtonPressed(MOUSE_BUTTON_RIGHT))
			return true;
		if (IsGestureDetected(GESTURE_TAP))
			return true;
		if (GetGamepadButtonPressed() != 0)
			return true;
		return false;
	}

	// ---------------------------------------------------------------- level files

	static function parseLevel(text:String):Null<LevelData> {
		var values = new Map<String, Float>();
		for (rawLine in text.split("\n")) {
			var line = StringTools.trim(rawLine);
			if (line.length == 0)
				continue;
			var eq = line.indexOf("=");
			if (eq < 0)
				continue;
			var key = StringTools.trim(line.substr(0, eq));
			var valueText = StringTools.trim(line.substr(eq + 1));
			var v = Std.parseFloat(valueText);
			if (Math.isNaN(v) || !~/^-?[0-9]+(\.[0-9]+)?$/.match(valueText))
				continue;
			values.set(key, v);
		}
		for (k in ["seed", "width", "height", "rocks", "crystals", "seconds", "target"])
			if (!values.exists(k))
				return null;
		var data:LevelData = {
			seed: Std.int(values.get("seed")),
			width: Std.int(values.get("width")),
			height: Std.int(values.get("height")),
			rocks: Std.int(values.get("rocks")),
			crystals: Std.int(values.get("crystals")),
			seconds: values.get("seconds"),
			target: Std.int(values.get("target"))
		};
		if (data.width < 100 || data.height < 100 || data.seconds <= 0 || data.rocks < 0 || data.crystals < 0)
			return null;
		return data;
	}

	static function requestLevel(n:Int) {
		state = Loading;
		var token = ++loadToken;
		var name = "assets/levels/level" + n + ".txt";
		LoadFileTextAsync(name, function(text:String) {
			if (token != loadToken)
				return;
			var data = parseLevel(text);
			if (data == null) {
				// A numbered level that can't be read counts as no more levels.
				finishGame("You win! Score: " + score);
				return;
			}
			startLevel(data, n);
		}, function(error:String) {
			if (token != loadToken)
				return;
			finishGame("You win! Score: " + score);
		});
	}

	static function handleDrop() {
		if (!IsFileDropped())
			return;
		var files = LoadDroppedFiles();
		if (files.count > 0) {
			var path = files.paths[0];
			var name = GetFileName(path);
			LoadFileTextAsync(path, function(text:String) {
				var data = parseLevel(text);
				if (data == null) {
					showNotice("Not a level: " + name);
					return;
				}
				loadToken++;
				score = 0;
				startLevel(data, 0);
			}, function(error:String) {
				showNotice("Not a level: " + name);
			});
		}
		UnloadDroppedFiles(files);
	}

	static function showNotice(text:String) {
		noticeText = text;
		noticeTimer = 3.0;
	}

	static function saveBestIfNeeded() {
		if (score > best) {
			best = score;
			SaveFileText(BEST_FILE, Std.string(best));
		}
	}

	static function finishGame(text:String) {
		saveBestIfNeeded();
		resultText = text;
		resultTimer = 3.0;
		state = Result;
	}

	// ---------------------------------------------------------------- field

	static function startLevel(data:LevelData, n:Int) {
		level = data;
		levelNumber = n;
		gathered = 0;
		timeLeft = data.seconds;
		hasTarget = false;
		zoom = 1;
		rotation = 0;

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
		crystalAlive = [];
		var margin = Std.int(CRYSTAL_R) + 4;
		for (i in 0...data.crystals) {
			var placed = false;
			var cx = 0.0, cy = 0.0;
			for (attempt in 0...200) {
				cx = GetRandomValue(margin, data.width - margin);
				cy = GetRandomValue(margin, data.height - margin);
				var clear = true;
				for (r in rocks) {
					if (CheckCollisionCircleRec(new Vector2(cx, cy), CRYSTAL_R + 2, r)) {
						clear = false;
						break;
					}
				}
				if (clear) {
					placed = true;
					break;
				}
			}
			if (placed) {
				crystals.push(new Vector2(cx, cy));
				crystalAlive.push(true);
			}
		}

		// Ship at the center, moved off any rock it lands on.
		shipX = data.width / 2;
		shipY = data.height / 2;
		if (shipBlocked(shipX, shipY)) {
			var found = false;
			var radius = 10.0;
			while (!found && radius < Math.max(data.width, data.height)) {
				var steps = 16;
				for (s in 0...steps) {
					var a = s * Math.PI * 2 / steps;
					var px = data.width / 2 + Math.cos(a) * radius;
					var py = data.height / 2 + Math.sin(a) * radius;
					if (!shipBlocked(px, py)) {
						shipX = px;
						shipY = py;
						found = true;
						break;
					}
				}
				radius += 10;
			}
		}
		state = Play;
	}

	static function shipRect(x:Float, y:Float):Rectangle {
		return new Rectangle(x - SHIP_SIZE / 2, y - SHIP_SIZE / 2, SHIP_SIZE, SHIP_SIZE);
	}

	static function shipBlocked(x:Float, y:Float):Bool {
		var half = SHIP_SIZE / 2;
		if (x - half < 0 || y - half < 0 || x + half > level.width || y + half > level.height)
			return true;
		var r = shipRect(x, y);
		for (rock in rocks)
			if (CheckCollisionRecs(r, rock))
				return true;
		return false;
	}

	/** Moves the ship by dx, dy one axis at a time, so it slides along what stops it. */
	static function moveShip(dx:Float, dy:Float) {
		var half = SHIP_SIZE / 2;
		if (dx != 0) {
			var nx = shipX + dx;
			nx = Math.max(half, Math.min(level.width - half, nx));
			var r = shipRect(nx, shipY);
			for (rock in rocks) {
				if (CheckCollisionRecs(r, rock)) {
					if (dx > 0)
						nx = Math.min(nx, rock.x - half);
					else
						nx = Math.max(nx, rock.x + rock.width + half);
					r = shipRect(nx, shipY);
				}
			}
			shipX = nx;
		}
		if (dy != 0) {
			var ny = shipY + dy;
			ny = Math.max(half, Math.min(level.height - half, ny));
			var r = shipRect(shipX, ny);
			for (rock in rocks) {
				if (CheckCollisionRecs(r, rock)) {
					if (dy > 0)
						ny = Math.min(ny, rock.y - half);
					else
						ny = Math.max(ny, rock.y + rock.height + half);
					r = shipRect(shipX, ny);
				}
			}
			shipY = ny;
		}
	}

	static function updateCamera() {
		camera.offset = new Vector2(GetScreenWidth() / 2, GetScreenHeight() / 2);
		camera.target = new Vector2(shipX, shipY);
		camera.rotation = rotation;
		camera.zoom = zoom;
	}

	// ---------------------------------------------------------------- update

	static function update() {
		var dt = GetFrameTime();
		if (noticeTimer > 0)
			noticeTimer -= dt;

		handleDrop();

		switch (state) {
			case Title:
				if (anyStartInput()) {
					score = 0;
					requestLevel(1);
				}
			case Loading:
			case Result:
				resultTimer -= dt;
				if (resultTimer <= 0)
					state = Title;
			case Play:
				updatePlay(dt);
		}
	}

	static function updatePlay(dt:Float) {
		if (IsKeyPressed(KEY_ESCAPE)) {
			saveBestIfNeeded();
			loadToken++;
			state = Title;
			return;
		}

		// View controls.
		var wheel = GetMouseWheelMove();
		if (wheel != 0)
			zoom = Math.max(0.5, Math.min(2.0, zoom * (1 + wheel * 0.1)));
		if (IsKeyDown(KEY_Q))
			rotation -= 90 * dt;
		if (IsKeyDown(KEY_E))
			rotation += 90 * dt;
		if (IsKeyPressed(KEY_R)) {
			zoom = 1;
			rotation = 0;
		}
		updateCamera();

		// Direction from keys and stick.
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
			var sx = GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_X);
			var sy = GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_Y);
			if (Math.sqrt(sx * sx + sy * sy) > 0.2) {
				ix += sx;
				iy += sy;
			}
		}
		var len = Math.sqrt(ix * ix + iy * iy);

		// Click or tap sends the ship to that point in the world.
		var clicked = false;
		var clickPos:Vector2 = null;
		if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT)) {
			clicked = true;
			clickPos = GetMousePosition();
		} else if (IsGestureDetected(GESTURE_TAP) && GetTouchPointCount() > 0) {
			clicked = true;
			clickPos = GetTouchPosition(0);
		}
		if (clicked) {
			var world = GetScreenToWorld2D(clickPos, camera);
			if (world.x >= 0 && world.y >= 0 && world.x <= level.width && world.y <= level.height) {
				hasTarget = true;
				targetX = world.x;
				targetY = world.y;
			}
		}

		if (len > 0) {
			hasTarget = false;
			var scale = (len > 1 ? 1 / len : 1.0) * SPEED * dt;
			moveShip(ix * scale, iy * scale);
		} else if (hasTarget) {
			var tx = targetX - shipX;
			var ty = targetY - shipY;
			var dist = Math.sqrt(tx * tx + ty * ty);
			var step = SPEED * dt;
			if (dist <= step) {
				moveShip(tx, ty);
				hasTarget = false;
			} else {
				var beforeX = shipX, beforeY = shipY;
				moveShip(tx / dist * step, ty / dist * step);
				// Blocked completely: give up rather than push forever.
				if (Math.abs(shipX - beforeX) < 0.001 && Math.abs(shipY - beforeY) < 0.001)
					hasTarget = false;
			}
		}

		// Crystals.
		var shipCircle = new Vector2(shipX, shipY);
		for (i in 0...crystals.length) {
			if (!crystalAlive[i])
				continue;
			var c = crystals[i];
			var dx = c.x - shipX, dy = c.y - shipY;
			var r = CRYSTAL_R + SHIP_SIZE / 2;
			if (dx * dx + dy * dy <= r * r) {
				crystalAlive[i] = false;
				gathered++;
				score++;
				if (coinSound != null)
					PlaySound(coinSound);
				saveBestIfNeeded();
			}
		}
		updateCamera();

		timeLeft -= dt;
		var allGone = gathered >= crystals.length;
		if (timeLeft <= 0 || allGone) {
			if (timeLeft < 0)
				timeLeft = 0;
			saveBestIfNeeded();
			if (levelNumber == 0) {
				finishGame((allGone ? "Field cleared! Score: " : "Time! Score: ") + score);
			} else if (gathered >= level.target) {
				requestLevel(levelNumber + 1);
			} else {
				finishGame("Time! Score: " + score);
			}
		}
	}

	// ---------------------------------------------------------------- draw

	static function drawCentered(text:String, y:Int, size:Int, color:Color) {
		var w = MeasureText(text, size);
		DrawText(text, Std.int((GetScreenWidth() - w) / 2), y, size, color);
	}

	static function draw() {
		BeginDrawing();
		ClearBackground(BLACK);
		var sh = GetScreenHeight();
		switch (state) {
			case Title:
				drawCentered("Drift Field", Std.int(sh / 2) - 90, 60, RAYWHITE);
				drawCentered("Press any key, click or tap to start", Std.int(sh / 2) - 10, 24, LIGHTGRAY);
				drawCentered("Best: " + best, Std.int(sh / 2) + 30, 24, GOLD);
				drawCentered("Drop a level file to play it", Std.int(sh / 2) + 66, 20, GRAY);
			case Loading:
				drawCentered("Loading...", Std.int(sh / 2) - 10, 24, LIGHTGRAY);
			case Result:
				drawCentered(resultText, Std.int(sh / 2) - 20, 40, RAYWHITE);
			case Play:
				drawPlay();
		}
		if (noticeTimer > 0 && noticeText != "")
			drawCentered(noticeText, sh - 60, 20, RED);
		EndDrawing();
	}

	static function drawPlay() {
		var sw = GetScreenWidth();
		var sh = GetScreenHeight();
		var fieldColor = new Color(16, 24, 64, 255);

		BeginMode2D(camera);
		DrawRectangleRec(new Rectangle(0, 0, level.width, level.height), fieldColor);
		for (r in rocks)
			DrawRectangleRec(r, GRAY);
		for (i in 0...crystals.length)
			if (crystalAlive[i])
				DrawCircleV(crystals[i], CRYSTAL_R, new Color(0, 255, 255, 255));
		DrawRectangleLinesEx(new Rectangle(0, 0, level.width, level.height), 2, WHITE);
		if (hasTarget) {
			var s = 6;
			DrawLineV(new Vector2(targetX - s, targetY - s), new Vector2(targetX + s, targetY + s), YELLOW);
			DrawLineV(new Vector2(targetX - s, targetY + s), new Vector2(targetX + s, targetY - s), YELLOW);
		}
		if (shipTex != null)
			DrawTexturePro(shipTex, new Rectangle(0, 0, shipTex.width, shipTex.height),
				new Rectangle(shipX - SHIP_SIZE / 2, shipY - SHIP_SIZE / 2, SHIP_SIZE, SHIP_SIZE), new Vector2(0, 0), 0, WHITE);
		else
			DrawRectangleRec(shipRect(shipX, shipY), WHITE);
		EndMode2D();

		// The map.
		var mapW = 200, mapH = 120;
		var mapX = sw - mapW - 10, mapY = sh - mapH - 10;
		var s = Math.min(mapW / level.width, mapH / level.height);
		var ox = mapX + (mapW - level.width * s) / 2;
		var oy = mapY + (mapH - level.height * s) / 2;
		DrawRectangle(mapX, mapY, mapW, mapH, new Color(0, 0, 0, 200));
		BeginScissorMode(mapX, mapY, mapW, mapH);
		DrawRectangleRec(new Rectangle(ox, oy, level.width * s, level.height * s), fieldColor);
		for (r in rocks)
			DrawRectangleRec(new Rectangle(ox + r.x * s, oy + r.y * s, Math.max(1, r.width * s), Math.max(1, r.height * s)), GRAY);
		for (i in 0...crystals.length)
			if (crystalAlive[i])
				DrawCircleV(new Vector2(ox + crystals[i].x * s, oy + crystals[i].y * s), 1.5, new Color(0, 255, 255, 255));
		DrawCircleV(new Vector2(ox + shipX * s, oy + shipY * s), 3, YELLOW);
		EndScissorMode();
		DrawRectangleLinesEx(new Rectangle(mapX - 1, mapY - 1, mapW + 2, mapH + 2), 1, WHITE);

		// Text.
		var levelName = levelNumber == 0 ? "Custom" : Std.string(levelNumber);
		DrawText("Score: " + score, 10, 10, 20, RAYWHITE);
		DrawText("Level: " + levelName, 10, 34, 20, RAYWHITE);
		DrawText("Crystals: " + gathered + " / " + level.target, 10, 58, 20, RAYWHITE);
		var timeText = "Time: " + Std.int(Math.ceil(timeLeft));
		DrawText(timeText, sw - MeasureText(timeText, 20) - 10, 10, 20, RAYWHITE);
	}
}
