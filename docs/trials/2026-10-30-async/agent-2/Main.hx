import helix.ray.Raylib.*;
import helix.ray.Raylib;
import helix.ray.Vector2;
import helix.ray.Color;
import helix.ray.Texture2D;
import helix.ray.Sound;

class Main {
	static inline var SCREEN_W = 960;
	static inline var SCREEN_H = 540;
	static inline var SPEED = 240.0;
	static inline var COIN_R = 12.0;
	static inline var BEST_FILE = "best.txt";

	static inline var STATE_TITLE = 0;
	static inline var STATE_LOADING = 1;
	static inline var STATE_PLAY = 2;
	static inline var STATE_MESSAGE = 3;

	static var state = STATE_TITLE;
	static var player:Texture2D;
	static var coinSound:Sound;
	static var px = 0.0;
	static var py = 0.0;
	static var coins:Array<Vector2> = [];
	static var score = 0;
	static var best = 0;
	static var level = 1;
	static var levelScore = 0;
	static var levelCoins = 5;
	static var levelSeconds = 20.0;
	static var levelTarget = 8;
	static var background:Color = RAYWHITE;
	static var timeLeft = 0.0;
	static var message = "";
	static var messageTime = 0.0;

	static function main() {
		SetConfigFlags(FLAG_WINDOW_RESIZABLE);
		InitWindow(SCREEN_W, SCREEN_H, "Coin Garden");
		InitAudioDevice();
		SetTargetFPS(60);
		SetExitKey(KEY_NULL); // Escape returns to the title instead of closing

		LoadTextureAsync("assets/player.png", function(t:Texture2D) player = t);
		LoadSoundAsync("assets/coin.wav", function(s:Sound) coinSound = s);
		loadBest();

		while (!WindowShouldClose()) {
			update(GetFrameTime());
			draw();
		}

		if (player != null)
			UnloadTexture(player);
		if (coinSound != null)
			UnloadSound(coinSound);
		CloseAudioDevice();
		CloseWindow();
	}

	static function loadBest() {
		LoadFileTextAsync(BEST_FILE, function(text:String) {
			var n = Std.parseInt(StringTools.trim(text));
			if (n != null && n > best)
				best = n;
		});
	}

	static function saveBest() {
		if (score > best) {
			best = score;
			SaveFileText(BEST_FILE, Std.string(best));
		}
	}

