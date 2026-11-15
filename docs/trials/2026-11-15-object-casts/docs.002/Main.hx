import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Device.*;
import helix.raylib.extras.VirtualGamepad.*;

class Main {
	static function main() {
		var maxFrames = -1;
		for (a in Sys.args())
			if (StringTools.startsWith(a, "--frames="))
				maxFrames = Std.parseInt(a.substr(9));

		InitWindow(800, 450, "Paused");
		SetTargetFPS(60);
		EnableTouchEmulation();
		EnableVirtualGamepad(0, {
			left: {enabled: false},
			right: {enabled: false},
			buttons: [
				{button: GAMEPAD_BUTTON_MIDDLE_RIGHT, position: new Vector2(740, 60), radius: 40, label: "II"},
				{button: GAMEPAD_BUTTON_RIGHT_FACE_DOWN, position: new Vector2(740, 390), radius: 40, label: "OK"}
			]
		});

		var bg:Color = {r: 30, g: 32, b: 40};
		var panelColor:Color = {r: 52, g: 58, b: 74};
		var outline:Color = {r: 120, g: 132, b: 160};
		var swatches:Array<Color> = [
			{r: 230, g: 41, b: 55},
			{r: 255, g: 161, b: 0},
			{r: 0, g: 228, b: 48},
			{r: 0, g: 121, b: 241},
			{r: 200, g: 122, b: 255}
		];
		var white = false;
		var frame = 0;
		var quit = false;

		while (!quit && !WindowShouldClose()) {
			if (IsGamepadButtonPressed(0, GAMEPAD_BUTTON_MIDDLE_RIGHT))
				white = !white;
			if (IsGamepadButtonPressed(0, GAMEPAD_BUTTON_RIGHT_FACE_DOWN))
				quit = true;

			BeginDrawing();
			ClearBackground(bg);

			var px = (800 - 420) >> 1;
			var py = (450 - 260) >> 1;
			DrawRectangle(px, py, 420, 260, panelColor);
			DrawRectangleLinesEx(new Rectangle(px, py, 420, 260), 2, white ? WHITE : outline);

			var tw = MeasureText("PAUSED", 40);
			DrawText("PAUSED", px + ((420 - tw) >> 1), py + 30, 40, WHITE);

			var sx = 400 - (5 * 48 + 4 * 16) / 2;
			var sy = 225 - 24;
			for (i in 0...5)
				DrawRectangle(Std.int(sx + i * 64), sy, 48, 48, swatches[i]);

			frame++;
			var last = maxFrames >= 0 && frame >= maxFrames;
			if (last)
				TakeScreenshot("shot.png");
			EndDrawing();
			if (last)
				break;
		}
		CloseWindow();
	}
}
