import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.*;
import helix.raylib.extras.GuiSkins.*;
import helix.raylib.extras.GuiSkin;

class Main {
	static var soundOn = true;
	static var played = false;
	static var quit = false;

	static var soundOnTex:Texture2D;
	static var soundOnPressedTex:Texture2D;
	static var soundOffTex:Texture2D;
	static var soundOffPressedTex:Texture2D;
	static var soundReady = 0;

	static function textOffsets(skin:GuiSkin, focusedY:Float) {
		skin.normalTextOffset = new Vector2(0, -2);
		skin.focusedTextOffset = new Vector2(0, focusedY);
		skin.pressedTextOffset = new Vector2(0, 2);
		skin.disabledTextOffset = new Vector2(0, -2);
	}

	static function main() {
		InitWindow(800, 450, "Main menu");
		SetTargetFPS(60);

		LoadTextureAsync("assets/button.png", sheet -> {
			var skin = GuiSkinFromSheet(sheet, 192, 64, 16, 16, 16, 20);
			textOffsets(skin, -2);
			GuiSetSkin(BUTTON, GUI_SKIN_BASE, skin);
		});
		LoadTextureAsync("assets/icons.png", icons -> {
			GuiSetIconTexture(ICON_229, icons, new Rectangle(0, 0, 24, 24));
			GuiSetIconTexture(ICON_230, icons, new Rectangle(24, 0, 24, 24));
			GuiSetIconTexture(ICON_231, icons, new Rectangle(48, 0, 24, 24));
		});
		LoadTextureAsync("assets/sound_on.png", t -> { soundOnTex = t; soundReady++; });
		LoadTextureAsync("assets/sound_on_pressed.png", t -> { soundOnPressedTex = t; soundReady++; });
		LoadTextureAsync("assets/sound_off.png", t -> { soundOffTex = t; soundReady++; });
		LoadTextureAsync("assets/sound_off_pressed.png", t -> { soundOffPressedTex = t; soundReady++; });

		var quitSkin:GuiSkin = null;
		LoadTextureAsync("assets/button_quit.png", sheet -> {
			quitSkin = GuiSkinFromSheet(sheet, 192, 64, 16, 16, 16, 20);
			textOffsets(quitSkin, -4);
		});

		while (!WindowShouldClose() && !quit) {
			BeginDrawing();
			ClearBackground(RAYWHITE);

			var x = 304.0;
			if (GuiButton(new Rectangle(x, 130, 192, 64), GuiIconText(ICON_229, "Play")) != 0)
				played = true;

			if (!played)
				GuiDisable();
			GuiButton(new Rectangle(x, 210, 192, 64), GuiIconText(ICON_230, "Options"));
			if (!played)
				GuiEnable();

			// Quit draws from its own sheet: swap the skin in for this call alone.
			var prev = GuiGetSkin(BUTTON, GUI_SKIN_BASE);
			if (quitSkin != null)
				GuiSetSkin(BUTTON, GUI_SKIN_BASE, quitSkin);
			if (GuiButton(new Rectangle(x, 290, 192, 64), GuiIconText(ICON_231, "Quit")) != 0)
				quit = true;
			GuiSetSkin(BUTTON, GUI_SKIN_BASE, prev);

			if (soundReady == 4) {
				var r = new Rectangle(800 - 48 - 16, 16, 48, 48);
				var clicked = soundOn ? GuiTextureButton(r, soundOnTex, soundOnTex, soundOnPressedTex) : GuiTextureButton(r, soundOffTex, soundOffTex,
					soundOffPressedTex);
				if (clicked != 0)
					soundOn = !soundOn;
			}

			EndDrawing();
		}
		CloseWindow();
	}
}