	static function anyStartPressed():Bool {
		if (GetKeyPressed() != 0)
			return true;
		if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT) || IsMouseButtonPressed(MOUSE_BUTTON_RIGHT))
			return true;
		if (GetTouchPointCount() > 0 && IsGestureDetected(GESTURE_TAP))
			return true;
		if (GetGamepadButtonPressed() != GAMEPAD_BUTTON_UNKNOWN)
			return true;
		return false;
	}

	static function startGame() {
		score = 0;
		level = 1;
		loadLevel();
	}

	static function loadLevel() {
		state = STATE_LOADING;
		var name = "assets/levels/level" + level + ".txt";
		LoadFileTextAsync(name, function(text:String) {
			parseLevel(text);
			beginLevel();
		}, function(error:String) {
			showMessage("You win! Score: " + score);
		});
	}

	static function parseLevel(text:String) {
		levelCoins = 5;
		levelSeconds = 20;
		levelTarget = 8;
		background = RAYWHITE;
		for (line in text.split("\n")) {
			var l = StringTools.trim(line);
			var eq = l.indexOf("=");
			if (eq < 0)
				continue;
			var key = StringTools.trim(l.substr(0, eq));
			var value = StringTools.trim(l.substr(eq + 1));
			switch (key) {
				case "coins":
					var n = Std.parseInt(value);
					if (n != null)
						levelCoins = n;
				case "seconds":
					var f = Std.parseFloat(value);
					if (!Math.isNaN(f))
						levelSeconds = f;
				case "target":
					var n = Std.parseInt(value);
					if (n != null)
						levelTarget = n;
				case "background":
					var parts = value.split(",");
					if (parts.length >= 3) {
						var r = Std.parseInt(StringTools.trim(parts[0]));
						var g = Std.parseInt(StringTools.trim(parts[1]));
						var b = Std.parseInt(StringTools.trim(parts[2]));
						if (r != null && g != null && b != null)
							background = new Color(r, g, b, 255);
					}
				default:
			}
		}
	}

	static function beginLevel() {
		levelScore = 0;
		timeLeft = levelSeconds;
		px = GetScreenWidth() / 2 - pw() / 2;
		py = GetScreenHeight() / 2 - ph() / 2;
		coins = [];
		for (i in 0...levelCoins)
			coins.push(randomCoin());
		state = STATE_PLAY;
	}

	static function randomCoin():Vector2 {
		var w = GetScreenWidth();
		var h = GetScreenHeight();
		var top = 60;
		for (attempt in 0...20) {
			var c = new Vector2(GetRandomValue(Std.int(COIN_R), w - Std.int(COIN_R)), GetRandomValue(top, h - Std.int(COIN_R)));
			if (!CheckCollisionCircleRec(c, COIN_R * 3, playerRect()))
				return c;
		}
		return new Vector2(GetRandomValue(Std.int(COIN_R), w - Std.int(COIN_R)), GetRandomValue(top, h - Std.int(COIN_R)));
	}

	static function pw():Int {
		return player != null ? player.width : 32;
	}

	static function ph():Int {
		return player != null ? player.height : 32;
	}

	static function playerRect() {
		return new helix.ray.Rectangle(px, py, pw(), ph());
	}

	static function showMessage(text:String) {
		saveBest();
		message = text;
		messageTime = 2.5;
		state = STATE_MESSAGE;
	}

	static function update(dt:Float) {
		switch (state) {
			case STATE_TITLE:
				if (anyStartPressed())
					startGame();
			case STATE_LOADING:
			case STATE_MESSAGE:
				messageTime -= dt;
				if (messageTime <= 0) {
					state = STATE_TITLE;
					// swallow input that happened during the message
				}
			case STATE_PLAY:
				updatePlay(dt);
		}
	}

	static function updatePlay(dt:Float) {
		if (IsKeyPressed(KEY_ESCAPE)) {
			saveBest();
			state = STATE_TITLE;
			return;
		}
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
		for (g in 0...4) {
			if (!IsGamepadAvailable(g))
				continue;
			var ax = GetGamepadAxisMovement(g, GAMEPAD_AXIS_LEFT_X);
			var ay = GetGamepadAxisMovement(g, GAMEPAD_AXIS_LEFT_Y);
			if (Math.abs(ax) > 0.2)
				dx += ax;
			if (Math.abs(ay) > 0.2)
				dy += ay;
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
		if (px < 0)
			px = 0;
		if (py < 0)
			py = 0;
		if (px > w - pw())
			px = w - pw();
		if (py > h - ph())
			py = h - ph();

		var rect = playerRect();
		for (i in 0...coins.length) {
			var c = coins[i];
			// keep coins inside the window after a resize
			if (c.x > w - COIN_R)
				c.x = w - COIN_R;
			if (c.y > h - COIN_R)
				c.y = h - COIN_R;
			if (CheckCollisionCircleRec(c, COIN_R, rect)) {
				if (coinSound != null)
					PlaySound(coinSound);
				score++;
				levelScore++;
				coins[i] = randomCoin();
				if (score > best)
					saveBest();
			}
		}

		timeLeft -= dt;
		if (timeLeft <= 0) {
			timeLeft = 0;
			saveBest();
			if (levelScore >= levelTarget) {
				level++;
				loadLevel();
			} else {
				showMessage("Time! Score: " + score);
			}
		}
	}

	static function centered(text:String, y:Int, size:Int, color:Color) {
		var tw = MeasureText(text, size);
		DrawText(text, Std.int(GetScreenWidth() / 2 - tw / 2), y, size, color);
	}

	static function draw() {
		BeginDrawing();
		var h = GetScreenHeight();
		var w = GetScreenWidth();
		switch (state) {
			case STATE_TITLE:
				ClearBackground(DARKGREEN);
				centered("Coin Garden", Std.int(h / 2 - 70), 48, RAYWHITE);
				centered("Press any key, click or tap to start", Std.int(h / 2), 20, RAYWHITE);
				centered("Best: " + best, Std.int(h / 2 + 40), 20, YELLOW);
			case STATE_LOADING:
				ClearBackground(DARKGREEN);
				centered("Loading level " + level + "...", Std.int(h / 2), 20, RAYWHITE);
			case STATE_MESSAGE:
				ClearBackground(DARKGREEN);
				centered(message, Std.int(h / 2 - 20), 36, RAYWHITE);
			case STATE_PLAY:
				ClearBackground(background);
				for (c in coins) {
					DrawCircleV(c, COIN_R, YELLOW);
					DrawCircleLinesV(c, COIN_R, ORANGE);
				}
				if (player != null)
					DrawTexture(player, Std.int(px), Std.int(py), WHITE);
				DrawText("Score: " + score + "   Level: " + level + "   Target: " + levelTarget, 10, 10, 20, BLACK);
				var t = "Time: " + Math.ceil(timeLeft);
				DrawText(t, w - MeasureText(t, 20) - 10, 10, 20, BLACK);
		}
		EndDrawing();
	}
}
