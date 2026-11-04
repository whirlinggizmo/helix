import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.extras.GuiSkin;
import helix.raylib.extras.GuiSkins.*;
import helix.raylib.extras.Textures.*;
import helix.raylib.extras.Text.*;

class Main {
	static var ready = 0;
	static var buttonTex:Texture2D;
	static var panelTex:Texture2D;
	static var font:Font;
	static var buttonSkin:GuiSkin;
	static var closeSkin:GuiSkin;
	static var panelSkin:GuiSkin;
	static var barSkin:GuiSkin;
	static var handleSkin:GuiSkin;
	static var volume:Array<Float> = [50];
	static var fullscreen:Array<Bool> = [false];

	static function cell(i:Int, shiftY:Int = 0, h:Int = 49):NPatchInfo
		return new NPatchInfo(new Rectangle(0, i * 49 + shiftY, 190, h), 14, 14, 14, 14, NPATCH_NINE_PATCH);

	static function build() {
		if (ready < 3)
			return;
		buttonSkin = GuiSkinFromTexture(buttonTex, cell(0), cell(1), cell(2, 4, 45), cell(3));
		closeSkin = GuiSkinFromTexture(buttonTex, cell(1));
		var p = new NPatchInfo(new Rectangle(0, 0, panelTex.width, panelTex.height), 16, 16, 16, 16, NPATCH_NINE_PATCH);
		panelSkin = GuiSkinFromTexture(panelTex, p);
		barSkin = GuiSkinFromTexture(buttonTex, cell(2, 4, 45));
		handleSkin = GuiSkinFromTexture(buttonTex, cell(0));
		GuiSetFont(font);
		GuiSetStyle(DEFAULT, TEXT_SIZE, 20);
		GuiSetSkin(BUTTON, GUI_SKIN_BASE, buttonSkin);
		GuiSetSkin(SLIDER, GUI_SKIN_BASE, panelSkin);
		GuiSetSkin(SLIDER, GUI_SKIN_FILL, barSkin);
		GuiSetSkin(SLIDER, GUI_SKIN_HANDLE, handleSkin);
	}

	static function frame() {
		BeginDrawing();
		ClearBackground(new Color(40, 46, 58, 255));
		if (ready >= 3) {
			var px = 220, py = 75;
			DrawTextureNPatch(panelTex, new NPatchInfo(new Rectangle(0, 0, panelTex.width, panelTex.height), 16, 16, 16, 16, NPATCH_NINE_PATCH),
				new Rectangle(px, py, 360, 300), new Vector2(0, 0), 0, WHITE);
			DrawTextEx(font, "WARDENS", new Vector2(px + 180 - MeasureTextEx(font, "WARDENS", 30, 1).x / 2, py + 22), 30, 1, WHITE);
			if (GuiButton(new Rectangle(px + 85, py + 70, 190, 40), "Play") != 0)
				trace("play");
			if (GuiButton(new Rectangle(px + 85, py + 120, 190, 40), "Options") != 0)
				fullscreen[0] = !fullscreen[0];
			GuiDisable();
			GuiButton(new Rectangle(px + 85, py + 170, 190, 40), "Quit");
			GuiEnable();
			GuiSlider(new Rectangle(px + 85, py + 225, 190, 24), "", "", volume, 0, 100);
			GuiCheckBox(new Rectangle(px + 85, py + 260, 20, 20), "Fullscreen", fullscreen);
			GuiSetSkin(BUTTON, GUI_SKIN_BASE, closeSkin);
			if (GuiButton(new Rectangle(px + 360 - 36, py + 8, 28, 28), "X") != 0)
				trace("close");
			GuiSetSkin(BUTTON, GUI_SKIN_BASE, buttonSkin);
		}
		EndDrawing();
	}

	static function main() {
		InitWindow(800, 450, "WARDENS");
		SetTargetFPS(60);
		LoadTextureAsync("assets/button.png", t -> { buttonTex = t; ready++; build(); });
		LoadTextureAsync("assets/panel.png", t -> { panelTex = t; ready++; build(); });
		LoadFontExAsync("assets/font.ttf", 20, null, 0, f -> { font = f; ready++; build(); });
		while (!WindowShouldClose())
			frame();
	}
}
