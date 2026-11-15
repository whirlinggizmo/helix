import helix.raylib.Raylib.*;
import helix.raylib.*;
import helix.raylib.extras.Device.*;
import helix.raylib.extras.VirtualGamepad.*;

class Main {
	static function main() {
		var maxFrames = -1;
		for (a in Sys.args()) {
			if (StringTools.startsWith(a, "--frames="))
				maxFrames = Std.parseInt(a.substr(9));
		}

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

		var bg = new Color(30, 32, 40, 255);
		var panelColor = new Color(52, 58, 74, 255);
		var outlineColor = new Color(120, 132, 160, 255);
		var swatches = [
			new Color(230, 41, 55, 255),
			new Color(255, 161, 0, 255),
			new Color(0, 228, 48, 255),
			new Color(0, 121, 241, 255),
			new Color(200, 122, 255, 255)
		];
		var outlineWhite = false;
		var frame = 0;
		var quit = false;

		while (!WindowShouldClose() && !quit) {
			if (IsGamepadButtonPressed(0, GAMEPAD_BUTTON_RIGHT_FACE_DOWN))
				quit = true;
			if (IsGamepadButtonPressed(0, GAMEPAD_BUTTON_MIDDLE_RIGHT))
				outlineWhite = !outlineWhite;

			var px = Std.int((800 - 420) / 2);
			var py = Std.int((450 - 260) / 2);

			BeginDrawing();
			ClearBackground(bg);
			DrawRectangle(px, py, 420, 260, panelColor);
			DrawRectangleLinesEx(new Rectangle(px, py, 420, 260), 2, outlineWhite ? WHITE : outlineColor);

			var tw = MeasureText("PAUSED", 40);
			DrawText("PAUSED", px + Std.int((420 - tw) / 2), py + 30, 40, WHITE);

			var total = 5 * 48 + 4 * 16;
			var sx = px + Std.int((420 - total) / 2);
			var sy = py + Std.int((260 - 48) / 2);
			for (i in 0...5)
				DrawRectangle(sx + i * (48 + 16), sy, 48, 48, swatches[i]);

			frame++;
			var last = maxFrames > 0 && frame >= maxFrames;
			if (last)
				TakeScreenshot("shot.png");
			EndDrawing();
			if (last)
				break;
		}
		CloseWindow();
	}
}
