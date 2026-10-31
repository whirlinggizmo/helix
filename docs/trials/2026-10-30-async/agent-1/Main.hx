import helix.ray.Raylib.*;
import helix.ray.Texture2D;
import helix.ray.Sound;
import helix.ray.Vector2;
import helix.ray.Color;

class Main {
	static inline var SCREEN_W = 960;
	static inline var SCREEN_H = 540;
	static inline var SPEED = 240.0;
	static inline var COIN_R = 12.0;
	static inline var BEST_FILE = "best.txt";

	static var state = 0; // 0 title, 1 play, 2 message
	static var player:Texture2D;
	static var coinSound:Sound;
	static var px = 0.0;
	static var py = 0.0;
	static var coinsX:Array<Float> = [];
	static var coinsY:Array<Float> = [];
	static var score = 0;
	static var levelScore = 0;
	static var level = 1;
	static var levelCoins = 5;
	static var levelSeconds = 20.0;
	static var levelTarget = 8;
	static var background:Color = RAYWHITE;
	static var timeLeft = 0.0;
	static var best = 0;
	static var message = "";
	static var messageTime = 0.0;
	static var pending = 0;

	static function main() {
		SetConfigFlags(FLAG_WINDOW_RESIZABLE);
		InitWindow(SCREEN_W, SCREEN_H, "Coin Garden");
		InitAudioDevice();
		SetTargetFPS(60);
		SetExitKey(KEY_NULL); // Escape returns to the title instead of closing

		pending = 3;
		LoadTextureAsync("assets/player.png", t -> {
			player = t;
			pending--;
		}, e -> {
			TraceLog(LOG_WARNING, "player.png: " + e);
			pending--;
		});
		LoadSoundAsync("assets/coin.wav", s -> {
			coinSound = s;
			pending--;
		}, e -> {
			TraceLog(LOG_WARNING, "coin.wav: " + e);
			pending--;
		});
		FileExistsAsync(BEST_FILE, exists -> {
			if (!exists) {
				pending--;
				return;
			}
			LoadFileTextAsync(BEST_FILE, t -> {
				var v = Std.parseInt(StringTools.trim(t));
				if (v != null)
					best = v;
				pending--;
			}, e -> pending--);
		});

		while (!WindowShouldClose()) {
			update();
			draw();
		}

		if (player != null)
			UnloadTexture(player);
		if (coinSound != null)
			UnloadSound(coinSound);
		CloseAudioDevice();
		CloseWindow();
	}

