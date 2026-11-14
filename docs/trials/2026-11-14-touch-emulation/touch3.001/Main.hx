import helix.raylib.Raylib.*;
import helix.raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.extras.Device.*;
import helix.raylib.extras.VirtualGamepad.*;

class Main {
	static inline final W = 800;
	static inline final H = 450;
	static inline final SPEED = 300.0;
	static inline final PAUSE_RADIUS = 28.0;

	static function main() {
		InitWindow(W, H, "touch controls");
		SetTargetFPS(60);

		// The left mouse button works as a finger, so the phone controls can be tried at a desk.
		EnableTouchEmulation();

		var resetBounds = new Rectangle(W / 2 - 60, H - 60, 120, 40);
		var pauseCenter = new Vector2(W - 20 - PAUSE_RADIUS - 10, 20 + PAUSE_RADIUS + 10);

		EnableVirtualGamepad(0, {
			// The reset button stays a free finger, so raygui sees it and the stick doesn't take it.
			blockedBounds: [resetBounds],
			left: {touchZone: new Rectangle(0, 0, W / 2, H)},
			right: {enabled: false},
			buttons: [
				{
					button: GAMEPAD_BUTTON_MIDDLE_RIGHT,
					position: pauseCenter,
					radius: PAUSE_RADIUS,
					label: "II"
				}
			]
		});

		var ball = new Vector2(W / 2, H / 2);
		var paused = false;

		while (!WindowShouldClose()) {
			var dt = GetFrameTime();

			if (IsGamepadButtonPressed(0, GAMEPAD_BUTTON_MIDDLE_RIGHT))
				paused = !paused;

			if (!paused) {
				var ax = GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_X);
				var ay = GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_Y);
				ball.x += ax * SPEED * dt;
				ball.y += ay * SPEED * dt;
			}

			BeginDrawing();
			ClearBackground(RAYWHITE);
			DrawCircleV(ball, 20, MAROON);
			if (paused)
				DrawText("Paused", Std.int(W / 2 - MeasureText("Paused", 40) / 2), 60, 40, DARKGRAY);
			if (GuiButton(resetBounds, "Reset") != 0)
				ball = new Vector2(W / 2, H / 2);
			EndDrawing();
		}
		CloseWindow();
	}
}
