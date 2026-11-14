import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.extras.Device.*;
import helix.raylib.extras.VirtualGamepad.*;

class Main {
	static function main() {
		InitWindow(800, 450, "touch controls");
		SetTargetFPS(60);

		// A desktop without touch: the left mouse button works as a finger.
		if (!IsTouchAvailable())
			EnableTouchEmulation();

		var resetBounds = new Rectangle(350, 450 - 50, 100, 36);
		EnableVirtualGamepad(0, {
			blockedBounds: [resetBounds],
			left: {touchZone: new Rectangle(0, 0, 400, 450), radius: 60},
			right: {enabled: false},
			buttons: [
				{
					button: GAMEPAD_BUTTON_MIDDLE_RIGHT,
					position: new Vector2(800 - 40, 40),
					radius: 24,
					label: "II"
				}
			]
		});

		var ball = new Vector2(400, 225);
		var paused = false;
		var radius = 20.0;

		while (!WindowShouldClose()) {
			var dt = GetFrameTime();

			if (IsGamepadButtonPressed(0, GAMEPAD_BUTTON_MIDDLE_RIGHT))
				paused = !paused;

			if (!paused) {
				var ax = GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_X);
				var ay = GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_Y);
				ball.x += ax * 300 * dt;
				ball.y += ay * 300 * dt;
				ball.x = Math.max(radius, Math.min(800 - radius, ball.x));
				ball.y = Math.max(radius, Math.min(450 - radius, ball.y));
			}

			BeginDrawing();
			ClearBackground(RAYWHITE);
			DrawCircleV(ball, radius, MAROON);
			if (paused)
				DrawText("Paused", 400 - Std.int(MeasureText("Paused", 40) / 2), 60, 40, DARKGRAY);
			if (GuiButton(resetBounds, "Reset") != 0)
				ball = new Vector2(400, 225);
			EndDrawing();
		}
		CloseWindow();
	}
}
