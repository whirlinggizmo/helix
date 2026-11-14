import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.*;
import helix.raylib.extras.GuiSkins.*;
import helix.raylib.extras.GuiSkin;

class Main {
	static var normalSkin:GuiSkin;
	static var quitSkin:GuiSkin;
	static var soundOn:Texture2D;
	static var soundOnPressed:Texture2D;
	static var soundOff:Texture2D;
	static var soundOffPressed:Texture2D;
	static var pending = 7;

	static function loaded():Void {
		pending--;
	}

	static function main() {
		InitWindow(800, 450, "Main menu");
		SetTargetFPS(60);

		// Cells are 192 x 64; borders 16 left/top/right, 20 bottom.
		LoadTextureAsync("assets/button.png", t -> {
			normalSkin = GuiSkinFromSheet(t, 192, 64, 16, 16, 16, 20);
			normalSkin.pressedTextOffset = new Vector2(0, 4);
			GuiSetSkin(BUTTON, GUI_SKIN_BASE, normalSkin);
			loaded();
		});
		LoadTextureAsync("assets/button_quit.png", t -> {
			quitSkin = GuiSkinFromSheet(t, 192, 64, 16, 16, 16, 20);
			quitSkin.focusedTextOffset = new Vector2(0, -2);
			quitSkin.pressedTextOffset = new Vector2(0, 4);
			loaded();
		});
		// Spare icons carry the three images.
		LoadTextureAsync("assets/icons.png", t -> {
			GuiSetIconTexture(ICON_229, t, new Rectangle(0, 0, 24, 24));
			GuiSetIconTexture(ICON_230, t, new Rectangle(24, 0, 24, 24));
			GuiSetIconTexture(ICON_231, t, new Rectangle(48, 0, 24, 24));
			loaded();
		});
		LoadTextureAsync("assets/sound_on.png", t -> {
			soundOn = t;
			loaded();
		});
		LoadTextureAsync("assets/sound_on_pressed.png", t -> {
			soundOnPressed = t;
			loaded();
		});
		LoadTextureAsync("assets/sound_off.png", t -> {
			soundOff = t;
			loaded();
		});
		LoadTextureAsync("assets/sound_off_pressed.png", t -> {
			soundOffPressed = t;
			loaded();
		});

		var played = false;
		var soundIsOn = true;
		var quit = false;

		while (!WindowShouldClose() && !quit) {
			BeginDrawing();
			ClearBackground(RAYWHITE);

			if (pending == 0) {
				var x = (800 - 192) / 2;
				GuiSetSkin(BUTTON, GUI_SKIN_BASE, normalSkin);
				if (GuiButton(new Rectangle(x, 150, 192, 64), GuiIconText(ICON_229, "Play")) != 0)
					played = true;

				if (!played)
					GuiDisable();
				GuiButton(new Rectangle(x, 230, 192, 64), GuiIconText(ICON_230, "Options"));
				if (!played)
					GuiEnable();

				GuiSetSkin(BUTTON, GUI_SKIN_BASE, quitSkin);
				quit = GuiButton(new Rectangle(x, 310, 192, 64), GuiIconText(ICON_231, "Quit")) != 0;
				GuiSetSkin(BUTTON, GUI_SKIN_BASE, normalSkin);

				var bounds = new Rectangle(740, 10, 48, 48);
				var snd = soundIsOn ? GuiTextureButton(bounds, soundOn, null, soundOnPressed) : GuiTextureButton(bounds, soundOff, null, soundOffPressed);
				if (snd != 0)
					soundIsOn = !soundIsOn;
			}

			EndDrawing();
		}
		CloseWindow();
	}
}
