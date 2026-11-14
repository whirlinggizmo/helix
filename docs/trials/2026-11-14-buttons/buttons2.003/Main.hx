import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.extras.GuiSkin;
import helix.raylib.extras.GuiSkins.*;

class Main {
	static function main() {
		InitWindow(800, 450, "Main menu");
		SetTargetFPS(60);

		var sheet:Texture2D = null;
		var quitSheet:Texture2D = null;
		var icons:Texture2D = null;
		var soundOn:Texture2D = null;
		var soundOnPressed:Texture2D = null;
		var soundOff:Texture2D = null;
		var soundOffPressed:Texture2D = null;
		var loaded = 0;
		LoadTextureAsync("assets/button.png", t -> { sheet = t; loaded++; });
		LoadTextureAsync("assets/button_quit.png", t -> { quitSheet = t; loaded++; });
		LoadTextureAsync("assets/icons.png", t -> { icons = t; loaded++; });
		LoadTextureAsync("assets/sound_on.png", t -> { soundOn = t; loaded++; });
		LoadTextureAsync("assets/sound_on_pressed.png", t -> { soundOnPressed = t; loaded++; });
		LoadTextureAsync("assets/sound_off.png", t -> { soundOff = t; loaded++; });
		LoadTextureAsync("assets/sound_off_pressed.png", t -> { soundOffPressed = t; loaded++; });

		var setup = false;
		var buttonSkin:GuiSkin = null;
		var quitSkin:GuiSkin = null;
		var played = false;
		var soundOnFlag = true;
		var init = () -> {
		buttonSkin = GuiSkinFromSheet(sheet, 192, 64, 16, 16, 16, 20);
		buttonSkin.pressedTextOffset = new Vector2(0, 4);
		quitSkin = GuiSkinFromSheet(quitSheet, 192, 64, 16, 16, 16, 20);
		quitSkin.focusedTextOffset = new Vector2(0, -2);
		quitSkin.pressedTextOffset = new Vector2(0, 4);
		GuiSetSkin(BUTTON, GUI_SKIN_BASE, buttonSkin);

		GuiSetIconTexture(ICON_229, icons, new Rectangle(0, 0, 24, 24));
		GuiSetIconTexture(ICON_230, icons, new Rectangle(24, 0, 24, 24));
		GuiSetIconTexture(ICON_231, icons, new Rectangle(48, 0, 24, 24));
		};

		while (!WindowShouldClose()) {
			BeginDrawing();
			ClearBackground(RAYWHITE);
			if (loaded < 7) {
				EndDrawing();
				continue;
			}
			if (!setup) {
				init();
				setup = true;
			}

			var x = 304.0;
			if (GuiButton(new Rectangle(x, 120, 192, 64), GuiIconText(ICON_229, "Play")) != 0)
				played = true;

			if (!played)
				GuiDisable();
			if (GuiButton(new Rectangle(x, 200, 192, 64), GuiIconText(ICON_230, "Options")) != 0) {
				// options screen not part of this task
			}
			if (!played)
				GuiEnable();

			var quit = false;
			var prev = GuiGetSkin(BUTTON, GUI_SKIN_BASE);
			GuiSetSkin(BUTTON, GUI_SKIN_BASE, quitSkin);
			quit = GuiButton(new Rectangle(x, 280, 192, 64), GuiIconText(ICON_231, "Quit")) != 0;
			GuiSetSkin(BUTTON, GUI_SKIN_BASE, prev);

			var toggled = soundOnFlag
				? GuiTextureButton(new Rectangle(742, 10, 48, 48), soundOn, null, soundOnPressed)
				: GuiTextureButton(new Rectangle(742, 10, 48, 48), soundOff, null, soundOffPressed);
			if (toggled != 0)
				soundOnFlag = !soundOnFlag;

			EndDrawing();
			if (quit)
				break;
		}
		CloseWindow();
	}
}
