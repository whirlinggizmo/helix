import helix.raylib.Raylib.*;
import helix.raylib.*;
import helix.raylib.extras.VirtualGamepad.*;
import helix.raylib.extras.Device.*;

class Main {
	static function main() {
		var maxFrames = -1;
		for (a in Sys.args())
			if (StringTools.startsWith(a, "--frames="))
				maxFrames = Std.parseInt(a.substr(9));

		InitWindow(800, 450, "Pause menu");
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

		var outline = new Color(120, 132, 160, 255);
		var white = false;
		var swatches = [
			new Color(230, 41, 55, 255),
			new Color(255, 161, 0, 255),
			new Color(0, 228, 48, 255),
			new Color(0, 121, 241, 255),
			new Color(200, 122, 255, 255)
		];
		var frame = 0;
		var quit = false;
		while (!quit && !WindowShouldClose()) {
			if (IsGamepadButtonPressed(0, GAMEPAD_BUTTON_MIDDLE_RIGHT))
				white = !white;
			if (IsGamepadButtonPressed(0, GAMEPAD_BUTTON_RIGHT_FACE_DOWN))
				quit = true;

			BeginDrawing();
			ClearBackground(new Color(30, 32, 40, 255));
			DrawRectangle(190, 95, 420, 260, new Color(52, 58, 74, 255));
			DrawRectangleLinesEx(new Rectangle(190, 95, 420, 260), 2, white ? WHITE : outline);
			DrawText("PAUSED", 400 - Std.int(MeasureText("PAUSED", 40) / 2), 125, 40, WHITE);
			for (i in 0...5)
				DrawRectangle(248 + i * 64, 201, 48, 48, swatches[i]);
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
