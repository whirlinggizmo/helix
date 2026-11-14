import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.*;
import helix.raylib.extras.Device.*;
import helix.raylib.extras.VirtualGamepad.*;

class Main {
	static inline final W = 800;
	static inline final H = 450;
	static inline final SPEED = 300.0;
	static inline final PAUSE_BUTTON = GAMEPAD_BUTTON_MIDDLE_RIGHT;

	static function main() {
		InitWindow(W, H, "touch controls");
		SetTargetFPS(60);

		// The left mouse button works as a finger, so the phone controls can be tried at a desk.
		EnableTouchEmulation();

		var resetBounds = new Rectangle(W / 2 - 60, H - 60, 120, 40);
		var pauseCenter = new Vector2(W - 50, 50);

		EnableVirtualGamepad(0, {
			blockedBounds: [resetBounds],
			left: {touchZone: new Rectangle(0, 0, W / 2, H), basePlacement: VIRTUAL_STICK_BASE_FLOATING},
			right: {enabled: false},
			buttons: [
				{
					button: PAUSE_BUTTON,
					position: pauseCenter,
					radius: 30,
					label: "II"
				}
			]
		});

		var ball = new Vector2(W / 2, H / 2);
		var paused = false;

		while (!WindowShouldClose()) {
			var dt = GetFrameTime();

			if (IsGamepadAvailable(0) && IsGamepadButtonPressed(0, PAUSE_BUTTON))
				paused = !paused;

			if (!paused && IsGamepadAvailable(0)) {
				var dx = GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_X);
				var dy = GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_Y);
				ball.x += dx * SPEED * dt;
				ball.y += dy * SPEED * dt;
			}

			BeginDrawing();
			ClearBackground(RAYWHITE);

			DrawCircleV(ball, 20, MAROON);

			if (paused)
				DrawText("Paused", Std.int(W / 2 - MeasureText("Paused", 40) / 2), 100, 40, DARKGRAY);

			if (GuiButton(resetBounds, "Reset") != 0)
				ball = new Vector2(W / 2, H / 2);

			EndDrawing(); // the virtual gamepad is drawn here, over everything
		}

		CloseWindow();
	}
}
