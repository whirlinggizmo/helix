import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.*;
import helix.raylib.extras.GuiSkins.*;
import helix.raylib.extras.GuiSkin;

class Main {
	static inline var PLAY_ICON = ICON_229;
	static inline var OPTIONS_ICON = ICON_230;
	static inline var QUIT_ICON = ICON_231;

	static var pending = 7;
	static var failed = false;
	static var sheet:Texture2D;
	static var quitSheet:Texture2D;
	static var icons:Texture2D;
	static var soundOn:Texture2D;
	static var soundOnPressed:Texture2D;
	static var soundOff:Texture2D;
	static var soundOffPressed:Texture2D;
	static var quitSkin:GuiSkin;

	static function load(file:String, set:Texture2D->Void) {
		LoadTextureAsync("assets/" + file, t -> {
			set(t);
			pending--;
		}, err -> {
			failed = true;
		});
	}

	// Cut the skins and icon textures once every texture has arrived.
	static function setup() {
		// Cells are 192 x 64; borders 16 at the sides and top, 20 at the bottom.
		var skin = GuiSkinFromSheet(sheet, 192, 64, 16, 16, 16, 20);
		skin.pressedTextOffset = new Vector2(0, 4);
		GuiSetSkin(BUTTON, GUI_SKIN_BASE, skin);

		quitSkin = GuiSkinFromSheet(quitSheet, 192, 64, 16, 16, 16, 20);
		quitSkin.focusedTextOffset = new Vector2(0, -2);
		quitSkin.pressedTextOffset = new Vector2(0, 4);

		GuiSetIconTexture(PLAY_ICON, icons, new Rectangle(0, 0, 24, 24));
		GuiSetIconTexture(OPTIONS_ICON, icons, new Rectangle(24, 0, 24, 24));
		GuiSetIconTexture(QUIT_ICON, icons, new Rectangle(48, 0, 24, 24));
	}

	static function main() {
		InitWindow(800, 450, "Main menu");
		SetTargetFPS(60);

		load("button.png", t -> sheet = t);
		load("button_quit.png", t -> quitSheet = t);
		load("icons.png", t -> icons = t);
		load("sound_on.png", t -> soundOn = t);
		load("sound_on_pressed.png", t -> soundOnPressed = t);
		load("sound_off.png", t -> soundOff = t);
		load("sound_off_pressed.png", t -> soundOffPressed = t);

		var ready = false;
		var played = false;
		var soundIsOn = true;
		var quit = false;

		while (!WindowShouldClose() && !quit) {
			BeginDrawing();
			ClearBackground(RAYWHITE);

			if (!ready && pending == 0) {
				setup();
				ready = true;
			}

			if (ready) {
				var x = 800 / 2 - 96;
				if (GuiButton(new Rectangle(x, 150, 192, 64), GuiIconText(PLAY_ICON, "Play")) != 0)
					played = true;

				if (!played)
					GuiDisable();
				GuiButton(new Rectangle(x, 230, 192, 64), GuiIconText(OPTIONS_ICON, "Options"));
				if (!played)
					GuiEnable();

				// Quit has its own skin, set around its one call.
				var previous = GuiGetSkin(BUTTON, GUI_SKIN_BASE);
				GuiSetSkin(BUTTON, GUI_SKIN_BASE, quitSkin);
				if (GuiButton(new Rectangle(x, 310, 192, 64), GuiIconText(QUIT_ICON, "Quit")) != 0)
					quit = true;
				GuiSetSkin(BUTTON, GUI_SKIN_BASE, previous);

				var on = soundIsOn;
				if (GuiTextureButton(new Rectangle(800 - 48 - 16, 16, 48, 48), on ? soundOn : soundOff, null, on ? soundOnPressed : soundOffPressed) != 0)
					soundIsOn = !soundIsOn;
			} else if (failed) {
				DrawText("Could not load assets", 20, 20, 20, RED);
			}

			EndDrawing();
		}
		CloseWindow();
	}
}
