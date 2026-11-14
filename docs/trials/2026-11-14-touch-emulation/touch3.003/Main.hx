import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.*;
import helix.raylib.extras.Device.*;
import helix.raylib.extras.VirtualGamepad.*;

class Main {
	static inline final SPEED = 300.0;
	static inline final BALL_RADIUS = 20.0;

	static function main() {
		InitWindow(800, 450, "touch controls");
		SetTargetFPS(60);

		// The mouse works as a finger, so the phone controls can be tried at a desk.
		EnableTouchEmulation();

		var resetBounds = new Rectangle(350, 390, 100, 40);
		var pauseButton = GAMEPAD_BUTTON_MIDDLE_RIGHT;

		EnableVirtualGamepad(0, {
			blockedBounds: [resetBounds],
			left: {touchZone: new Rectangle(0, 0, 400, 450)},
			right: {enabled: false},
			buttons: [
				{
					button: pauseButton,
					position: new Vector2(800 - 50, 50),
					radius: 30,
					label: "II"
				}
			]
		});

		var ball = new Vector2(400, 225);
		var paused = false;

		while (!WindowShouldClose()) {
			var dt = GetFrameTime();

			if (IsGamepadAvailable(0) && IsGamepadButtonPressed(0, pauseButton))
				paused = !paused;

			if (!paused && IsGamepadAvailable(0)) {
				var x = GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_X);
				var y = GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_Y);
				ball.x += x * SPEED * dt;
				ball.y += y * SPEED * dt;
				ball.x = Math.max(BALL_RADIUS, Math.min(800 - BALL_RADIUS, ball.x));
				ball.y = Math.max(BALL_RADIUS, Math.min(450 - BALL_RADIUS, ball.y));
			}

			BeginDrawing();
			ClearBackground(RAYWHITE);
			DrawCircleV(ball, BALL_RADIUS, MAROON);
			if (paused)
				DrawText("Paused", 400 - Std.int(MeasureText("Paused", 40) / 2), 100, 40, DARKGRAY);
			if (GuiButton(resetBounds, "Reset") != 0)
				ball = new Vector2(400, 225);
			EndDrawing();
		}
		CloseWindow();
	}
}
