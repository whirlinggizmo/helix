import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.extras.GuiSkin;
import helix.raylib.extras.GuiSkins.*;

class Main {
	static var baseSkin:Null<GuiSkin>;
	static var quitSkin:Null<GuiSkin>;
	static var soundOn:Null<Texture2D>;
	static var soundOnPressed:Null<Texture2D>;
	static var soundOff:Null<Texture2D>;
	static var soundOffPressed:Null<Texture2D>;

	static function sheetSkin(tex:Texture2D, lift:Float):GuiSkin {
		var skin = GuiSkinFromSheet(tex, 192, 64, 16, 16, 16, 20);
		skin.focusedTextOffset = new Vector2(0, -lift);
		skin.pressedTextOffset = new Vector2(0, 4);
		return skin;
	}

	static function main() {
		InitWindow(800, 450, "Main menu");
		SetTargetFPS(60);

		LoadTextureAsync("assets/button.png", tex -> {
			baseSkin = sheetSkin(tex, 0);
			GuiSetSkin(BUTTON, GUI_SKIN_BASE, baseSkin);
		});
		LoadTextureAsync("assets/button_quit.png", tex -> quitSkin = sheetSkin(tex, 2));
		LoadTextureAsync("assets/icons.png", tex -> {
			// Icons 229..231 are raygui's spare icons; they show the textures.
			GuiSetIconTexture(ICON_229, tex, new Rectangle(0, 0, 24, 24));
			GuiSetIconTexture(ICON_230, tex, new Rectangle(24, 0, 24, 24));
			GuiSetIconTexture(ICON_231, tex, new Rectangle(48, 0, 24, 24));
		});
		LoadTextureAsync("assets/sound_on.png", tex -> soundOn = tex);
		LoadTextureAsync("assets/sound_on_pressed.png", tex -> soundOnPressed = tex);
		LoadTextureAsync("assets/sound_off.png", tex -> soundOff = tex);
		LoadTextureAsync("assets/sound_off_pressed.png", tex -> soundOffPressed = tex);

		var playedOnce = false;
		var soundEnabled = true;

		while (!WindowShouldClose()) {
			BeginDrawing();
			ClearBackground(RAYWHITE);

			var x = 800 / 2 - 96;
			if (GuiButton(new Rectangle(x, 150, 192, 64), GuiIconText(ICON_229, "Play")) != 0)
				playedOnce = true;

			if (!playedOnce)
				GuiDisable();
			GuiButton(new Rectangle(x, 230, 192, 64), GuiIconText(ICON_230, "Options"));
			if (!playedOnce)
				GuiEnable();

			if (quitSkin != null)
				GuiSetSkin(BUTTON, GUI_SKIN_BASE, quitSkin);
			var quit = GuiButton(new Rectangle(x, 310, 192, 64), GuiIconText(ICON_231, "Quit")) != 0;
			GuiSetSkin(BUTTON, GUI_SKIN_BASE, baseSkin);

			var on = soundEnabled ? soundOn : soundOff;
			var held = soundEnabled ? soundOnPressed : soundOffPressed;
			if (on != null && held != null
				&& GuiTextureButton(new Rectangle(800 - 48 - 16, 16, 48, 48), on, on, held) != 0)
				soundEnabled = !soundEnabled;

			EndDrawing();
			if (quit)
				break;
		}
		CloseWindow();
	}
}
