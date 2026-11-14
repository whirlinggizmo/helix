import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.extras.GuiSkins.*;

/** Skins raygui's buttons (`helix.raylib.extras.GuiSkins`): a texture made at start, a rounded frame, drawn as a nine-patch so its
	corners keep their shape however wide the button is. The `quit_after_frame` option (`--quit_after_frame=60` natively,
	`?quit_after_frame=60` in a page) quits it after that frame. */
class Main {
	static function main():Void {
		InitWindow(800, 450, "helix-raylib: GUI skins");
		SetTargetFPS(60);
		// A 48 x 48 frame: an orange border 12 texels wide, a cream middle.
		var image = GenImageColor(48, 48, ORANGE);
		ImageDrawRectangle(image, 12, 12, 24, 24, BEIGE);
		var texture = LoadTextureFromImage(image);
		UnloadImage(image);
		GuiSetSkin(BUTTON, GUI_SKIN_BASE, GuiSkinFromTexture(texture, new NPatchInfo(new Rectangle(0, 0, 48, 48), 12, 12, 12, 12)));
		GuiSetStyle(DEFAULT, TEXT_SIZE, 20);
		var presses = 0;
		while (!WindowShouldClose()) {
			BeginDrawing();
			ClearBackground(RAYWHITE);
			if (GuiButton(new Rectangle(40, 60, 200, 60), "Play") == 1)
				presses++;
			GuiButton(new Rectangle(40, 150, 420, 60), "A wide button keeps its corners");
			DrawText('pressed $presses times', 40, 240, 20, DARKGRAY);
			EndDrawing();
		}
		UnloadTexture(texture);
		CloseWindow();
	}
}