	static function anyStart():Bool {
		if (GetKeyPressed() != 0)
			return true;
		if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT) || IsMouseButtonPressed(MOUSE_BUTTON_RIGHT))
			return true;
		if (IsGestureDetected(GESTURE_TAP))
			return true;
		if (GetGamepadButtonPressed() != GAMEPAD_BUTTON_UNKNOWN)
			return true;
		return false;
	}

	static function update() {
		switch state {
			case 0:
				if (pending <= 0 && anyStart()) {
					score = 0;
					startLevel(1);
				}
			case 1:
				if (IsKeyPressed(KEY_ESCAPE)) {
					state = 0;
					return;
				}
				updatePlay();
			case 2:
				messageTime -= GetFrameTime();
				if (messageTime <= 0 || (messageTime < 2 && anyStart()))
					state = 0;
			case _:
		}
	}

	static function startLevel(n:Int) {
		var name = "assets/levels/level" + n + ".txt";
		state = 3; // loading
		FileExistsAsync(name, exists -> {
			if (!exists) {
				showMessage("You win! Score: " + score);
				return;
			}
			LoadFileTextAsync(name, text -> beginLevel(n, text), e -> {
				TraceLog(LOG_WARNING, name + ": " + e);
				showMessage("You win! Score: " + score);
			});
		});
	}

	static function showMessage(m:String) {
		message = m;
		messageTime = 3;
		state = 2;
	}

	static function beginLevel(n:Int, text:String) {
		levelCoins = 5;
		levelSeconds = 20;
		levelTarget = 8;
		background = RAYWHITE;
		var lines:Array<String> = text.split("\n");
		for (line in lines) {
			var l = StringTools.trim(line);
			var eq = l.indexOf("=");
			if (eq < 0)
				continue;
			var k = StringTools.trim(l.substr(0, eq));
			var v = StringTools.trim(l.substr(eq + 1));
			switch k {
				case "coins":
					levelCoins = Std.parseInt(v);
				case "seconds":
					levelSeconds = Std.parseFloat(v);
				case "target":
					levelTarget = Std.parseInt(v);
				case "background":
					var p = v.split(",");
					background = new Color(Std.parseInt(p[0]), Std.parseInt(p[1]), Std.parseInt(p[2]), 255);
			}
		}
		level = n;
		levelScore = 0;
		timeLeft = levelSeconds;
		px = GetScreenWidth() / 2;
		py = GetScreenHeight() / 2;
		coinsX = [];
		coinsY = [];
		for (i in 0...levelCoins) {
			coinsX.push(0);
			coinsY.push(0);
			placeCoin(i);
		}
		state = 1;
	}

	static function placeCoin(i:Int) {
		var w = GetScreenWidth();
		var h = GetScreenHeight();
		var top = 40;
		for (tries in 0...20) {
			coinsX[i] = GetRandomValue(Std.int(COIN_R), w - Std.int(COIN_R));
			coinsY[i] = GetRandomValue(top + Std.int(COIN_R), h - Std.int(COIN_R));
			var dx = coinsX[i] - px;
			var dy = coinsY[i] - py;
			if (dx * dx + dy * dy > 80 * 80)
				break;
		}
	}

	static function saveBest() {
		if (score > best) {
			best = score;
			SaveFileText(BEST_FILE, Std.string(best));
		}
	}

	static function updatePlay() {
		var dt = GetFrameTime();
		var dx = 0.0;
		var dy = 0.0;
		if (IsKeyDown(KEY_LEFT) || IsKeyDown(KEY_A))
			dx -= 1;
		if (IsKeyDown(KEY_RIGHT) || IsKeyDown(KEY_D))
			dx += 1;
		if (IsKeyDown(KEY_UP) || IsKeyDown(KEY_W))
			dy -= 1;
		if (IsKeyDown(KEY_DOWN) || IsKeyDown(KEY_S))
			dy += 1;
		if (IsGamepadAvailable(0)) {
			var ax = GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_X);
			var ay = GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_Y);
			if (Math.abs(ax) > 0.2 || Math.abs(ay) > 0.2) {
				dx += ax;
				dy += ay;
			}
		}
		var len = Math.sqrt(dx * dx + dy * dy);
		if (len > 1) {
			dx /= len;
			dy /= len;
		}
		px += dx * SPEED * dt;
		py += dy * SPEED * dt;

		var w = GetScreenWidth();
		var h = GetScreenHeight();
		var pw = player != null ? player.width : 32;
		var ph = player != null ? player.height : 32;
		var hw = pw / 2;
		var hh = ph / 2;
		if (px < hw)
			px = hw;
		if (px > w - hw)
			px = w - hw;
		if (py < hh)
			py = hh;
		if (py > h - hh)
			py = h - hh;

		var pr = Math.min(pw, ph) / 2;
		for (i in 0...coinsX.length) {
			// keep coins inside the window when it shrinks
			if (coinsX[i] > w - COIN_R || coinsY[i] > h - COIN_R)
				placeCoin(i);
			if (CheckCollisionCircles(new Vector2(px, py), pr, new Vector2(coinsX[i], coinsY[i]), COIN_R)) {
				if (coinSound != null)
					PlaySound(coinSound);
				score++;
				levelScore++;
				saveBest();
				placeCoin(i);
			}
		}

		timeLeft -= dt;
		if (timeLeft <= 0) {
			timeLeft = 0;
			saveBest();
			if (levelScore >= levelTarget) {
				startLevel(level + 1);
			} else {
				showMessage("Time! Score: " + score);
			}
		}
	}

	static function centered(text:String, y:Int, size:Int, color:Color) {
		var tw = MeasureText(text, size);
		DrawText(text, Std.int((GetScreenWidth() - tw) / 2), y, size, color);
	}

	static function draw() {
		BeginDrawing();
		var w = GetScreenWidth();
		var h = GetScreenHeight();
		switch state {
			case 0:
				ClearBackground(DARKGREEN);
				centered("Coin Garden", Std.int(h / 2) - 70, 48, RAYWHITE);
				centered(pending > 0 ? "Loading..." : "Press any key, click or tap to start", Std.int(h / 2), 24, RAYWHITE);
				centered("Best: " + best, Std.int(h / 2) + 40, 24, YELLOW);
			case 1:
				ClearBackground(background);
				for (i in 0...coinsX.length)
					DrawCircleV(new Vector2(coinsX[i], coinsY[i]), COIN_R, YELLOW);
				if (player != null)
					DrawTexture(player, Std.int(px - player.width / 2), Std.int(py - player.height / 2), WHITE);
				else
					DrawRectangle(Std.int(px - 16), Std.int(py - 16), 32, 32, BLUE);
				DrawText("Score: " + score + "  Level: " + level + "  Target: " + levelTarget, 10, 10, 20, BLACK);
				var t = "Time: " + Math.ceil(timeLeft);
				DrawText(t, w - MeasureText(t, 20) - 10, 10, 20, BLACK);
			case 3:
				ClearBackground(DARKGREEN);
				centered("Loading...", Std.int(h / 2) - 12, 24, RAYWHITE);
			case _:
				ClearBackground(DARKGREEN);
				centered(message, Std.int(h / 2) - 20, 40, RAYWHITE);
		}
		EndDrawing();
	}
}
