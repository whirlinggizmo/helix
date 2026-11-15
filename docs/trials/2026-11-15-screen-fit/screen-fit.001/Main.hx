import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Screen.*;

class Main {
	static inline var DW = 320;
	static inline var DH = 180;
	static inline var TILE = 16;
	static inline var COLS = 20;
	static inline var ROWS = 11;

	static final fitNames = ["KEEP", "KEEP_WIDTH", "KEEP_HEIGHT", "EXPAND", "STRETCH"];

	static function buildLevel():Array<Array<Int>> {
		var g = [for (r in 0...ROWS) [for (c in 0...COLS) 0]];
		for (c in 0...COLS) {
			g[9][c] = 1;
			g[10][c] = 1;
		}
		for (c in 3...7) g[7][c] = 2;
		for (c in 9...13) g[5][c] = 2;
		for (c in 14...18) g[7][c] = 2;
		return g;
	}

	static function tileColor(t:Int):Color {
		return t == 1 ? new Color(120, 80, 50, 255) : new Color(70, 150, 90, 255);
	}

	static function tileEdge(t:Int):Color {
		return t == 1 ? new Color(70, 45, 28, 255) : new Color(35, 90, 50, 255);
	}

	static function main() {
		SetConfigFlags(FLAG_WINDOW_RESIZABLE);
		InitWindow(1280, 720, "screen fit");
		SetTargetFPS(60);

		var fit = SCREEN_FIT_KEEP;
		var is3D = false;
		SetScreenFit(DW, DH, SCREEN_STRETCH_VIEWPORT, fit, true);

		var grid = buildLevel();
		var safe = new Rectangle(0, 0, DW, DH);

		// 3D: one world unit per tile, row 0 at the top (y = 0), framed at the design's 16:9.
		var designFovy = 40.0;
		var halfH = Math.max(ROWS, COLS / (DW / DH)) / 2;
		var dist = halfH / Math.tan(designFovy / 2 * Math.PI / 180) + 0.5;
		var camera = new Camera3D(new Vector3(COLS / 2, -ROWS / 2 + 0.5, dist), new Vector3(COLS / 2, -ROWS / 2 + 0.5, 0), new Vector3(0, 1, 0),
			designFovy, CAMERA_PERSPECTIVE);

		while (!WindowShouldClose()) {
			if (IsKeyPressed(KEY_TAB)) {
				is3D = !is3D;
				if (is3D)
					SetScreenFit(DW, DH, SCREEN_STRETCH_CANVAS, SCREEN_FIT_EXPAND, false);
				else
					SetScreenFit(DW, DH, SCREEN_STRETCH_VIEWPORT, fit, true);
			}
			if (!is3D && IsKeyPressed(KEY_F)) {
				fit = (fit + 1) % 5;
				SetScreenFit(DW, DH, SCREEN_STRETCH_VIEWPORT, fit, true);
			}

			var t = GetTime();
			var angle = Math.sin(t * 1.5) * 6;

			BeginDrawing();
			ClearBackground(new Color(30, 34, 60, 255));

			if (is3D) {
				camera.fovy = GetScreenFitFovy(designFovy);
				BeginMode3D(camera);
				for (r in 0...ROWS)
					for (c in 0...COLS) {
						var tl = grid[r][c];
						if (tl == 0)
							continue;
						var p = new Vector3(c + 0.5, -r - 0.5 + 1, 0);
						DrawCube(p, 1, 1, 1, tileColor(tl));
						DrawCubeWires(p, 1, 1, 1, tileEdge(tl));
					}
				// the character, 12 x 14 design pixels, standing on the floor
				DrawCube(new Vector3(COLS / 2, -9 + 1 + 14 / 32, 0), 12 / 16, 14 / 16, 12 / 16, ORANGE);
				EndMode3D();
				DrawText("3D  TAB: back", 4, 4, 10, WHITE);
			} else {
				for (r in 0...ROWS)
					for (c in 0...COLS) {
						var tl = grid[r][c];
						if (tl == 0)
							continue;
						DrawRectangle(c * TILE, r * TILE, TILE, TILE, tileColor(tl));
						DrawRectangleLines(c * TILE, r * TILE, TILE, TILE, tileEdge(tl));
					}

				// the character: 12 x 14, feet on the floor (y = 144), turned about its centre
				var cw = 12, ch = 14;
				DrawRectanglePro(new Rectangle(DW / 2, 144 - ch / 2, cw, ch), new Vector2(cw / 2, ch / 2), angle, ORANGE);
				DrawRectangle(Std.int(DW / 2) - 3, 144 - ch + 3, 2, 2, BLACK);

				// the tile under the pointer, in design pixels
				var m = GetMousePosition();
				var tx = Math.floor(m.x / TILE);
				var ty = Math.floor(m.y / TILE);
				if (tx >= 0 && tx < COLS && ty >= 0 && ty < ROWS)
					DrawRectangleLines(tx * TILE, ty * TILE, TILE, TILE, YELLOW);

				// HUD inside the safe area
				GetScreenSafeArea(safe);
				var sx = Std.int(safe.x);
				var sy = Std.int(safe.y);
				var sr = Std.int(safe.x + safe.width);
				DrawText("SCORE 0420", sx + 4, sy + 4, 10, WHITE);
				DrawText(fitNames[fit], sx + 4, sy + 16, 10, YELLOW);
				var hx = sr - 12;
				var hy = sy + 8;
				DrawCircle(hx - 2, hy, 3, RED);
				DrawCircle(hx + 2, hy, 3, RED);
				DrawTriangle(new Vector2(hx - 5, hy + 1), new Vector2(hx, hy + 7), new Vector2(hx + 5, hy + 1), RED);
			}
			EndDrawing();
		}
		CloseWindow();
	}
}
