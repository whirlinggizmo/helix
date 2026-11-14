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
	static var pending = 7;

	static var playedOnce = false;
	static var sound = true;

	static function done():Void
		pending--;

	static function main():Void {
		InitWindow(800, 450, "Main menu");
		SetTargetFPS(60);

		LoadTextureAsync("assets/button.png", t -> {
			skin = GuiSkinFromSheet(t, 192, 64, 16, 16, 16, 20, 4);
			done();
		});
		LoadTextureAsync("assets/button_quit.png", t -> {
			quitSkin = GuiSkinFromSheet(t, 192, 64, 16, 16, 16, 20, 4, 2);
			done();
		});
		LoadTextureAsync("assets/icons.png", t -> {
			// raygui's spare icons, one per button
			for (i in 0...3)
				GuiSetIconTexture(ICON_229 + i, t, new Rectangle(i * 24, 0, 24, 24));
			done();
		});
		LoadTextureAsync("assets/sound_on.png", t -> { soundOn = t; done(); });
		LoadTextureAsync("assets/sound_on_pressed.png", t -> { soundOnPressed = t; done(); });
		LoadTextureAsync("assets/sound_off.png", t -> { soundOff = t; done(); });
		LoadTextureAsync("assets/sound_off_pressed.png", t -> { soundOffPressed = t; done(); });
		// a round button's corners shouldn't answer the pointer
		LoadImageAsync("assets/sound_on.png", i -> { soundMask = i; });

		var quit = false;
		while (!WindowShouldClose() && !quit) {
			BeginDrawing();
			ClearBackground(RAYWHITE);

			if (pending == 0 && soundMask != null) {
				GuiSetSkin(BUTTON, GUI_SKIN_BASE, skin);

				var x = (800 - 192) / 2;
				if (GuiButton(new Rectangle(x, 120, 192, 64), GuiIconText(ICON_229, "Play")) != 0)
					playedOnce = true;

				if (!playedOnce)
					GuiDisable();
				GuiButton(new Rectangle(x, 200, 192, 64), GuiIconText(ICON_230, "Options"));
				if (!playedOnce)
					GuiEnable();

				GuiSetSkinOnce(BUTTON, GUI_SKIN_BASE, quitSkin);
				if (GuiButton(new Rectangle(x, 280, 192, 64), GuiIconText(ICON_231, "Quit")) != 0)
					quit = true;

				var clicked = if (sound)
					GuiTextureButton(new Rectangle(740, 10, 48, 48), soundOn, soundOn, soundOnPressed, null, soundMask);
				else
					GuiTextureButton(new Rectangle(740, 10, 48, 48), soundOff, soundOff, soundOffPressed, null, soundMask);
				if (clicked != 0)
					sound = !sound;
			} else {
				DrawText("Loading...", 340, 210, 20, GRAY);
			}

			EndDrawing();
		}
		CloseWindow();
	}
}
