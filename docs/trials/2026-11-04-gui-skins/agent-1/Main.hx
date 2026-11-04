import helix.raylib.Raylib;
import helix.raylib.extras.Textures.*;
import helix.raylib.extras.Text.*;
import helix.raylib.Texture2D;
import helix.raylib.Font;
import helix.raylib.Rectangle;
import helix.raylib.Color;
import helix.raylib.Vector2;
import helix.raylib.NPatchInfo;
import helix.raylib.extras.GuiSkin;
import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.extras.GuiSkins.*;

class Main {
	static var panelTex:Texture2D;
	static var buttonTex:Texture2D;
	static var font:Font;
	static var ready = false;
	static var volume = [50.0];
	static var fullscreenOpt = [false];
	static var showFullscreen = false;
	static var panelSkin:GuiSkin;
	static var buttonSkin:GuiSkin;
	static var closeSkin:GuiSkin;

	static function cell(i:Int):NPatchInfo {
		return {
			source: new Rectangle(0, i * 49, 190, 49),
			left: 14, top: 14, right: 14, bottom: 14,
			layout: NPATCH_NINE_PATCH
		};
	}

	static function main() {
		InitWindow(800, 450, "WARDENS");
		SetTargetFPS(60);
		LoadTextureAsync("assets/panel.png", function(t) { panelTex = t; check(); });
		LoadTextureAsync("assets/button.png", function(t) { buttonTex = t; check(); });
		LoadFontExAsync("assets/font.ttf", 20, null, 0, function(f) { font = f; check(); });
		while (!WindowShouldClose()) frame();
	}

	static function check() {
		if (panelTex == null || buttonTex == null || font == null) return;
		panelSkin = GuiSkinFromTexture(panelTex, {
			source: new Rectangle(0, 0, panelTex.width, panelTex.height),
			left: 16, top: 16, right: 16, bottom: 16, layout: NPATCH_NINE_PATCH
		});
		buttonSkin = GuiSkinFromTexture(buttonTex, cell(0), cell(1), cell(2), cell(3));
		closeSkin = GuiSkinFromTexture(buttonTex, cell(1));
		var pressedSkin = GuiSkinFromTexture(buttonTex, cell(2));
		var normalSkin = GuiSkinFromTexture(buttonTex, cell(0));
		GuiSetSkin(BUTTON, GUI_SKIN_BASE, buttonSkin);
		GuiSetSkin(SLIDER, GUI_SKIN_BASE, panelSkin);
		GuiSetSkin(SLIDER, GUI_SKIN_FILL, pressedSkin);
		GuiSetSkin(SLIDER, GUI_SKIN_HANDLE, normalSkin);
		GuiSetFont(font);
		GuiSetStyle(DEFAULT, TEXT_SIZE, 20);
		ready = true;
	}

	static function frame() {
		BeginDrawing();
		ClearBackground(new Color(36, 42, 54, 255));
		if (ready) {
			var px = (800 - 360) / 2;
			var py = (450 - 300) / 2;
			DrawTextureNPatch(panelTex, {
				source: new Rectangle(0, 0, panelTex.width, panelTex.height),
				left: 16, top: 16, right: 16, bottom: 16, layout: NPATCH_NINE_PATCH
			}, new Rectangle(px, py, 360, 300), new Vector2(0, 0), 0, WHITE);
			DrawTextEx(font, "WARDENS", new Vector2(px + 180 - MeasureTextEx(font, "WARDENS", 20, 1).x / 2, py + 20), 20, 1, WHITE);

			var bx = px + 85;
			if (GuiButton(new Rectangle(bx, py + 55, 190, 49), "Play") != 0) trace("play");
			if (GuiButton(new Rectangle(bx, py + 110, 190, 49), "Options") != 0) showFullscreen = !showFullscreen;
			GuiDisable();
			GuiButton(new Rectangle(bx, py + 165, 190, 49), "Quit");
			GuiEnable();

			GuiSlider(new Rectangle(bx, py + 225, 190, 24), "", "", volume, 0, 100);
			if (showFullscreen)
				GuiCheckBox(new Rectangle(bx, py + 260, 20, 20), "Fullscreen", fullscreenOpt);

			GuiSetSkin(BUTTON, GUI_SKIN_BASE, closeSkin);
			if (GuiButton(new Rectangle(px + 360 - 36, py + 8, 28, 28), "X") != 0) trace("close");
			GuiSetSkin(BUTTON, GUI_SKIN_BASE, buttonSkin);
		}
		EndDrawing();
	}
}
