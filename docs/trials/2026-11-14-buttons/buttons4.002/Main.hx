import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.extras.GuiSkins.*;

class Main {
	static var soundOn = true;
	static var playedOnce = false;
	static var soundOnTex:Texture2D;
	static var soundOnPressed:Texture2D;
	static var soundOffTex:Texture2D;
	static var soundOffPressed:Texture2D;
	static var soundMask:Image;
	static var quitSkin:helix.raylib.extras.GuiSkin;
	static var ready = 0;

	static function main() {
		InitWindow(800, 450, "Main menu");
		SetTargetFPS(60);

		LoadTextureAsync("assets/button.png", sheet -> {
			GuiSetSkin(BUTTON, GUI_SKIN_BASE, GuiSkinFromSheet(sheet, 192, 64, 16, 16, 16, 20, 4, 0));
			ready++;
		});
		LoadTextureAsync("assets/button_quit.png", sheet -> {
			quitSkin = GuiSkinFromSheet(sheet, 192, 64, 16, 16, 16, 20, 4, 2);
			ready++;
		});
		LoadTextureAsync("assets/icons.png", icons -> {
			GuiSetIconTexture(ICON_229, icons, new Rectangle(0, 0, 24, 24));
			GuiSetIconTexture(ICON_230, icons, new Rectangle(24, 0, 24, 24));
			GuiSetIconTexture(ICON_231, icons, new Rectangle(48, 0, 24, 24));
			ready++;
		});
		LoadTextureAsync("assets/sound_on.png", t -> soundOnTex = t);
		LoadTextureAsync("assets/sound_on_pressed.png", t -> soundOnPressed = t);
		LoadTextureAsync("assets/sound_off.png", t -> soundOffTex = t);
		LoadTextureAsync("assets/sound_off_pressed.png", t -> soundOffPressed = t);
		LoadImageAsync("assets/sound_on.png", i -> soundMask = i);

		while (!WindowShouldClose()) {
			BeginDrawing();
			ClearBackground(RAYWHITE);

			var bw = 192;
			var bh = 64;
			var x = (800 - bw) / 2;

			if (GuiButton(new Rectangle(x, 120, bw, bh), GuiIconText(ICON_229, "Play")) != 0)
				playedOnce = true;

			if (!playedOnce)
				GuiDisable();
			if (GuiButton(new Rectangle(x, 200, bw, bh), GuiIconText(ICON_230, "Options")) != 0) {}
			if (!playedOnce)
				GuiEnable();

			GuiSetSkinOnce(BUTTON, GUI_SKIN_BASE, quitSkin);
			if (GuiButton(new Rectangle(x, 280, bw, bh), GuiIconText(ICON_231, "Quit")) != 0) {
				CloseWindow();
				return;
			}

			if (soundOnTex != null && soundOffTex != null && soundOnPressed != null && soundOffPressed != null) {
				var r = new Rectangle(800 - 48 - 10, 10, 48, 48);
				var clicked = if (soundOn) GuiTextureButton(r, soundOnTex, soundOnTex, soundOnPressed, null, soundMask)
				else GuiTextureButton(r, soundOffTex, soundOffTex, soundOffPressed, null, soundMask);
				if (clicked != 0)
					soundOn = !soundOn;
			}

			EndDrawing();
		}
		CloseWindow();
	}
}
