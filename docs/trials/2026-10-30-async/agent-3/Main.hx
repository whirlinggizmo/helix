import helix.ray.Raylib.*;
import helix.ray.Raymath.*;
import helix.ray.*;

class Main {
	static inline var SPEED = 240.0;
	static inline var COIN_RADIUS = 12.0;
	static inline var BEST_FILE = "best.txt";

	static var state = 0; // 0 title, 1 loading, 2 play, 3 message
	static var player:Texture2D;
	static var coinSound:Sound;
	static var best = 0;
	static var score = 0;
	static var level = 1;
	static var levelCoins = 5;
	static var levelSeconds = 20.0;
	static var levelTarget = 8;
	static var levelScore = 0;
	static var background:Color;
	static var timeLeft = 0.0;
	static var coins:Array<Vector2> = [];
	static var pos:Vector2;
	static var message = "";

	static function main() {
		SetConfigFlags(FLAG_WINDOW_RESIZABLE);
		InitWindow(960, 540, "Coin Garden");
		InitAudioDevice();
		SetTargetFPS(60);
		SetExitKey(KEY_NULL);
		background = RAYWHITE;
		state = 1;
		LoadTextureAsync("assets/player.png", t -> {
			player = t;
			assetLoaded();
		}, e -> {
			TraceLog(LOG_WARNING, "player.png: " + e);
			assetLoaded();
		});
		LoadSoundAsync("assets/coin.wav", s -> {
			coinSound = s;
			assetLoaded();
		}, e -> {
			TraceLog(LOG_WARNING, "coin.wav: " + e);
			assetLoaded();
		});
		LoadFileTextAsync(BEST_FILE, text -> {
			if (text != null)
				best = parseInt(text);
			assetLoaded();
		}, e -> assetLoaded());
		while (!WindowShouldClose()) {
			update();
			draw();
		}
		UnloadTexture(player);
		UnloadSound(coinSound);
		CloseAudioDevice();
		CloseWindow();
	}

	static var pending = 3;

	static function assetLoaded() {
		pending--;
		if (pending == 0)
			state = 0;
	}

	static function parseInt(s:String):Int {
		var v = Std.parseInt(StringTools.trim(s));
		return v == null ? 0 : v;
	}

