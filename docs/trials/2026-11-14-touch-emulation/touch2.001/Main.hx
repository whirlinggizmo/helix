import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.*;
import helix.raylib.extras.Device.*;
import helix.raylib.extras.VirtualGamepad.*;

class Main {
	static inline final W = 800;
	static inline final H = 450;
	static inline final PAD = 0;
	static inline final SPEED = 300.0;
	static inline final PAUSE_BUTTON = GAMEPAD_BUTTON_MIDDLE_RIGHT;

	static function main() {
		InitWindow(W, H, "touch controls");
		SetTargetFPS(60);

		// On a desktop without touch, the left mouse button works as a finger.
		if (!IsTouchAvailable())
			EnableTouchEmulation();

		var resetBounds = new Rectangle(W / 2 - 60, H - 60, 120, 40);
		EnableVirtualGamepad(PAD, {
			basePlacement: VIRTUAL_STICK_BASE_FLOATING,
			blockedBounds: [resetBounds],
			left: {touchZone: new Rectangle(0, 0, W / 2, H)},
			right: {enabled: false},
			buttons: [
				{
					button: PAUSE_BUTTON,
					position: new Vector2(W - 50, 50),
					radius: 30,
					label: "II"
				}
			]
		});

		var ball = new Vector2(W / 2, H / 2);
		var paused = false;

		while (!WindowShouldClose()) {
			var dt = GetFrameTime();

			if (IsGamepadButtonPressed(PAD, PAUSE_BUTTON))
				paused = !paused;

			if (!paused && IsGamepadAvailable(PAD)) {
				var x = GetGamepadAxisMovement(PAD, GAMEPAD_AXIS_LEFT_X);
				var y = GetGamepadAxisMovement(PAD, GAMEPAD_AXIS_LEFT_Y);
				ball.x += x * SPEED * dt;
				ball.y += y * SPEED * dt;
			}

			BeginDrawing();
			ClearBackground(RAYWHITE);
			DrawCircleV(ball, 20, MAROON);
			if (paused)
				DrawText("Paused", Std.int(W / 2) - Std.int(MeasureText("Paused", 40) / 2), Std.int(H / 2) - 100, 40, DARKGRAY);
			if (GuiButton(resetBounds, "Reset") != 0) {
				ball.x = W / 2;
				ball.y = H / 2;
			}
			EndDrawing();
		}
		CloseWindow();
	}
}
