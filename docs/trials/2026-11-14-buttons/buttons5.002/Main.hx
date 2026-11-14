import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.extras.GuiSkin;
import helix.raylib.extras.GuiSkins.*;

class Main {
	static var buttonSheet:Texture2D;
	static var quitSheet:Texture2D;
	static var icons:Texture2D;
	static var soundOn:Texture2D;
	static var soundOnPressed:Texture2D;
	static var soundOff:Texture2D;
	static var soundOffPressed:Texture2D;
	static var barGrey:Texture2D;
	static var barRed:Texture2D;
	static var barBlue:Texture2D;
	static var barTip:Texture2D;
	static var quitSkin:GuiSkin;
	static var redSkin:GuiSkin;
	static var blueSkin:GuiSkin;
	static var pending = 11;
	static var ready = false;

	static function setup() {
		// Buttons: 192 x 64 cells, borders 16 / 16 / 16 / 20, lip of 4.
		GuiSetSkin(BUTTON, GUI_SKIN_BASE, GuiSkinFromSheet(buttonSheet, 192, 64, 16, 16, 16, 20, 4, 0));
		quitSkin = GuiSkinFromSheet(quitSheet, 192, 64, 16, 16, 16, 20, 4, 2);

		// Icons on the spare icon ids.
		GuiSetIconTexture(ICON_229, icons, new Rectangle(0, 0, 24, 24));
		GuiSetIconTexture(ICON_230, icons, new Rectangle(24, 0, 24, 24));
		GuiSetIconTexture(ICON_231, icons, new Rectangle(48, 0, 24, 24));

		// Bars: a three-patch with 16 texel caps.
		var capped = (tex:Texture2D) -> new NPatchInfo(new Rectangle(0, 0, 96, 16), 16, 0, 16, 0, NPATCH_THREE_PATCH_HORIZONTAL);
		var greySkin = GuiSkinFromTexture(barGrey, capped(barGrey));
		redSkin = GuiSkinFromTexture(barRed, capped(barRed));
		redSkin.fillMode = GUI_SKIN_FILL_CLIPPED;
		redSkin.fillEdge = barTip;
		blueSkin = GuiSkinFromTexture(barBlue, capped(barBlue));
		GuiSetSkin(PROGRESSBAR, GUI_SKIN_BASE, greySkin);

	}

	static function main() {
		InitWindow(800, 450, "Main menu");
		SetTargetFPS(60);

		var load = (file:String, set:Texture2D->Void) -> LoadTextureAsync("assets/" + file + ".png", tex -> {
			set(tex);
			if (--pending == 0) {
				setup();
				ready = true;
			}
		});
		load("button", t -> buttonSheet = t);
		load("button_quit", t -> quitSheet = t);
		load("icons", t -> icons = t);
		load("sound_on", t -> soundOn = t);
		load("sound_on_pressed", t -> soundOnPressed = t);
		load("sound_off", t -> soundOff = t);
		load("sound_off_pressed", t -> soundOffPressed = t);
		load("bar_grey", t -> barGrey = t);
		load("bar_red", t -> barRed = t);
		load("bar_blue", t -> barBlue = t);
		load("bar_tip", t -> barTip = t);

		var played = false;
		var soundIsOn = true;
		var time = 0.0;

		while (!WindowShouldClose()) {
			time += GetFrameTime();
			var t = (time % 10.0) / 10.0;
			var health = (t < 0.5 ? t * 2 : 2 - t * 2) * 100;
			var experience = Math.min(time / 20.0, 1.0) * 100;

			BeginDrawing();
			ClearBackground(RAYWHITE);
			if (!ready) {
				EndDrawing();
				continue;
			}

			var x = 304.0;
			if (GuiButton(new Rectangle(x, 90, 192, 64), GuiIconText(ICON_229, "Play")) != 0)
				played = true;

			if (!played)
				GuiDisable();
			GuiButton(new Rectangle(x, 170, 192, 64), GuiIconText(ICON_230, "Options"));
			if (!played)
				GuiEnable();

			GuiSetSkinOnce(BUTTON, GUI_SKIN_BASE, quitSkin);
			if (GuiButton(new Rectangle(x, 250, 192, 64), GuiIconText(ICON_231, "Quit")) != 0) {
				break;
			}

			GuiSetSkinOnce(PROGRESSBAR, GUI_SKIN_FILL, redSkin);
			GuiProgressBar(new Rectangle(352, 340, 96, 16), "", "", [health], 0, 100);
			GuiSetSkinOnce(PROGRESSBAR, GUI_SKIN_FILL, blueSkin);
			GuiProgressBar(new Rectangle(352, 370, 96, 16), "", "", [experience], 0, 100);

			var on = soundIsOn;
			if (GuiTextureButton(new Rectangle(736, 16, 48, 48), on ? soundOn : soundOff, null, on ? soundOnPressed : soundOffPressed) != 0)
				soundIsOn = !soundIsOn;

			EndDrawing();
		}
		CloseWindow();
	}
}
