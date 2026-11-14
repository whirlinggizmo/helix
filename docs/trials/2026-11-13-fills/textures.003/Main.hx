import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.*;
import helix.raylib.extras.GuiSkins.*;
import helix.raylib.extras.GuiSkin;
import helix.raylib.extras.Textures.*;
import helix.raylib.extras.TextureAtlas;

class Main {
	static var target:RenderTexture2D;
	static var barGrey:Texture2D;
	static var barRed:Texture2D;
	static var barTip:Texture2D;
	static var ballGlass:Texture2D;
	static var ballMana:Texture2D;
	static var froth:Texture2D;
	static var icon:Texture2D;
	static var gauge:Texture2D;
	static var rope:Texture2D;
	static var stone:Texture2D;
	static var portrait:Texture2D;
	static var atlas:TextureAtlas;
	static var pending = 12;

	static function load(path:String, set:Texture2D->Void) {
		LoadTextureAsync(path, t -> {
			set(t);
			pending--;
		});
	}

	static function tri(t:Float, period:Float):Float {
		var p = (t % period) / period;
		return p < 0.5 ? p * 2 : 2 - p * 2;
	}

	static function main() {
		InitWindow(1280, 720, "Status widgets");
		SetTargetFPS(60);
		target = LoadRenderTexture(640, 360);

		load("assets/bar_grey.png", t -> barGrey = t);
		load("assets/bar_red.png", t -> barRed = t);
		load("assets/bar_tip.png", t -> barTip = t);
		load("assets/ball_glass.png", t -> ballGlass = t);
		load("assets/ball_mana.png", t -> ballMana = t);
		load("assets/froth.png", t -> froth = t);
		load("assets/icon.png", t -> icon = t);
		load("assets/gauge.png", t -> gauge = t);
		load("assets/rope_frame.png", t -> {
			rope = t;
			GuiSetSkin(DEFAULT, GUI_SKIN_BASE,
				GuiSkinFromTexture(t, new NPatchInfo(new Rectangle(0, 0, 96, 96), 24, 24, 24, 24, NPATCH_NINE_PATCH), null, null, null, null,
					NPATCH_MODE_TILE, NPATCH_MODE_TILE));
		});
		load("assets/stone.png", t -> stone = t);
		load("assets/portrait.png", t -> portrait = t);
		LoadTextureAtlasAsync("assets/icons.xml", a -> {
			atlas = a;
			pending--;
		});

		var barsSet = false;
		var fit = new Rectangle(0, 0, 0, 0);
		var hex:Array<Vector2> = [for (i in 0...6) new Vector2(0, 0)];
		var hexUv:Array<Vector2> = [for (i in 0...6) new Vector2(0, 0)];
		var edge = new Vector3(0, 0, 0);
		var healthVal = [0.0];

		while (!WindowShouldClose()) {
			var t = GetTime();
			// wait for all assets
			var ready = pending == 0;
			if (ready && !barsSet) {
				barsSet = true;
				GuiSetSkin(PROGRESSBAR, GUI_SKIN_BASE, GuiSkinFromTexture(barGrey, new NPatchInfo(new Rectangle(0, 0, 96, 16), 16, 0, 16, 0, NPATCH_THREE_PATCH_HORIZONTAL)));
				GuiSetSkin(PROGRESSBAR, GUI_SKIN_FILL, GuiSkinFromTexture(barRed, new NPatchInfo(new Rectangle(0, 0, 96, 16), 16, 0, 16, 0, NPATCH_THREE_PATCH_HORIZONTAL)));
				GuiSetSkin(PROGRESSBAR, GUI_SKIN_FILL_EDGE, GuiSkinFromTexture(barTip, new NPatchInfo(new Rectangle(0, 0, 16, 16), 0, 0, 0, 0, NPATCH_NINE_PATCH)));
				GuiSetSkinFillMode(PROGRESSBAR, GUI_SKIN_FILL_CLIPPED);
			}

			// the mouse answers in the render texture's coordinates
			GetRenderTextureFitRect(target, false, fit);
			SetMouseOffset(Std.int(-fit.x), Std.int(-fit.y));
			SetMouseScale(640 / fit.width, 360 / fit.height);

			BeginTextureMode(target);
			ClearBackground(BLACK);
			if (ready) {
				DrawTextureTiled(stone, new Rectangle(0, 0, 64, 64), new Rectangle(0, 0, 640, 360), new Vector2(0, 0), 0, 0.5, WHITE);

				GuiPanel(new Rectangle(20, 20, 600, 320), null);

				// portrait in a hexagon beside the health bar
				var c = new Vector2(70, 70);
				for (i in 0...6) {
					var a = (i * 60 - 90) * Math.PI / 180;
					hex[i].x = c.x + Math.cos(a) * 48;
					hex[i].y = c.y + Math.sin(a) * 48;
					hexUv[i].x = 0.5 + Math.cos(a) * 0.5;
					hexUv[i].y = 0.5 + Math.sin(a) * 0.5;
				}
				DrawTexturePoly(portrait, c, hex, hexUv, 6, WHITE);

				var health = tri(t, 10);
				healthVal[0] = health * 100;
				GuiProgressBar(new Rectangle(130, 62, 192, 32), null, null, healthVal, 0, 100);

				// mana ball
				var mana = tri(t, 6);
				var ball = new Rectangle(60, 160, 128, 128);
				DrawTextureFill(ballMana, new Rectangle(0, 0, 128, 128), ball, mana, TEXTURE_FILL_BOTTOM_TO_TOP, WHITE);
				DrawTexturePro(ballGlass, new Rectangle(0, 0, 128, 128), ball, new Vector2(0, 0), 0, WHITE);
				GetTextureFillEdge(ball, mana, TEXTURE_FILL_BOTTOM_TO_TOP, edge);
				DrawTexture(froth, Std.int(edge.x - froth.width / 2), Std.int(edge.y - froth.height / 2), WHITE);

				// cooldown
				var cool = (t % 3) / 3;
				var ic = new Rectangle(240, 180, 64, 64);
				DrawTexturePro(icon, new Rectangle(0, 0, 64, 64), ic, new Vector2(0, 0), 0, GRAY);
				DrawTextureFill(icon, new Rectangle(0, 0, 64, 64), ic, cool, TEXTURE_FILL_CLOCKWISE, WHITE);

				// speed gauge: the dial's top half, swept 180 degrees from the left end (270 deg clockwise from up)
				var speed = tri(t, 8);
				// the texture is the half circle; its full circle is twice as tall, centered on the bottom edge
				var full = new Rectangle(380, 130, 200, 200);
				DrawTextureFillEx(gauge, new Rectangle(0, 0, 200, 100), full, speed, TEXTURE_FILL_CLOCKWISE, 270, 180, WHITE);
				GetTextureFillEdgeEx(full, speed, TEXTURE_FILL_CLOCKWISE, 270, 180, edge);
				DrawLineEx(new Vector2(480, 230), new Vector2(edge.x, edge.y), 3, RED);

				// icon row
				var names = ["sword", "shield", "potion", "bow"];
				for (i in 0...4) {
					var src = GetTextureAtlasRect(atlas, names[i]);
					DrawTexturePro(atlas.texture, src, new Rectangle(380 + i * 52, 260, 48, 48), new Vector2(0, 0), 0, WHITE);
				}
			}
			EndTextureMode();

			BeginDrawing();
			ClearBackground(BLACK);
			DrawRenderTextureFit(target, false, WHITE);
			EndDrawing();
		}
		CloseWindow();
	}
}
