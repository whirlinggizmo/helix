import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.*;
import helix.raylib.extras.GuiSkins.*;
import helix.raylib.extras.GuiSkin;

class Main {
	static var skin:GuiSkin;
	static var quitSkin:GuiSkin;
	static var soundOn:Texture2D;
	static var soundOnPressed:Texture2D;
	static var soundOff:Texture2D;
	static var soundOffPressed:Texture2D;
	static var soundMask:Image;
	static var iconsReady = false;

	static var playedOnce = false;
	static var sound = true;

	static function main() {
		InitWindow(800, 450, "Main menu");
		SetTargetFPS(60);

		LoadTextureAsync("assets/button.png", sheet -> {
			skin = GuiSkinFromSheet(sheet, 192, 64, 16, 16, 16, 20, 4, 0);
			GuiSetSkin(BUTTON, GUI_SKIN_BASE, skin);
		});
		LoadTextureAsync("assets/button_quit.png", sheet -> {
			quitSkin = GuiSkinFromSheet(sheet, 192, 64, 16, 16, 16, 20, 4, 2);
		});
		LoadTextureAsync("assets/icons.png", icons -> {
			GuiSetIconTexture(ICON_229, icons, new Rectangle(0, 0, 24, 24));
			GuiSetIconTexture(ICON_230, icons, new Rectangle(24, 0, 24, 24));
			GuiSetIconTexture(ICON_231, icons, new Rectangle(48, 0, 24, 24));
			iconsReady = true;
		});
		LoadTextureAsync("assets/sound_on.png", t -> soundOn = t);
		LoadTextureAsync("assets/sound_on_pressed.png", t -> soundOnPressed = t);
		LoadTextureAsync("assets/sound_off.png", t -> soundOff = t);
		LoadTextureAsync("assets/sound_off_pressed.png", t -> soundOffPressed = t);
		LoadImageAsync("assets/sound_on.png", i -> soundMask = i);

		while (!WindowShouldClose()) {
			BeginDrawing();
			ClearBackground(RAYWHITE);

			var x = 400 - 96;
			var play = iconsReady ? GuiIconText(ICON_229, "Play") : "Play";
			var options = iconsReady ? GuiIconText(ICON_230, "Options") : "Options";
			var quit = iconsReady ? GuiIconText(ICON_231, "Quit") : "Quit";

			if (GuiButton(new Rectangle(x, 150, 192, 64), play) != 0)
				playedOnce = true;

			if (!playedOnce)
				GuiDisable();
			GuiButton(new Rectangle(x, 230, 192, 64), options);
			if (!playedOnce)
				GuiEnable();

			if (quitSkin != null)
				GuiSetSkinOnce(BUTTON, GUI_SKIN_BASE, quitSkin);
			var quitClicked = GuiButton(new Rectangle(x, 310, 192, 64), quit) != 0;

			if (soundOn != null && soundOff != null) {
				var on = sound;
				var clicked = GuiTextureButton(new Rectangle(800 - 48 - 10, 10, 48, 48), on ? soundOn : soundOff, null, on ? soundOnPressed : soundOffPressed,
					null, soundMask);
				if (clicked != 0)
					sound = !sound;
			}

			EndDrawing();

			if (quitClicked)
				break;
		}
		CloseWindow();
	}
}
