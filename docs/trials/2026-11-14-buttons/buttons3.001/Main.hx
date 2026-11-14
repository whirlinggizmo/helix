import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.*;
import helix.raylib.extras.GuiSkin;
import helix.raylib.extras.GuiSkins.*;

class Main {
	static function makeSkin(sheet:Texture2D, focusedLift:Float):GuiSkin {
		var skin = GuiSkinFromSheet(sheet, 192, 64, 16, 16, 16, 20);
		// Raised faces have a 4 texel lip, so the text sits 2 above the bounds' center; a pressed face is pushed down onto the lip.
		skin.normalTextOffset = new Vector2(0, -2);
		skin.focusedTextOffset = new Vector2(0, -2 - focusedLift);
		skin.pressedTextOffset = new Vector2(0, 2);
		skin.disabledTextOffset = new Vector2(0, -2);
		return skin;
	}

	static function main() {
		InitWindow(800, 450, "Main menu");
		SetTargetFPS(60);

		var tex:Map<String, Texture2D> = new Map();
		var names = ["button", "button_quit", "icons", "sound_on", "sound_on_pressed", "sound_off", "sound_off_pressed"];
		for (n in names)
			LoadTextureAsync("assets/" + n + ".png", t -> tex[n] = t);
		var ready = false;
		var normalSkin:GuiSkin = null;
		var quitSkin:GuiSkin = null;
		var soundOn:Texture2D = null;
		var soundOnPressed:Texture2D = null;
		var soundOff:Texture2D = null;
		var soundOffPressed:Texture2D = null;
		var iconPlay = ICON_229;
		var iconGear = ICON_230;
		var iconDoor = ICON_231;
		var played = false;
		var soundIsOn = true;
		var quit = false;

		while (!quit && !WindowShouldClose()) {
			BeginDrawing();
			ClearBackground(RAYWHITE);

			if (!ready) {
				var all = true;
				for (n in names)
					if (!tex.exists(n))
						all = false;
				if (all) {
					ready = true;
					normalSkin = makeSkin(tex["button"], 0);
					quitSkin = makeSkin(tex["button_quit"], 2);
					soundOn = tex["sound_on"];
					soundOnPressed = tex["sound_on_pressed"];
					soundOff = tex["sound_off"];
					soundOffPressed = tex["sound_off_pressed"];
					GuiSetSkin(BUTTON, GUI_SKIN_BASE, normalSkin);
					var icons = tex["icons"];
					GuiSetIconTexture(iconPlay, icons, new Rectangle(0, 0, 24, 24));
					GuiSetIconTexture(iconGear, icons, new Rectangle(24, 0, 24, 24));
					GuiSetIconTexture(iconDoor, icons, new Rectangle(48, 0, 24, 24));
				}
				EndDrawing();
				continue;
			}

			var x = (800 - 192) / 2;
			if (GuiButton(new Rectangle(x, 150, 192, 64), GuiIconText(iconPlay, "Play")) != 0)
				played = true;

			if (!played)
				GuiDisable();
			GuiButton(new Rectangle(x, 230, 192, 64), GuiIconText(iconGear, "Options"));
			if (!played)
				GuiEnable();

			// Quit has its own sheet; put the shared skin back after it.
			GuiSetSkin(BUTTON, GUI_SKIN_BASE, quitSkin);
			if (GuiButton(new Rectangle(x, 310, 192, 64), GuiIconText(iconDoor, "Quit")) != 0)
				quit = true;
			GuiSetSkin(BUTTON, GUI_SKIN_BASE, normalSkin);

			var bounds = new Rectangle(800 - 48 - 10, 10, 48, 48);
			var clicked = soundIsOn ? GuiTextureButton(bounds, soundOn, null, soundOnPressed) : GuiTextureButton(bounds, soundOff, null, soundOffPressed);
			if (clicked != 0)
				soundIsOn = !soundIsOn;

			EndDrawing();
		}

		CloseWindow();
	}
}
