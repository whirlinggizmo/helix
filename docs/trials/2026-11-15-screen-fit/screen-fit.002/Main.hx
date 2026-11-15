import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Screen.*;

class Main {
	static inline var DW = 320;
	static inline var DH = 180;
	static inline var COLS = 20;
	static inline var ROWS = 11;
	static inline var TILE = 16;
	static inline var FOVY = 40.0;

	// '#' = solid tile
	static final LEVEL:Array<String> = [
		"....................",
		"....................",
		"....................",
		"....................",
		"....................",
		"......#####.........",
		"....................",
		".....##........###..",
		"....................",
		"####################",
		"####################",
	];

	static final FIT_NAMES = ["KEEP", "KEEP_WIDTH", "KEEP_HEIGHT", "EXPAND", "STRETCH"];
	static final FITS = [SCREEN_FIT_KEEP, SCREEN_FIT_KEEP_WIDTH, SCREEN_FIT_KEEP_HEIGHT, SCREEN_FIT_EXPAND, SCREEN_FIT_STRETCH];

	static var fitIndex = 0;
	static var integerScale = true;
	static var view3D = false;

	static function solid(c:Int, r:Int):Bool {
		return c >= 0 && c < COLS && r >= 0 && r < ROWS && LEVEL[r].charAt(c) == "#";
	}

	static function applyFit():Void {
		if (view3D) {
			// no bars, whole level, more world on the longer side; fractional scale so nothing is left over as bars
			SetScreenFit(DW, DH, SCREEN_STRETCH_CANVAS, SCREEN_FIT_EXPAND, false);
		} else {
			SetScreenFit(DW, DH, SCREEN_STRETCH_VIEWPORT, FITS[fitIndex], integerScale);
		}
	}

	static function fitName():String {
		return FIT_NAMES[fitIndex] + (FITS[fitIndex] == SCREEN_FIT_STRETCH ? "" : (integerScale ? " INT" : " FREE"));
	}

	static function darker(c:Color):Color {
		return new Color(Std.int(c.r * 0.6), Std.int(c.g * 0.6), Std.int(c.b * 0.6), 255);
	}

	static function drawTile(x:Int, y:Int, c:Color):Void {
		DrawRectangle(x, y, TILE, TILE, darker(c));
		DrawRectangle(x + 1, y + 1, TILE - 2, TILE - 2, c);
	}

	static function drawHeart(x:Int, y:Int):Void {
		// 11 x 10 design-pixel heart whose top-left is (x, y)
		DrawCircle(x + 3, y + 3, 3, RED);
		DrawCircle(x + 7, y + 3, 3, RED);
		DrawTriangle(new Vector2(x, y + 4), new Vector2(x + 5, y + 10), new Vector2(x + 10, y + 4), RED);
	}

	static function draw2D(offX:Int, offY:Int, t:Float):Void {
		ClearBackground(new Color(40, 44, 70, 255));
		var tileColor = new Color(110, 170, 90, 255);
		var platColor = new Color(190, 140, 80, 255);
		for (r in 0...ROWS)
			for (c in 0...COLS)
				if (solid(c, r))
					drawTile(offX + c * TILE, offY + r * TILE, r >= ROWS - 2 ? tileColor : platColor);

		// character: 12 x 14, standing on the floor (top of row 9), rotated about its center
		var angle = Math.sin(t * 0.8) * 8.0;
		var cx = offX + 160.0;
		var cy = offY + 9 * TILE - 7.0;
		DrawRectanglePro(new Rectangle(cx, cy, 12, 14), new Vector2(6, 7), angle, new Color(230, 90, 90, 255));
		DrawRectanglePro(new Rectangle(cx, cy - 3, 6, 4), new Vector2(3, 5), angle, WHITE);

		// tile under the mouse, in design pixels
		var m = GetMousePosition();
		var tc = Math.floor((m.x - offX) / TILE);
		var tr = Math.floor((m.y - offY) / TILE);
		if (tc >= 0 && tc < COLS && tr >= 0 && tr < ROWS)
			DrawRectangleLines(offX + tc * TILE, offY + tr * TILE, TILE, TILE, YELLOW);

		// HUD inside the safe area
		var s = GetScreenSafeArea();
		DrawText("SCORE 0420", Std.int(s.x) + 4, Std.int(s.y) + 4, 10, WHITE);
		DrawText(fitName(), Std.int(s.x) + 4, Std.int(s.y) + 16, 10, LIGHTGRAY);
		drawHeart(Std.int(s.x + s.width) - 15, Std.int(s.y) + 4);
	}

	static function draw3D():Void {
		ClearBackground(new Color(40, 44, 70, 255));
		// one unit per tile; level spans x 0..20, y 0..11 (y up), centered on its middle
		// the level is 20 x 11 but the design is 16:9 (20 x 11.25): frame the full design height
		var dist = (DH / TILE) / 2.0 / Math.tan(FOVY * 0.5 * Math.PI / 180.0);
		var camera = new Camera3D(
			new Vector3(COLS / 2.0, ROWS / 2.0, dist),
			new Vector3(COLS / 2.0, ROWS / 2.0, 0),
			new Vector3(0, 1, 0),
			GetScreenFitFovy(FOVY),
			CAMERA_PERSPECTIVE);
		BeginMode3D(camera);
		for (r in 0...ROWS)
			for (c in 0...COLS)
				if (solid(c, r)) {
					var p = new Vector3(c + 0.5, ROWS - r - 0.5, 0);
					var col = r >= ROWS - 2 ? new Color(110, 170, 90, 255) : new Color(190, 140, 80, 255);
					DrawCube(p, 1, 1, 1, col);
					DrawCubeWires(p, 1, 1, 1, darker(col));
				}
		DrawCube(new Vector3(COLS / 2.0, ROWS - 9 + 14.0 / TILE / 2, 0), 12.0 / TILE, 14.0 / TILE, 12.0 / TILE, new Color(230, 90, 90, 255));
		EndMode3D();
		var s = GetScreenSafeArea();
		DrawText("SCORE 0420", Std.int(s.x) + 4, Std.int(s.y) + 4, 20, WHITE);
		DrawText("3D", Std.int(s.x) + 4, Std.int(s.y) + 30, 20, LIGHTGRAY);
	}

	static function main():Void {
		SetConfigFlags(FLAG_WINDOW_RESIZABLE);
		InitWindow(1280, 720, "pixel art");
		SetTargetFPS(60);
		applyFit();

		while (!WindowShouldClose()) {
			if (IsKeyPressed(KEY_TAB)) {
				view3D = !view3D;
				applyFit();
			}
			if (!view3D && IsKeyPressed(KEY_F)) {
				fitIndex++;
				if (fitIndex >= FITS.length) {
					fitIndex = 0;
					integerScale = !integerScale;
				}
				applyFit();
			}

			BeginDrawing();
			ClearBackground(BLACK);
			if (view3D) {
				draw3D();
			} else {
				// center the level in whatever design the fit grows
				var offX = Std.int((GetScreenWidth() - COLS * TILE) / 2);
				var offY = Std.int((GetScreenHeight() - ROWS * TILE) / 2);
				draw2D(offX, offY, GetTime());
			}
			EndDrawing();
		}
		CloseWindow();
	}
}
