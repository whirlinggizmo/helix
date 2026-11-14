import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.*;
import helix.raylib.extras.GuiSkins.*;
import helix.raylib.extras.GuiSkin;

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
		var buttonSkin:GuiSkin = null;
		var quitSkin:GuiSkin = null;
		var pending = 7;
		var ready = false;

		function setup() {
		buttonSkin = GuiSkinFromSheet(sheet, 192, 64, 16, 16, 16, 20);
			buttonSkin.normalTextOffset = new Vector2(0, -2);
			buttonSkin.focusedTextOffset = new Vector2(0, -2);
			buttonSkin.pressedTextOffset = new Vector2(0, 2);
			buttonSkin.disabledTextOffset = new Vector2(0, -2);

			quitSkin = GuiSkinFromSheet(quitSheet, 192, 64, 16, 16, 16, 20);
			quitSkin.normalTextOffset = new Vector2(0, -2);
			quitSkin.focusedTextOffset = new Vector2(0, -4);
			quitSkin.pressedTextOffset = new Vector2(0, 2);
			quitSkin.disabledTextOffset = new Vector2(0, -2);

			GuiSetSkin(BUTTON, GUI_SKIN_BASE, buttonSkin);
			GuiSetIconTexture(ICON_229, icons, new Rectangle(0, 0, 24, 24));
			GuiSetIconTexture(ICON_230, icons, new Rectangle(24, 0, 24, 24));
			GuiSetIconTexture(ICON_231, icons, new Rectangle(48, 0, 24, 24));
			ready = true;
		}

		function load(path:String, set:Texture2D->Void) {
			LoadTextureAsync(path, t -> {
				set(t);
				if (--pending == 0)
					setup();
			});
		}

		load("assets/button.png", t -> sheet = t);
		load("assets/button_quit.png", t -> quitSheet = t);
		load("assets/icons.png", t -> icons = t);
		load("assets/sound_on.png", t -> soundOn = t);
		load("assets/sound_on_pressed.png", t -> soundOnPressed = t);
		load("assets/sound_off.png", t -> soundOff = t);
		load("assets/sound_off_pressed.png", t -> soundOffPressed = t);

		var played = false;
		var soundIsOn = true;
		var quit = false;

		while (!quit && !WindowShouldClose()) {
			BeginDrawing();
			ClearBackground(RAYWHITE);
			if (!ready) {
				EndDrawing();
				continue;
			}

			var x = 800 / 2 - 96;
			if (GuiButton(new Rectangle(x, 140, 192, 64), GuiIconText(ICON_229, "Play")) != 0)
				played = true;

			if (!played)
				GuiDisable();
			GuiButton(new Rectangle(x, 220, 192, 64), GuiIconText(ICON_230, "Options"));
			if (!played)
				GuiEnable();

			GuiSetSkin(BUTTON, GUI_SKIN_BASE, quitSkin);
			if (GuiButton(new Rectangle(x, 300, 192, 64), GuiIconText(ICON_231, "Quit")) != 0)
				quit = true;
			GuiSetSkin(BUTTON, GUI_SKIN_BASE, buttonSkin);

			var b = new Rectangle(800 - 48 - 10, 10, 48, 48);
			var clicked = soundIsOn ? GuiTextureButton(b, soundOn, soundOn, soundOnPressed) : GuiTextureButton(b, soundOff, soundOff, soundOffPressed);
			if (clicked != 0)
				soundIsOn = !soundIsOn;

			EndDrawing();
		}

		GuiClearSkins();
		if (sheet != null)
			UnloadTexture(sheet);
		if (quitSheet != null)
			UnloadTexture(quitSheet);
		if (icons != null)
			UnloadTexture(icons);
		if (soundOn != null)
			UnloadTexture(soundOn);
		if (soundOnPressed != null)
			UnloadTexture(soundOnPressed);
		if (soundOff != null)
			UnloadTexture(soundOff);
		if (soundOffPressed != null)
			UnloadTexture(soundOffPressed);
		CloseWindow();
	}
}
