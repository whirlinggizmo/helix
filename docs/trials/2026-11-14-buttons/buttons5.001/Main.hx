import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.*;
import helix.raylib.extras.GuiSkins.*;
import helix.raylib.extras.GuiSkin;

class Main {
	static var quitSkin:GuiSkin;
	static var barExp:GuiSkin;
	static var soundOn:Texture2D;
	static var soundOnPressed:Texture2D;
	static var soundOff:Texture2D;
	static var soundOffPressed:Texture2D;
	static var soundMask:Image;
	static var soundEnabled = true;
	static var played = false;

	static function threePatch(w:Int, h:Int, cap:Int):NPatchInfo {
		return {
			source: new Rectangle(0, 0, w, h),
			left: cap,
			top: 0,
			right: cap,
			bottom: 0,
			layout: NPATCH_THREE_PATCH_HORIZONTAL
		};
	}

	static function main() {
		InitWindow(800, 450, "Main menu");
		SetTargetFPS(60);

		LoadTextureAsync("assets/button.png", sheet -> GuiSetSkin(BUTTON, GUI_SKIN_BASE, GuiSkinFromSheet(sheet, 192, 64, 16, 16, 16, 20, 4)));
		LoadTextureAsync("assets/button_quit.png", sheet -> quitSkin = GuiSkinFromSheet(sheet, 192, 64, 16, 16, 16, 20, 4, 2));

		LoadTextureAsync("assets/icons.png", icons -> {
			GuiSetIconTexture(ICON_229, icons, new Rectangle(0, 0, 24, 24));
			GuiSetIconTexture(ICON_230, icons, new Rectangle(24, 0, 24, 24));
			GuiSetIconTexture(ICON_231, icons, new Rectangle(48, 0, 24, 24));
		});

		LoadTextureAsync("assets/sound_on.png", t -> soundOn = t);
		LoadTextureAsync("assets/sound_on_pressed.png", t -> soundOnPressed = t);
		LoadTextureAsync("assets/sound_off.png", t -> soundOff = t);
		LoadTextureAsync("assets/sound_off_pressed.png", t -> soundOffPressed = t);
		LoadImageAsync("assets/sound_on.png", i -> soundMask = i);

		// Bars: grey box shared; red fill clipped with a tip; blue fill stretched.
		LoadTextureAsync("assets/bar_grey.png", grey -> {
			GuiSetSkin(PROGRESSBAR, GUI_SKIN_BASE, GuiSkinFromTexture(grey, threePatch(96, 16, 16)));
		});
		LoadTextureAsync("assets/bar_red.png", red -> {
			LoadTextureAsync("assets/bar_tip.png", tip -> {
				var s = GuiSkinFromTexture(red, threePatch(96, 16, 16));
				s.fillMode = GUI_SKIN_FILL_CLIPPED;
				s.fillEdge = tip;
				GuiSetSkin(PROGRESSBAR, GUI_SKIN_FILL, s);
			});
		});
		LoadTextureAsync("assets/bar_blue.png", blue -> barExp = GuiSkinFromTexture(blue, threePatch(96, 16, 16)));

		var t = 0.0;
		while (!WindowShouldClose()) {
			t += GetFrameTime();
			var health = [100.0 * (1 - Math.abs(((t % 10) / 5) - 1))];
			var exp = [Math.min(100.0, t / 20 * 100.0)];

			BeginDrawing();
			ClearBackground(RAYWHITE);

			if (GuiButton(new Rectangle(304, 100, 192, 64), GuiIconText(ICON_229, "Play")) != 0)
				played = true;

			if (!played)
				GuiDisable();
			GuiButton(new Rectangle(304, 176, 192, 64), GuiIconText(ICON_230, "Options"));
			if (!played)
				GuiEnable();

			if (quitSkin != null)
				GuiSetSkinOnce(BUTTON, GUI_SKIN_BASE, quitSkin);
			if (GuiButton(new Rectangle(304, 252, 192, 64), GuiIconText(ICON_231, "Quit")) != 0)
				break;

			GuiProgressBar(new Rectangle(352, 332, 96, 16), "", "", health, 0, 100);
			if (barExp != null)
				GuiSetSkinOnce(PROGRESSBAR, GUI_SKIN_FILL, barExp);
			GuiProgressBar(new Rectangle(352, 356, 96, 16), "", "", exp, 0, 100);

			if (soundOn != null) {
				var b = new Rectangle(736, 16, 48, 48);
				var clicked = soundEnabled ? GuiTextureButton(b, soundOn, null, soundOnPressed, null, soundMask) : GuiTextureButton(b, soundOff, null,
					soundOffPressed, null, soundMask);
				if (clicked != 0)
					soundEnabled = !soundEnabled;
			}
			EndDrawing();
		}
		CloseWindow();
	}
}
