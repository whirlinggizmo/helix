import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.*;
import helix.raylib.extras.GuiSkins.*;
import helix.raylib.extras.GuiSkin;

class Main {
	static var playedOnce = false;
	static var soundOn = true;
	static var quit = false;

	static var soundOnTex:Texture2D;
	static var soundOnPressedTex:Texture2D;
	static var soundOffTex:Texture2D;
	static var soundOffPressedTex:Texture2D;

	static var buttonSkin:GuiSkin;
	static var quitSkin:GuiSkin;

	static function main() {
		InitWindow(800, 450, "Main menu");
		SetTargetFPS(60);

		LoadTextureAsync("assets/button.png", sheet -> {
			buttonSkin = GuiSkinFromSheet(sheet, 192, 64, 16, 16, 16, 20);
			buttonSkin.pressedTextOffset = new Vector2(0, 4);
			GuiSetSkin(BUTTON, GUI_SKIN_BASE, buttonSkin);
		});
		LoadTextureAsync("assets/button_quit.png", sheet -> {
			quitSkin = GuiSkinFromSheet(sheet, 192, 64, 16, 16, 16, 20);
			quitSkin.focusedTextOffset = new Vector2(0, -2);
			quitSkin.pressedTextOffset = new Vector2(0, 4);
		});
		LoadTextureAsync("assets/icons.png", icons -> {
			GuiSetIconTexture(ICON_229, icons, new Rectangle(0, 0, 24, 24));
			GuiSetIconTexture(ICON_230, icons, new Rectangle(24, 0, 24, 24));
			GuiSetIconTexture(ICON_231, icons, new Rectangle(48, 0, 24, 24));
		});
		LoadTextureAsync("assets/sound_on.png", t -> soundOnTex = t);
		LoadTextureAsync("assets/sound_on_pressed.png", t -> soundOnPressedTex = t);
		LoadTextureAsync("assets/sound_off.png", t -> soundOffTex = t);
		LoadTextureAsync("assets/sound_off_pressed.png", t -> soundOffPressedTex = t);

		while (!WindowShouldClose() && !quit) {
			BeginDrawing();
			ClearBackground(RAYWHITE);

			var x = 304.0;
			var w = 192.0;
			var h = 64.0;

			if (GuiButton(new Rectangle(x, 120, w, h), GuiIconText(ICON_229, "Play")) != 0)
				playedOnce = true;

			if (!playedOnce)
				GuiDisable();
			GuiButton(new Rectangle(x, 200, w, h), GuiIconText(ICON_230, "Options"));
			if (!playedOnce)
				GuiEnable();

			// Quit's skin is set around its own call only
			if (quitSkin != null)
				GuiSetSkin(BUTTON, GUI_SKIN_BASE, quitSkin);
			if (GuiButton(new Rectangle(x, 280, w, h), GuiIconText(ICON_231, "Quit")) != 0)
				quit = true;
			GuiSetSkin(BUTTON, GUI_SKIN_BASE, buttonSkin);

			if (soundOnTex != null && soundOnPressedTex != null && soundOffTex != null && soundOffPressedTex != null) {
				var r = new Rectangle(800 - 48 - 10, 10, 48, 48);
				var clicked = soundOn ? GuiTextureButton(r, soundOnTex, null, soundOnPressedTex) : GuiTextureButton(r, soundOffTex, null,
					soundOffPressedTex);
				if (clicked != 0)
					soundOn = !soundOn;
			}

			EndDrawing();
		}
		CloseWindow();
	}
}
