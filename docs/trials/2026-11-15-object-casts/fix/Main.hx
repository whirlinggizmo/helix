import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Device.*;
import helix.raylib.extras.VirtualButtonOptions;
import helix.raylib.extras.VirtualGamepad.*;

class Main {
	static function main():Void {
		var frames = 0;
		for (a in Sys.args())
			if (StringTools.startsWith(a, "--frames="))
				frames = Std.parseInt(a.substr(9));

		InitWindow(800, 450, "pause");
		SetTargetFPS(60);
		EnableTouchEmulation();

		var background:Color = cast {r: 30, g: 32, b: 40, a: 255};
		var panelColor:Color = cast {r: 52, g: 58, b: 74, a: 255};
		var outline:Color = cast {r: 120, g: 132, b: 160, a: 255};
		var swatches:Array<Color> = [
			cast {r: 230, g: 41, b: 55, a: 255},
			cast {r: 255, g: 161, b: 0, a: 255},
			cast {r: 0, g: 228, b: 48, a: 255},
			cast {r: 0, g: 121, b: 241, a: 255},
			cast {r: 200, g: 122, b: 255, a: 255}
		];

		var buttons:Array<VirtualButtonOptions> = [];
		buttons.push(cast {button: GAMEPAD_BUTTON_MIDDLE_RIGHT, label: "II", radius: 40, position: new Vector2(740, 60)});
		buttons.push(cast {button: GAMEPAD_BUTTON_RIGHT_FACE_DOWN, label: "OK", radius: 40, position: new Vector2(740, 390)});
		EnableVirtualGamepad(0, {buttons: buttons});

		var whiteOutline = false;
		var frame = 0;
		while (!WindowShouldClose()) {
			if (IsGamepadButtonPressed(0, GAMEPAD_BUTTON_RIGHT_FACE_DOWN))
				break;
			if (IsGamepadButtonPressed(0, GAMEPAD_BUTTON_MIDDLE_RIGHT))
				whiteOutline = !whiteOutline;
			frame++;

			BeginDrawing();
			ClearBackground(background);
			var panel = new Rectangle(190, 95, 420, 260);
			DrawRectangleRec(panel, panelColor);
			DrawRectangleLinesEx(panel, 2, whiteOutline ? WHITE : outline);
			var title = "PAUSED";
			DrawText(title, Std.int(panel.x + (panel.width - MeasureText(title, 40)) / 2), Std.int(panel.y + 30), 40, WHITE);
			var row = 5 * 48 + 4 * 16;
			for (i => c in swatches)
				DrawRectangle(Std.int(panel.x + (panel.width - row) / 2 + i * 64), Std.int(panel.y + (panel.height - 48) / 2), 48, 48, c);
			if (frames > 0 && frame == frames)
				TakeScreenshot("shot.png");
			EndDrawing();
			if (frames > 0 && frame >= frames)
				break;
		}
		CloseWindow();
	}
}
