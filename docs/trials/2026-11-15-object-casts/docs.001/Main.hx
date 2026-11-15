import helix.raylib.Raylib.*;
import helix.raylib.*;
import helix.raylib.extras.VirtualGamepad.*;
import helix.raylib.extras.Device.*;

class Main {
	static function main() {
		var maxFrames = -1;
		for (a in Sys.args()) {
			if (StringTools.startsWith(a, "--frames="))
				maxFrames = Std.parseInt(a.substr(9));
		}

		InitWindow(800, 450, "Pause menu");
		SetTargetFPS(60);
		EnableTouchEmulation();
		EnableVirtualGamepad(0, {
			left: {enabled: false},
			right: {enabled: false},
			buttons: [
				{button: GAMEPAD_BUTTON_MIDDLE_RIGHT, position: {x: 740, y: 60}, radius: 40, label: "II"},
				{button: GAMEPAD_BUTTON_RIGHT_FACE_DOWN, position: {x: 740, y: 390}, radius: 40, label: "OK"}
			]
		});

		var bg = new Color(30, 32, 40);
		var panelColor = new Color(52, 58, 74);
		var outline = new Color(120, 132, 160);
		var outlineWhite = false;
		var swatches = [
			new Color(230, 41, 55), new Color(255, 161, 0), new Color(0, 228, 48),
			new Color(0, 121, 241), new Color(200, 122, 255)
		];

		var panelX = (800 - 420) >> 1;
		var panelY = (450 - 260) >> 1;
		var frame = 0;
		var quit = false;

		while (!quit && !WindowShouldClose()) {
			if (IsGamepadButtonPressed(0, GAMEPAD_BUTTON_MIDDLE_RIGHT))
				outlineWhite = !outlineWhite;
			if (IsGamepadButtonPressed(0, GAMEPAD_BUTTON_RIGHT_FACE_DOWN))
				quit = true;

			BeginDrawing();
			ClearBackground(bg);
			DrawRectangle(panelX, panelY, 420, 260, panelColor);
			DrawRectangleLinesEx({x: panelX, y: panelY, width: 420, height: 260}, 2, outlineWhite ? WHITE : outline);

			var tw = MeasureText("PAUSED", 40);
			DrawText("PAUSED", panelX + ((420 - tw) >> 1), panelY + 30, 40, WHITE);

			var startX = 400 - (5 * 48 + 4 * 16) / 2;
			for (i in 0...5)
				DrawRectangle(Std.int(startX + i * 64), panelY + 130 - 24, 48, 48, swatches[i]);

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
