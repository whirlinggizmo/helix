import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.*;
import helix.raylib.extras.Device.*;
import helix.raylib.extras.VirtualGamepad.*;

class Main {
	static inline final W = 800;
	static inline final H = 450;
	static inline final SPEED = 300.0;
	static inline final BALL_RADIUS = 20.0;

	static function main() {
		InitWindow(W, H, "touch.001");
		SetTargetFPS(60);

		// On a desktop with no touch screen the left mouse button works as a finger.
		if (!IsTouchAvailable())
			EnableTouchEmulation();

		var resetBounds = new Rectangle(W / 2 - 60, H - 50, 120, 36);
		var pauseCenter = new Vector2(W - 50, 50);

		EnableVirtualGamepad(0, {
			basePlacement: VIRTUAL_STICK_BASE_FLOATING,
			blockedBounds: [resetBounds],
			left: {touchZone: new Rectangle(0, 0, W / 2, H)},
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

		var ball = new Vector2(W / 2, H / 2);
		var paused = false;

		while (!WindowShouldClose()) {
			var dt = GetFrameTime();

			if (IsGamepadButtonPressed(0, GAMEPAD_BUTTON_MIDDLE_RIGHT))
				paused = !paused;

			if (!paused) {
				var ax = GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_X);
				var ay = GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_Y);
				// Keep a diagonal push within the stick's full speed.
				var len = Math.sqrt(ax * ax + ay * ay);
				if (len > 1) {
					ax /= len;
					ay /= len;
				}
				ball.x = Math.max(BALL_RADIUS, Math.min(W - BALL_RADIUS, ball.x + ax * SPEED * dt));
				ball.y = Math.max(BALL_RADIUS, Math.min(H - BALL_RADIUS, ball.y + ay * SPEED * dt));
			}

			BeginDrawing();
			ClearBackground(RAYWHITE);
			DrawCircleV(ball, BALL_RADIUS, MAROON);
			if (paused)
				DrawText("Paused", Std.int(W / 2 - MeasureText("Paused", 40) / 2), 60, 40, DARKGRAY);
			if (GuiButton(resetBounds, "Reset") != 0) {
				ball.x = W / 2;
				ball.y = H / 2;
			}
			EndDrawing(); // the virtual gamepad is drawn here, over the frame
		}
		CloseWindow();
	}
}
