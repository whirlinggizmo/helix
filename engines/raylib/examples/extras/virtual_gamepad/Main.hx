import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Screen.*;
import helix.raylib.extras.VirtualGamepad.*;

/** Moves a ball with an on-screen stick (`helix.raylib.extras.VirtualGamepad`): a floating stick where a finger lands, full at 80
	pixels, and a pause button at the top right that keeps its finger off the stick. Touch reads as gamepad 0, so a physical gamepad
	moves the ball alike, and the arrow keys too. The program draws the stick itself. The `quit_after_frame` option
	(`--quit_after_frame=60` natively, `?quit_after_frame=60` in a page) quits it after that frame. */
class Main {
	static function main():Void {
		InitWindow(800, 450, "helix-raylib: a virtual gamepad");
		// The 800 x 450 design fitted to any window, a phone's too (helix.raylib.extras.Screen).
		SetScreenFit(800, 450, SCREEN_STRETCH_CANVAS, SCREEN_FIT_EXPAND, false);
		SetTargetFPS(60);
		EnableVirtualGamepad(0, {
			left: {
				basePlacement: VIRTUAL_STICK_BASE_FLOATING,
				radius: 80,
				deadZone: 0.125,
				visible: false
			},
			right: {enabled: false},
			buttons: [
				{
					button: GAMEPAD_BUTTON_MIDDLE_RIGHT,
					position: new Vector2(740, 60),
					radius: 36,
					label: "II"
				}
			]
		});
		var ball = new Vector2(400, 225);
		var paused = false;
		while (!WindowShouldClose()) {
			if (IsGamepadButtonPressed(0, GAMEPAD_BUTTON_MIDDLE_RIGHT) || IsKeyPressed(KEY_P))
				paused = !paused;
			if (!paused) {
				var x = GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_X) + (IsKeyDown(KEY_RIGHT) ? 1 : 0) - (IsKeyDown(KEY_LEFT) ? 1 : 0);
				var y = GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_Y) + (IsKeyDown(KEY_DOWN) ? 1 : 0) - (IsKeyDown(KEY_UP) ? 1 : 0);
				ball.x = Math.max(20, Math.min(780, ball.x + x * 300 * GetFrameTime()));
				ball.y = Math.max(20, Math.min(430, ball.y + y * 300 * GetFrameTime()));
			}
			BeginDrawing();
			ClearBackground(RAYWHITE);
			DrawCircleV(ball, 20, paused ? GRAY : MAROON);
			if (IsVirtualStickHeld(0, VIRTUAL_STICK_LEFT)) {
				DrawCircleLinesV(GetVirtualStickBase(0, VIRTUAL_STICK_LEFT), 80, DARKGRAY);
				DrawCircleV(GetVirtualStickKnob(0, VIRTUAL_STICK_LEFT), 24, Fade(DARKGRAY, 0.6));
			}
			DrawText(IsGamepadVirtual(0) ? "touch: drag anywhere" : "touch the screen, or use the arrow keys", 10, 10, 20, DARKGRAY);
			if (paused)
				DrawText("paused", 360, 210, 30, GRAY);
			EndDrawing();
		}
		CloseWindow();
	}
}
