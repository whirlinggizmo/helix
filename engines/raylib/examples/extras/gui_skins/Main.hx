import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.extras.GuiSkins.*;

/** Skins raygui's controls (`helix.raylib.extras.GuiSkins`): a settings panel of buttons, a slider, a checkbox and a progress bar, each
	part drawn from Kenney's UI Pack (CC0, `web/assets/License.txt`) as a nine-patch, so its corners keep their shape at any size, in the pack's font. The
	buttons take their four states from one sheet (`web/assets/button.png`: normal, focused, pressed, disabled, top down). The
	`quit_after_frame` option (`--quit_after_frame=60` natively, `?quit_after_frame=60` in a page) quits it after that frame. */
class Main {
	static function main():Void {
		InitWindow(800, 450, "helix-raylib: GUI skins");
		SetTargetFPS(60);
		// The skins are set once every texture has loaded, DEFAULT's first: a skin set on DEFAULT is set on every control too.
		var names = ["panel", "button", "rail", "rail_slider", "rail_fill", "handle", "check_box", "check"];
		var textures = new Map<String, Texture2D>();
		for (name in names)
			LoadTextureAsync('assets/$name.png', t -> {
				textures.set(name, t);
				if (Lambda.count(textures) == names.length)
					skin(textures);
			});
		LoadFontExAsync("assets/font.ttf", 20, null, 0, font -> GuiSetFont(font));
		GuiSetStyle(DEFAULT, TEXT_SIZE, 20);
		for (state in [TEXT_COLOR_NORMAL, TEXT_COLOR_FOCUSED, TEXT_COLOR_PRESSED])
			GuiSetStyle(BUTTON, state, ColorToInt(WHITE));
		GuiSetStyle(SLIDER, SLIDER_WIDTH, 24);
		// The fill, the blue rail with its caps, laid over the grey rail's whole rectangle up to the progress.
		GuiSetStyle(PROGRESSBAR, BORDER_WIDTH, 0);
		GuiSetStyle(PROGRESSBAR, PROGRESS_PADDING, 0);
		var volume = [0.6];
		var music = [true];
		var saved = 40;
		while (!WindowShouldClose()) {
			BeginDrawing();
			ClearBackground(new Color(52, 152, 219, 255));
			GuiPanel(new Rectangle(200, 40, 400, 380), null);
			GuiLabel(new Rectangle(230, 60, 340, 30), "Settings");
			GuiSlider(new Rectangle(340, 106, 200, 32), "Volume", null, volume, 0, 1);
			GuiCheckBox(new Rectangle(230, 165, 32, 32), "Music", music);
			GuiProgressBar(new Rectangle(340, 224, 200, 16), "Saved", null, [saved / 100], 0, 1);
			if (GuiButton(new Rectangle(230, 262, 160, 64), "Save") == 1)
				saved = 100;
			GuiDisable();
			GuiButton(new Rectangle(410, 262, 160, 64), "Load");
			GuiEnable();
			if (GuiButton(new Rectangle(230, 336, 340, 64), "Back") == 1)
				saved = 0;
			EndDrawing();
		}
		CloseWindow();
	}

	// Each control's skins from the loaded textures, DEFAULT's first.
	static function skin(t:Map<String, Texture2D>):Void {
		GuiSetSkin(DEFAULT, GUI_SKIN_BASE, GuiSkinFromTexture(t["panel"], patch(t["panel"], 16)));
		GuiSetSkin(BUTTON, GUI_SKIN_BASE, GuiSkinFromSheet(t["button"], 192, 64, 16, 16, 16, 20));
		GuiSetSkin(SLIDER, GUI_SKIN_BASE, GuiSkinFromTexture(t["rail_slider"], caps(t["rail_slider"], 16)));
		GuiSetSkin(SLIDER, GUI_SKIN_HANDLE, GuiSkinFromTexture(t["handle"], patch(t["handle"], 0)));
		GuiSetSkin(PROGRESSBAR, GUI_SKIN_BASE, GuiSkinFromTexture(t["rail"], caps(t["rail"], 16)));
		GuiSetSkin(PROGRESSBAR, GUI_SKIN_FILL, GuiSkinFromTexture(t["rail_fill"], caps(t["rail_fill"], 16)));
		GuiSetSkin(CHECKBOX, GUI_SKIN_BASE, GuiSkinFromTexture(t["check_box"], patch(t["check_box"], 8)));
		GuiSetSkin(CHECKBOX, GUI_SKIN_FILL, GuiSkinFromTexture(t["check"], patch(t["check"], 0)));
	}

	// A whole texture as a three-patch across, its caps cap texels wide, drawn at the texture's own height so they keep their shape.
	static function caps(texture:Texture2D, cap:Int):NPatchInfo
		return new NPatchInfo(new Rectangle(0, 0, texture.width, texture.height), cap, 0, cap, 0, NPATCH_THREE_PATCH_HORIZONTAL);

	// A whole texture as a nine-patch, its borders border texels wide.
	static function patch(texture:Texture2D, border:Int):NPatchInfo
		return new NPatchInfo(new Rectangle(0, 0, texture.width, texture.height), border, border, border, border);
}
