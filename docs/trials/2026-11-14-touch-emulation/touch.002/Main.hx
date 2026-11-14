import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.*;
import helix.raylib.extras.Device.*;
import helix.raylib.extras.VirtualGamepad.*;

class Main {
	static function main() {
		InitWindow(800, 450, "touch");
		SetTargetFPS(60);

		// Without a touch screen, the left mouse button works as a finger.
		if (!IsTouchAvailable())
			EnableTouchEmulation();

		var resetBounds = new Rectangle(350, 400, 100, 30);
		var pauseCenter = new Vector2(800 - 40, 40);

		EnableVirtualGamepad(0, {
			blockedBounds: [resetBounds],
			left: {touchZone: new Rectangle(0, 0, 400, 450), basePlacement: VIRTUAL_STICK_BASE_FLOATING},
			right: {enabled: false},
			buttons: [
				{
					button: GAMEPAD_BUTTON_MIDDLE_RIGHT,
					position: pauseCenter,
					radius: 28,
					label: "II"
				}
			]
		});

		var ball = new Vector2(400, 225);
		var paused = false;

		while (!WindowShouldClose()) {
			if (IsGamepadButtonPressed(0, GAMEPAD_BUTTON_MIDDLE_RIGHT))
				paused = !paused;

			if (!paused) {
				var dt = GetFrameTime();
				var x = GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_X);
				var y = GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_Y);
				ball.x += x * 300 * dt;
				ball.y += y * 300 * dt;
			}

			BeginDrawing();
			ClearBackground(RAYWHITE);
			DrawCircleV(ball, 20, MAROON);
			if (paused)
				DrawText("Paused", Std.int(400 - MeasureText("Paused", 40) / 2), 60, 40, DARKGRAY);
			if (GuiButton(resetBounds, "Reset") != 0)
				ball = new Vector2(400, 225);
			EndDrawing();
		}
		CloseWindow();
	}
}
