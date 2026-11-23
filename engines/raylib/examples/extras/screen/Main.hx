import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Screen.*;

/** Fits an 800 x 450 design to the window (`helix.raylib.extras.Screen`): the design white, what the window shows around it grey, a
	red square at its centre, and the mouse followed in the design's pixels. F changes the fit, S the stretch, I the integer scale and B the bars' color: black, blue or clear, showing what is behind the window.
	The `quit_after_frame` option (`--quit_after_frame=60` natively, `?quit_after_frame=60` in a page) quits it after that frame. */
class Main {
	static function main():Void {
		SetConfigFlags(FLAG_WINDOW_TRANSPARENT);
		InitWindow(800, 450, "helix-raylib: the screen fit");
		SetTargetFPS(60);
		var fits = ["keep", "keep width", "keep height", "expand", "cover", "stretch"];
		var fit = SCREEN_FIT_EXPAND,
			stretch = SCREEN_STRETCH_CANVAS,
			integer = false;
		SetScreenFit(800, 450, stretch, fit, integer);
		var visible = new Rectangle(0, 0, 0, 0), mouse = new Vector2(0, 0);
		var angle = 0., bars = 0, barColors = [BLACK, DARKBLUE, BLANK];
		while (!WindowShouldClose()) {
			if (IsKeyPressed(KEY_F))
				fit = fit % SCREEN_FIT_STRETCH + 1;
			if (IsKeyPressed(KEY_S))
				stretch = stretch == SCREEN_STRETCH_CANVAS ? SCREEN_STRETCH_VIEWPORT : SCREEN_STRETCH_CANVAS;
			if (IsKeyPressed(KEY_I))
				integer = !integer;
			if (IsKeyPressed(KEY_B)) {
				bars = (bars + 1) % barColors.length;
				SetScreenFitBarColor(barColors[bars]);
			}
			if (GetScreenFit() != fit || GetScreenStretch() != stretch || IsScreenFitIntegerScale() != integer)
				SetScreenFit(800, 450, stretch, fit, integer);
			GetScreenVisibleArea(visible);
			GetMousePosition(mouse);
			angle += 90 * GetFrameTime();
			BeginDrawing();
			ClearBackground(LIGHTGRAY);
			DrawRectangle(0, 0, GetScreenWidth(), GetScreenHeight(), RAYWHITE);
			DrawRectangle(Std.int(GetScreenWidth() / 2) - 20, Std.int(GetScreenHeight() / 2) - 20, 40, 40, RED);
			DrawRectanglePro(new Rectangle(200, 225, 60, 60), new Vector2(30, 30), angle, DARKBLUE);
			DrawCircleV(mouse, 8, MAROON);
			var line = fits[fit - 1] + (stretch == SCREEN_STRETCH_CANVAS ? ", canvas" : ", viewport") + (integer ? ", integer" : "");
			DrawText(line, Std.int(visible.x) + 10, Std.int(visible.y) + 10, 20, DARKGRAY);
			DrawText("F fit, S stretch, I integer, B bars", Std.int(visible.x) + 10, Std.int(visible.y + visible.height) - 30, 20, DARKGRAY);
			EndDrawing();
		}
		CloseWindow();
	}
}
