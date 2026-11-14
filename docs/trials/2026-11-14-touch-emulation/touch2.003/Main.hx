import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.*;
import helix.raylib.extras.Device.*;
import helix.raylib.extras.VirtualGamepad.*;
import helix.raylib.extras.VirtualGamepadOptions;
import helix.raylib.extras.VirtualButtonOptions;
import helix.raylib.extras.VirtualStickOptions;

class Main {
	static inline final W = 800;
	static inline final H = 450;
	static inline final SPEED = 300.0;
	static inline final BALL_RADIUS = 20.0;
	static inline final PAD = 0;
	static inline final PAUSE_RADIUS = 28.0;

	static function main():Void {
		InitWindow(W, H, "touch controls");
		SetTargetFPS(60);

		// Without touch, a press of the mouse is a finger.
		if (!IsTouchAvailable())
			EnableTouchEmulation();

		var resetBounds = new Rectangle(W / 2 - 50, H - 50, 100, 36);
		var pausePos = new Vector2(W - PAUSE_RADIUS - 16, PAUSE_RADIUS + 16);

		var options:VirtualGamepadOptions = {
			basePlacement: VIRTUAL_STICK_BASE_FLOATING,
			blockedBounds: [resetBounds],
			left: {touchZone: new Rectangle(0, 0, W / 2, H)},
			right: {enabled: false},
			buttons: [
				{
					button: GAMEPAD_BUTTON_MIDDLE_RIGHT,
					position: pausePos,
					radius: PAUSE_RADIUS,
					label: "II"
				}
			]
		};
		EnableVirtualGamepad(PAD, options);

		var ball = new Vector2(W / 2, H / 2);
		var paused = false;

		while (!WindowShouldClose()) {
			var dt = GetFrameTime();

			if (IsGamepadButtonPressed(PAD, GAMEPAD_BUTTON_MIDDLE_RIGHT))
				paused = !paused;

			if (!paused && IsGamepadAvailable(PAD)) {
				var x = GetGamepadAxisMovement(PAD, GAMEPAD_AXIS_LEFT_X);
				var y = GetGamepadAxisMovement(PAD, GAMEPAD_AXIS_LEFT_Y);
				var len = Math.sqrt(x * x + y * y);
				if (len > 1) {
					x /= len;
					y /= len;
				}
				ball.x += x * SPEED * dt;
				ball.y += y * SPEED * dt;
				ball.x = Math.max(BALL_RADIUS, Math.min(W - BALL_RADIUS, ball.x));
				ball.y = Math.max(BALL_RADIUS, Math.min(H - BALL_RADIUS, ball.y));
			}

			BeginDrawing();
			ClearBackground(RAYWHITE);
			DrawCircleV(ball, BALL_RADIUS, MAROON);
			if (paused)
				DrawText("Paused", Std.int(W / 2 - MeasureText("Paused", 40) / 2), 20, 40, DARKGRAY);
			if (GuiButton(resetBounds, "Reset") != 0)
				ball = new Vector2(W / 2, H / 2);
			EndDrawing();
		}

		DisableVirtualGamepad(PAD);
		CloseWindow();
	}
}
