import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.TextureAtlas;
import helix.raylib.extras.Textures.*;

/** Draws a game's status widgets with `helix.raylib.extras.Textures`, at 640 x 360 in a render texture fitted to the window: a health
	bar filled up to the health with a tip at its end, a cooldown sweeping clockwise over an icon, a half-circle gauge with a needle at
	its edge, a stone floor tiled, a frame whose edges repeat, a portrait in a hexagon, and four icons from an atlas
	(`web/assets/icons.xml`). The mouse is read in the render texture's pixels, and a cursor from Kenney's Cursor Pack (CC0,
	`web/assets/License.txt`) is drawn over the fitted render texture where it is. The `quit_after_frame` option
	(`--quit_after_frame=60` natively, `?quit_after_frame=60` in a page) quits it after that frame. */
class Main {
	static function main():Void {
		SetConfigFlags(FLAG_WINDOW_RESIZABLE);
		InitWindow(1280, 720, "helix-raylib: textures");
		SetTargetFPS(60);
		var target = LoadRenderTexture(640, 360);
		var stone = texture(GenImageChecked(32, 32, 16, 16, new Color(70, 70, 80, 255), new Color(85, 85, 95, 255)));
		var bar = texture(GenImageGradientLinear(200, 20, 90, MAROON, RED));
		var tip = texture(GenImageGradientRadial(12, 24, 0, WHITE, new Color(255, 255, 255, 0)));
		// The gauge's dial: a ring, its top half drawn.
		var dialImage = GenImageColor(160, 160, BLANK);
		ImageDrawCircle(dialImage, 80, 80, 78, ORANGE);
		ImageDrawCircle(dialImage, 80, 80, 74, GOLD);
		ImageDrawCircle(dialImage, 80, 80, 46, ORANGE);
		ImageDrawCircle(dialImage, 80, 80, 42, new Color(40, 30, 20, 255));
		var dial = texture(dialImage);
		var portrait = texture(GenImageGradientLinear(96, 96, 45, SKYBLUE, DARKBLUE));
		var frameImage = GenImageColor(48, 48, BROWN);
		ImageDrawRectangle(frameImage, 12, 12, 24, 24, new Color(40, 30, 20, 255));
		// Studs every 12 pixels along each edge, the corners' included, so the edges' repeats run on unbroken.
		for (i in 0...4) {
			var at = 6 + i * 12;
			for (stud in [[at, 6], [at, 42], [6, at], [42, at]])
				ImageDrawCircle(frameImage, stud[0], stud[1], 3, BEIGE);
		}
		var frame = texture(frameImage);
		var framePatch = new NPatchInfo(new Rectangle(0, 0, 48, 48), 12, 12, 12, 12, NPATCH_NINE_PATCH);
		var cursor:Null<Texture2D> = null;
		LoadTextureAsync("assets/cursor.png", loaded -> cursor = loaded);
		HideCursor();
		var atlas:Null<TextureAtlas> = null;
		LoadTextureAtlasAsync("assets/icons.xml", loaded -> atlas = loaded);
		var hexagon = [for (i in 0...6) new Vector2(0, 0)];
		var hexagonCoords = [
			for (i in 0...6)
				new Vector2(0.5 + 0.5 * Math.cos(i * Math.PI / 3 - Math.PI / 2), 0.5 + 0.5 * Math.sin(i * Math.PI / 3 - Math.PI / 2))
		];
		var edge = new Vector3(0, 0, 0);
		var zero = new Vector2(0, 0);
		var icon = new Rectangle(0, 0, 0, 0);
		var fitted = new Rectangle(0, 0, 0, 0);
		while (!WindowShouldClose()) {
			var time = GetTime();
			var health = 0.5 + 0.5 * Math.sin(time * 0.8);
			var cooldown = (time * 0.4) % 1;
			var speed = 0.5 + 0.5 * Math.sin(time * 1.3);
			SetMouseRenderTextureFit(target, false);
			var mouse = GetMousePosition();

			BeginTextureMode(target);
			ClearBackground(BLACK);
			DrawTextureTiled(stone, new Rectangle(0, 0, 32, 32), new Rectangle(0, 0, 640, 360), zero, 0, 1, WHITE);
			DrawTextureNPatchEx(frame, framePatch, new Rectangle(16, 16, 608, 328), zero, 0, NPATCH_MODE_TILE, NPATCH_MODE_TILE, WHITE);

			// The health bar, filled up to the health, its tip at the fill's end.
			var barRectangle = new Rectangle(48, 48, 200, 20);
			DrawRectangleRec(barRectangle, new Color(30, 10, 10, 255));
			DrawTextureFill(bar, new Rectangle(0, 0, 200, 20), barRectangle, health, TEXTURE_FILL_LEFT_TO_RIGHT, WHITE);
			GetTextureFillEdge(barRectangle, health, TEXTURE_FILL_LEFT_TO_RIGHT, edge);
			DrawTexture(tip, Std.int(edge.x - tip.width / 2), Std.int(edge.y - tip.height / 2), WHITE);

			// The gauge: a half circle about its hub at the bottom's middle, from the left round to the right, and a needle at its edge.
			var gaugeRectangle = new Rectangle(380, 60, 160, 80);
			var hub = new Vector2(80, 80);
			DrawTextureFillEx(dial, new Rectangle(0, 0, 160, 80), gaugeRectangle, 1, TEXTURE_FILL_CLOCKWISE, hub, 270, 180, new Color(80, 80, 80, 255));
			DrawTextureFillEx(dial, new Rectangle(0, 0, 160, 80), gaugeRectangle, speed, TEXTURE_FILL_CLOCKWISE, hub, 270, 180, WHITE);
			GetTextureFillEdgeEx(gaugeRectangle, speed, TEXTURE_FILL_CLOCKWISE, hub, 270, 180, edge);
			var angle = edge.z * Math.PI / 180;
			DrawLineEx(new Vector2(edge.x, edge.y), new Vector2(edge.x + 70 * Math.sin(angle), edge.y - 70 * Math.cos(angle)), 3, WHITE);

			// The portrait in a hexagon.
			for (i in 0...6) {
				var a = i * Math.PI / 3 - Math.PI / 2;
				hexagon[i].x = 96 + 48 * Math.cos(a);
				hexagon[i].y = 200 + 48 * Math.sin(a);
			}
			DrawTexturePoly(portrait, new Vector2(96, 200), hexagon, hexagonCoords, 6, WHITE);

			// The atlas's icons, the first under a cooldown sweeping clockwise.
			if (atlas != null)
				for (i in 0...atlas.names.length) {
					GetTextureAtlasRectangle(atlas, atlas.names[i], icon);
					var place = new Rectangle(200 + i * 80, 200, 64, 64);
					if (i == 0) {
						DrawTexturePro(atlas.texture, icon, place, zero, 0, DARKGRAY);
						DrawTextureFill(atlas.texture, icon, place, cooldown, TEXTURE_FILL_CLOCKWISE, WHITE);
					} else
						DrawTexturePro(atlas.texture, icon, place, zero, 0, WHITE);
				}
			EndTextureMode();

			BeginDrawing();
			ClearBackground(new Color(20, 20, 26, 255));
			DrawRenderTextureFit(target, false, WHITE);
			// The cursor at its own size over the fitted render texture, centered where the mouse is.
			if (cursor != null) {
				GetRenderTextureFitRectangle(target, false, fitted);
				var x = fitted.x + mouse.x * fitted.width / target.texture.width;
				var y = fitted.y + mouse.y * fitted.height / target.texture.height;
				DrawTexture(cursor, Std.int(x - cursor.width / 2), Std.int(y - cursor.height / 2), WHITE);
			}
			EndDrawing();
		}
		UnloadRenderTexture(target);
		if (atlas != null)
			UnloadTextureAtlas(atlas);
		if (cursor != null)
			UnloadTexture(cursor);
		CloseWindow();
	}

	// A texture of an image, the image unloaded.
	static function texture(image:Image):Texture2D {
		var t = LoadTextureFromImage(image);
		UnloadImage(image);
		return t;
	}
}
