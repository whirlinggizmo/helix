import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.extras.GuiSkins.*;

/** Skins raygui's controls (`helix.raylib.extras.GuiSkins`): a settings panel of buttons, a slider, a checkbox and a progress bar, each
	part drawn from Kenney's UI Pack (CC0, `web/assets/License.txt`) as a nine-patch, so its corners keep their shape at any size, in the pack's font. The
	buttons take their four states from one sheet (`web/assets/button.png`: normal, focused, pressed, disabled, top down), their faces on a
	lip their text stays centered on, the pressed face pushed down onto it with its text. Each button shows an icon from the pack
	before its text, and a round button of images alone, which answers on its face and not its clear corners, sets the volume to
	full. The
	`quit_after_frame` option (`--quit_after_frame=60` natively, `?quit_after_frame=60` in a page) quits it after that frame. */
class Main {
	static function main():Void {
		InitWindow(800, 450, "helix-raylib: GUI skins");
		SetTargetFPS(60);
		// The skins are set once every texture has loaded, DEFAULT's first: a skin set on DEFAULT is set on every control too.
		var names = [
			"panel",
			"button",
			"rail",
			"rail_slider",
			"rail_fill",
			"handle",
			"check_box",
			"check",
			"icon_load",
			"icon_save",
			"icon_reset",
			"star_button",
			"star_button_pressed"
		];
		var textures = new Map<String, Texture2D>();
		for (name in names)
			LoadTextureAsync('assets/$name.png', t -> {
				textures.set(name, t);
				if (Lambda.count(textures) == names.length)
					skin(textures);
			});
		// The star button answers on its round face alone, its image's clear corners left out.
		var starMask:Null<Image> = null;
		LoadImageAsync("assets/star_button.png", image -> starMask = image);
		LoadFontExAsync("assets/font.ttf", 20, null, 0, font -> GuiSetFont(font));
		GuiSetStyle(DEFAULT, TEXT_SIZE, 20);
		for (state in [TEXT_COLOR_NORMAL, TEXT_COLOR_FOCUSED, TEXT_COLOR_PRESSED])
			GuiSetStyle(BUTTON, state, ColorToInt(WHITE));
		GuiSetStyle(SLIDER, SLIDER_WIDTH, 24);
		// The fill, the blue rail with its caps, laid over the grey rail's whole rectangle and shown up to the progress.
		GuiSetStyle(PROGRESSBAR, BORDER_WIDTH, 0);
		GuiSetStyle(PROGRESSBAR, PROGRESS_PADDING, 0);
		var volume = [0.6];
		var music = [true];
		// How much has loaded, from 0 to 1, rising while loading.
		var loaded = 0.4;
		var loading = false;
		while (!WindowShouldClose()) {
			BeginDrawing();
			ClearBackground(new Color(52, 152, 219, 255));
			GuiPanel(new Rectangle(200, 40, 400, 380), null);
			GuiLabel(new Rectangle(230, 60, 340, 30), "Settings");
			// A button of images: the star sets the volume to full.
			if (textures.exists("star_button")
				&& textures.exists("star_button_pressed")
				&& GuiTextureButton(new Rectangle(526, 52, 48, 48), textures["star_button"], null, textures["star_button_pressed"], null, starMask) == 1)
				volume[0] = 1;
			GuiSlider(new Rectangle(340, 106, 200, 32), "Volume", null, volume, 0, 1);
			GuiCheckBox(new Rectangle(230, 165, 32, 32), "Music", music);
			if (loading)
				loaded = Math.min(loaded + GetFrameTime() / 4, 1);
			GuiProgressBar(new Rectangle(340, 224, 200, 16), '${Math.round(loaded * 100)}%', null, [loaded], 0, 1);
			if (GuiButton(new Rectangle(230, 262, 160, 64), GuiIconText(ICON_229, "Load")) == 1) {
				loaded = 0;
				loading = true;
			}
			GuiDisable();
			GuiButton(new Rectangle(410, 262, 160, 64), GuiIconText(ICON_230, "Save"));
			GuiEnable();
			if (GuiButton(new Rectangle(230, 336, 340, 64), GuiIconText(ICON_231, "Reset")) == 1) {
				loaded = 0;
				loading = false;
			}
			EndDrawing();
		}
		CloseWindow();
	}

	// Each control's skins from the loaded textures, DEFAULT's first.
	static function skin(t:Map<String, Texture2D>):Void {
		GuiSetSkin(DEFAULT, GUI_SKIN_BASE, GuiSkinFromTexture(t["panel"], patch(t["panel"], 16)));
		// The buttons' faces sit on a lip 4 texels deep, the pressed face pushed down onto it, the text moving with the face.
		GuiSetSkin(BUTTON, GUI_SKIN_BASE, GuiSkinFromSheet(t["button"], 192, 64, 16, 16, 16, 20, 4));
		GuiSetSkin(SLIDER, GUI_SKIN_BASE, GuiSkinFromTexture(t["rail_slider"], caps(t["rail_slider"], 16)));
		GuiSetSkin(SLIDER, GUI_SKIN_HANDLE, GuiSkinFromTexture(t["handle"], patch(t["handle"], 0)));
		GuiSetSkin(PROGRESSBAR, GUI_SKIN_BASE, GuiSkinFromTexture(t["rail"], caps(t["rail"], 16)));
		var fill = GuiSkinFromTexture(t["rail_fill"], caps(t["rail_fill"], 16));
		fill.fillMode = GUI_SKIN_FILL_CLIPPED;
		GuiSetSkin(PROGRESSBAR, GUI_SKIN_FILL, fill);
		GuiSetSkin(CHECKBOX, GUI_SKIN_BASE, GuiSkinFromTexture(t["check_box"], patch(t["check_box"], 8)));
		GuiSetSkin(CHECKBOX, GUI_SKIN_FILL, GuiSkinFromTexture(t["check"], patch(t["check"], 0)));
		// The buttons' icons, drawn from the pack's in place of raygui's spare icons 229 to 231.
		GuiSetIconTexture(ICON_229, t["icon_load"]);
		GuiSetIconTexture(ICON_230, t["icon_save"]);
		GuiSetIconTexture(ICON_231, t["icon_reset"]);
	}

	// A whole texture as a three-patch across, its caps cap texels wide, drawn at the texture's own height so they keep their shape.
	static function caps(texture:Texture2D, cap:Int):NPatchInfo
		return new NPatchInfo(new Rectangle(0, 0, texture.width, texture.height), cap, 0, cap, 0, NPATCH_THREE_PATCH_HORIZONTAL);

	// A whole texture as a nine-patch, its borders border texels wide.
	static function patch(texture:Texture2D, border:Int):NPatchInfo
		return new NPatchInfo(new Rectangle(0, 0, texture.width, texture.height), border, border, border, border);
}
