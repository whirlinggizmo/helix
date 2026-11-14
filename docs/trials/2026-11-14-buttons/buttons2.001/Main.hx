import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.*;
import helix.raylib.extras.GuiSkins.*;
import helix.raylib.extras.GuiSkin;

class Main {
	static var skinNormal:Null<GuiSkin>;
	static var skinQuit:Null<GuiSkin>;
	static var icons:Null<Texture2D>;
	static var soundOn:Null<Texture2D>;
	static var soundOnPressed:Null<Texture2D>;
	static var soundOff:Null<Texture2D>;
	static var soundOffPressed:Null<Texture2D>;
	static var played = false;
	static var sound = true;

	static function makeSkin(sheet:Texture2D, focusLift:Float):GuiSkin {
		var s = GuiSkinFromSheet(sheet, 192, 64, 16, 16, 16, 20);
		s.focusedTextOffset = new Vector2(0, -focusLift);
		s.pressedTextOffset = new Vector2(0, 4);
		return s;
	}

	static function main() {
		InitWindow(800, 450, "Main menu");
		SetTargetFPS(60);

		LoadTextureAsync("assets/button.png", t -> skinNormal = makeSkin(t, 0));
		LoadTextureAsync("assets/button_quit.png", t -> skinQuit = makeSkin(t, 2));
		LoadTextureAsync("assets/icons.png", t -> {
			icons = t;
			GuiSetIconTexture(ICON_229, t, new Rectangle(0, 0, 24, 24));
			GuiSetIconTexture(ICON_230, t, new Rectangle(24, 0, 24, 24));
			GuiSetIconTexture(ICON_231, t, new Rectangle(48, 0, 24, 24));
		});
		LoadTextureAsync("assets/sound_on.png", t -> soundOn = t);
		LoadTextureAsync("assets/sound_on_pressed.png", t -> soundOnPressed = t);
		LoadTextureAsync("assets/sound_off.png", t -> soundOff = t);
		LoadTextureAsync("assets/sound_off_pressed.png", t -> soundOffPressed = t);

		while (!WindowShouldClose()) {
			BeginDrawing();
			ClearBackground(RAYWHITE);

			var x = 800 / 2 - 96;
			if (skinNormal != null)
				GuiSetSkin(BUTTON, GUI_SKIN_BASE, skinNormal);
			if (GuiButton(new Rectangle(x, 150, 192, 64), GuiIconText(ICON_229, "Play")) != 0)
				played = true;

			if (!played)
				GuiDisable();
			GuiButton(new Rectangle(x, 230, 192, 64), GuiIconText(ICON_230, "Options"));
			if (!played)
				GuiEnable();

			if (skinQuit != null)
				GuiSetSkin(BUTTON, GUI_SKIN_BASE, skinQuit);
			var quit = GuiButton(new Rectangle(x, 310, 192, 64), GuiIconText(ICON_231, "Quit")) != 0;
			GuiSetSkin(BUTTON, GUI_SKIN_BASE, skinNormal);

			var on = sound ? soundOn : soundOff;
			var held = sound ? soundOnPressed : soundOffPressed;
			if (on != null && GuiTextureButton(new Rectangle(800 - 48 - 10, 10, 48, 48), on, null, held) != 0)
				sound = !sound;

			EndDrawing();
			if (quit)
				break;
		}
		CloseWindow();
	}
}
