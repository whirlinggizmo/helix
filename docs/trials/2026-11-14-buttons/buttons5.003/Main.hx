import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.*;
import helix.raylib.extras.GuiSkins.*;
import helix.raylib.extras.GuiSkin;

class Main {
	static var buttonSkin:GuiSkin;
	static var quitSkin:GuiSkin;
	static var barBase:GuiSkin;
	static var healthFill:GuiSkin;
	static var expFill:GuiSkin;

	static var button:Texture2D;
	static var quit:Texture2D;
	static var icons:Texture2D;
	static var soundOn:Texture2D;
	static var soundOnPressed:Texture2D;
	static var soundOff:Texture2D;
	static var soundOffPressed:Texture2D;
	static var barGrey:Texture2D;
	static var barRed:Texture2D;
	static var barBlue:Texture2D;
	static var barTip:Texture2D;
	static var soundMask:Image;

	static var loaded = 0;
	static inline var TOTAL = 12;

	static var health:Array<Float> = [0.0];
	static var exp:Array<Float> = [0.0];
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

	static function load(path:String, set:Texture2D->Void):Void {
		LoadTextureAsync(path, t -> {
			set(t);
			loaded++;
			if (loaded == TOTAL)
				buildSkins();
		});
	}

	static function buildSkins():Void {
		buttonSkin = GuiSkinFromSheet(button, 192, 64, 16, 16, 16, 20, 4, 0);
		quitSkin = GuiSkinFromSheet(quit, 192, 64, 16, 16, 16, 20, 4, 2);
		GuiSetSkin(BUTTON, GUI_SKIN_BASE, buttonSkin);

		var grey = threePatch(96, 16, 16);
		barBase = GuiSkinFromTexture(barGrey, grey);
		healthFill = GuiSkinFromTexture(barRed, threePatch(96, 16, 16));
		healthFill.fillMode = GUI_SKIN_FILL_CLIPPED;
		healthFill.fillEdge = barTip;
		expFill = GuiSkinFromTexture(barBlue, threePatch(96, 16, 16));
		GuiSetSkin(PROGRESSBAR, GUI_SKIN_BASE, barBase);

		GuiSetIconTexture(ICON_229, icons, new Rectangle(0, 0, 24, 24));
		GuiSetIconTexture(ICON_230, icons, new Rectangle(24, 0, 24, 24));
		GuiSetIconTexture(ICON_231, icons, new Rectangle(48, 0, 24, 24));
	}

	static function main():Void {
		InitWindow(800, 450, "Main menu");
		SetTargetFPS(60);

		load("assets/button.png", t -> button = t);
		load("assets/button_quit.png", t -> quit = t);
		load("assets/icons.png", t -> icons = t);
		load("assets/sound_on.png", t -> soundOn = t);
		load("assets/sound_on_pressed.png", t -> soundOnPressed = t);
		load("assets/sound_off.png", t -> soundOff = t);
		load("assets/sound_off_pressed.png", t -> soundOffPressed = t);
		load("assets/bar_grey.png", t -> barGrey = t);
		load("assets/bar_red.png", t -> barRed = t);
		load("assets/bar_blue.png", t -> barBlue = t);
		load("assets/bar_tip.png", t -> barTip = t);
		LoadImageAsync("assets/sound_on.png", i -> {
			soundMask = i;
			loaded++;
			if (loaded == TOTAL)
				buildSkins();
		});

		while (!WindowShouldClose()) {
			var t:Float = GetTime();
			// health: 0 -> 100 -> 0, one cycle in 10 s
			var phase = (t % 10.0) / 5.0;
			health[0] = (phase <= 1.0 ? phase : 2.0 - phase) * 100.0;
			exp[0] = Math.min(t / 20.0, 1.0) * 100.0;

			BeginDrawing();
			ClearBackground(RAYWHITE);

			if (loaded == TOTAL) {
				if (GuiButton(new Rectangle(304, 100, 192, 64), GuiIconText(ICON_229, "Play")) != 0)
					played = true;

				if (!played)
					GuiDisable();
				GuiButton(new Rectangle(304, 180, 192, 64), GuiIconText(ICON_230, "Options"));
				if (!played)
					GuiEnable();

				GuiSetSkinOnce(BUTTON, GUI_SKIN_BASE, quitSkin);
				if (GuiButton(new Rectangle(304, 260, 192, 64), GuiIconText(ICON_231, "Quit")) != 0)
					break;

				GuiSetSkinOnce(PROGRESSBAR, GUI_SKIN_FILL, healthFill);
				GuiProgressBar(new Rectangle(352, 350, 96, 16), "", "", health, 0, 100);
				GuiSetSkinOnce(PROGRESSBAR, GUI_SKIN_FILL, expFill);
				GuiProgressBar(new Rectangle(352, 380, 96, 16), "", "", exp, 0, 100);

				var on = soundEnabled;
				if (GuiTextureButton(new Rectangle(736, 16, 48, 48), on ? soundOn : soundOff, null, on ? soundOnPressed : soundOffPressed, null, soundMask) != 0)
					soundEnabled = !soundEnabled;
			}
			EndDrawing();
		}
		CloseWindow();
	}
}