	static function anyInput():Bool {
		if (GetKeyPressed() != 0)
			return true;
		if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT) || IsMouseButtonPressed(MOUSE_BUTTON_RIGHT))
			return true;
		if (GetGestureDetected() == GESTURE_TAP)
			return true;
		if (GetGamepadButtonPressed() != GAMEPAD_BUTTON_UNKNOWN)
			return true;
		return false;
	}

	static function startLevel(n:Int) {
		level = n;
		var name = "assets/levels/level" + n + ".txt";
		state = 1;
		FileExistsAsync(name, exists -> {
			if (!exists) {
				win();
				return;
			}
			LoadFileTextAsync(name, text -> applyLevel(text), e -> {
				TraceLog(LOG_WARNING, name + ": " + e);
				win();
			});
		});
	}

	static function applyLevel(text:String) {
		for (line in text.split("\n")) {
			var eq = line.indexOf("=");
			if (eq < 0)
				continue;
			var key = StringTools.trim(line.substr(0, eq));
			var value = StringTools.trim(line.substr(eq + 1));
			switch key {
				case "coins":
					levelCoins = parseInt(value);
				case "seconds":
					levelSeconds = Std.parseFloat(value);
				case "target":
					levelTarget = parseInt(value);
				case "background":
					var p = value.split(",");
					if (p.length >= 3)
						background = new Color(parseInt(p[0]), parseInt(p[1]), parseInt(p[2]), 255);
			}
		}
		levelScore = 0;
		timeLeft = levelSeconds;
		pos = new Vector2(GetScreenWidth() / 2, GetScreenHeight() / 2);
		coins = [];
		for (i in 0...levelCoins)
			coins.push(randomCoin());
		state = 2;
	}

	static function win() {
		message = "You win! Score: " + score;
		state = 3;
	}

	static function randomCoin():Vector2 {
		var m = Std.int(COIN_RADIUS) + 4;
		var top = 40;
		for (attempt in 0...20) {
			var c = new Vector2(GetRandomValue(m, GetScreenWidth() - m), GetRandomValue(top + m, GetScreenHeight() - m));
			if (Vector2Distance(c, playerCenter()) > 80)
				return c;
		}
		return new Vector2(GetRandomValue(m, GetScreenWidth() - m), GetRandomValue(top + m, GetScreenHeight() - m));
	}

	static function playerCenter():Vector2 {
		if (pos == null)
			return new Vector2(-1000, -1000);
		return pos;
	}

	static function saveBest() {
		if (score > best) {
			best = score;
			SaveFileText(BEST_FILE, Std.string(best));
		}
	}

	static function update() {
		switch state {
			case 0:
				if (anyInput()) {
					score = 0;
					startLevel(1);
				}
			case 2:
				updatePlay();
			case 3:
				if (anyInput())
					state = 0;
			default:
		}
	}

	static function updatePlay() {
		if (IsKeyPressed(KEY_ESCAPE)) {
			state = 0;
			return;
		}
		var dt = GetFrameTime();
		var dir = new Vector2(0, 0);
		if (IsKeyDown(KEY_RIGHT) || IsKeyDown(KEY_D))
			dir.x += 1;
		if (IsKeyDown(KEY_LEFT) || IsKeyDown(KEY_A))
			dir.x -= 1;
		if (IsKeyDown(KEY_DOWN) || IsKeyDown(KEY_S))
			dir.y += 1;
		if (IsKeyDown(KEY_UP) || IsKeyDown(KEY_W))
			dir.y -= 1;
		if (IsGamepadAvailable(0)) {
			var gx = GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_X);
			var gy = GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_Y);
			if (Math.abs(gx) > 0.2)
				dir.x += gx;
			if (Math.abs(gy) > 0.2)
				dir.y += gy;
		}
		if (Vector2Length(dir) > 1)
			dir = Vector2Normalize(dir);
		pos = Vector2Add(pos, Vector2Scale(dir, SPEED * dt));
		var hw = player != null ? player.width / 2 : 16.0, hh = player != null ? player.height / 2 : 16.0;
		var w = GetScreenWidth(), h = GetScreenHeight();
		pos.x = Clamp(pos.x, hw, w - hw);
		pos.y = Clamp(pos.y, hh, h - hh);

		var radius = Math.max(hw, hh);
		for (i in 0...coins.length) {
			if (CheckCollisionCircles(pos, radius, coins[i], COIN_RADIUS)) {
				if (coinSound != null)
					PlaySound(coinSound);
				score++;
				levelScore++;
				saveBest();
				coins[i] = randomCoin();
			}
		}
		// keep coins inside a resized window
		for (c in coins) {
			c.x = Clamp(c.x, COIN_RADIUS, w - COIN_RADIUS);
			c.y = Clamp(c.y, COIN_RADIUS, h - COIN_RADIUS);
		}

		timeLeft -= dt;
		if (timeLeft <= 0) {
			timeLeft = 0;
			saveBest();
			if (levelScore >= levelTarget) {
				startLevel(level + 1);
			} else {
				message = "Time! Score: " + score;
				state = 3;
			}
		}
	}

	static function centered(text:String, y:Int, size:Int, color:Color) {
		var w = MeasureText(text, size);
		DrawText(text, Std.int((GetScreenWidth() - w) / 2), y, size, color);
	}

	static function draw() {
		BeginDrawing();
		var w = GetScreenWidth(), h = GetScreenHeight();
		switch state {
			case 2:
				ClearBackground(background);
				for (c in coins)
					DrawCircleV(c, COIN_RADIUS, YELLOW);
				if (player != null)
					DrawTexture(player, Std.int(pos.x - player.width / 2), Std.int(pos.y - player.height / 2), WHITE);
				DrawText("Score: " + score + "  Level: " + level + "  Target: " + levelTarget, 10, 10, 20, BLACK);
				var t = "Time: " + Math.ceil(timeLeft);
				DrawText(t, w - MeasureText(t, 20) - 10, 10, 20, BLACK);
			case 3:
				ClearBackground(RAYWHITE);
				centered(message, Std.int(h / 2 - 20), 40, DARKGRAY);
			case 1:
				ClearBackground(RAYWHITE);
				centered("Loading...", Std.int(h / 2 - 10), 20, GRAY);
			default:
				ClearBackground(RAYWHITE);
				centered("Coin Garden", Std.int(h / 2 - 60), 48, DARKGREEN);
				centered("Press any key, click or tap to start", Std.int(h / 2), 20, DARKGRAY);
				centered("Best: " + best, Std.int(h / 2 + 40), 20, GRAY);
		}
		EndDrawing();
	}
}
