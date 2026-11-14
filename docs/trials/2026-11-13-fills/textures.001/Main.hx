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
	static var ropeFrame:Texture2D;
	static var stone:Texture2D;
	static var portrait:Texture2D;
	static var atlas:TextureAtlas;
	static var healthV:Array<Float> = [0];
	static var pending = 0;
	static var ready = false;
	static var skinsSet = false;

	static function load(path:String, set:Texture2D->Void) {
		pending++;
		LoadTextureAsync(path, t -> {
			set(t);
			pending--;
		});
	}

	static function tri(t:Float, period:Float):Float {
		var p = (t % period) / period;
		return p < 0.5 ? p * 2 : 2 - p * 2;
	}

	static function setSkins() {
		var rope = new NPatchInfo(new Rectangle(0, 0, 96, 96), 24, 24, 24, 24, NPATCH_NINE_PATCH);
		GuiSetSkin(DEFAULT, GUI_SKIN_BASE, GuiSkinFromTexture(ropeFrame, rope, null, null, null, WHITE, NPATCH_MODE_TILE, NPATCH_MODE_TILE));

		var box = new NPatchInfo(new Rectangle(0, 0, 96, 16), 16, 0, 16, 0, NPATCH_THREE_PATCH_HORIZONTAL);
		var fill = new NPatchInfo(new Rectangle(0, 0, 96, 16), 16, 0, 16, 0, NPATCH_THREE_PATCH_HORIZONTAL);
		var tip = new NPatchInfo(new Rectangle(0, 0, 16, 16), 0, 0, 0, 0, NPATCH_NINE_PATCH);
		GuiSetSkin(PROGRESSBAR, GUI_SKIN_BASE, GuiSkinFromTexture(barGrey, box));
		GuiSetSkin(PROGRESSBAR, GUI_SKIN_FILL, GuiSkinFromTexture(barRed, fill));
		GuiSetSkin(PROGRESSBAR, GUI_SKIN_FILL_EDGE, GuiSkinFromTexture(barTip, tip));
		GuiSetSkinFillMode(PROGRESSBAR, GUI_SKIN_FILL_CLIPPED);
		skinsSet = true;
	}

	static function hexagon(cx:Float, cy:Float, r:Float) {
		var pts:Array<Vector2> = [];
		var uvs:Array<Vector2> = [];
		for (i in 0...6) {
			var a = Math.PI / 3 * i;
			pts.push(new Vector2(cx + Math.cos(a) * r, cy + Math.sin(a) * r));
			uvs.push(new Vector2(0.5 + Math.cos(a) * 0.5, 0.5 + Math.sin(a) * 0.5));
		}
		// close the fan back to the first point
		pts.push(pts[0]);
		uvs.push(uvs[0]);
		DrawTexturePoly(portrait, new Vector2(cx, cy), pts, uvs, 7, WHITE);
	}

	static function frame() {
		var t = GetTime();
		if (!ready) {
			ready = pending == 0 && atlas != null && stone != null;
			BeginDrawing();
			ClearBackground(BLACK);
			DrawText("Loading...", 10, 10, 20, WHITE);
			EndDrawing();
			return;
		}
		if (!skinsSet)
			setSkins();

		var fit = GetRenderTextureFitRect(target, false);
		SetMouseOffset(-Std.int(fit.x), -Std.int(fit.y));
		SetMouseScale(640 / fit.width, 360 / fit.height);

		var health = tri(t, 10);
		var mana = tri(t, 6);
		var cooldown = (t % 3) / 3;
		var speed = tri(t, 8);

		BeginTextureMode(target);
		ClearBackground(BLACK);

		// background
		DrawTextureTiled(stone, new Rectangle(0, 0, 64, 64), new Rectangle(0, 0, 640, 360), new Vector2(0, 0), 0, 0.5, WHITE);

		// panel
		GuiPanel(new Rectangle(10, 10, 620, 340), null);

		// portrait and health bar
		hexagon(66, 66, 48);
		healthV[0] = health * 100;
		GuiProgressBar(new Rectangle(120, 50, 192, 32), null, null, healthV, 0, 100);

		// mana ball
		var ball = new Rectangle(40, 130, 128, 128);
		DrawTexturePro(ballGlass, new Rectangle(0, 0, 128, 128), ball, new Vector2(0, 0), 0, WHITE);
		DrawTextureFill(ballMana, new Rectangle(0, 0, 128, 128), ball, mana, TEXTURE_FILL_BOTTOM_TO_TOP, WHITE);
		var edge = GetTextureFillEdge(ball, mana, TEXTURE_FILL_BOTTOM_TO_TOP);
		DrawTexture(froth, Std.int(edge.x - froth.width / 2), Std.int(edge.y - froth.height / 2), WHITE);

		// cooldown
		var cd = new Rectangle(220, 140, 64, 64);
		DrawTexture(icon, 220, 140, GRAY);
		DrawTextureFill(icon, new Rectangle(0, 0, 64, 64), cd, cooldown, TEXTURE_FILL_CLOCKWISE, WHITE);

		// speed gauge: a half circle from the left end (-90) over the top to the right (+90)
		var g = new Rectangle(340, 140, 200, 100);
		DrawTextureFillEx(gauge, new Rectangle(0, 0, 200, 100), g, speed, TEXTURE_FILL_CLOCKWISE, -90, 180, WHITE);
		var ge = GetTextureFillEdgeEx(g, speed, TEXTURE_FILL_CLOCKWISE, -90, 180);
		DrawLineEx(new Vector2(g.x + g.width / 2, g.y + g.height), new Vector2(ge.x, ge.y), 3, RED);

		// ability slots
		var names = ["sword", "shield", "potion", "bow"];
		for (i in 0...names.length) {
			var src = GetTextureAtlasRect(atlas, names[i]);
			var x = 220 + i * 72;
			DrawTexturePro(atlas.texture, src, new Rectangle(x, 280, 64, 64), new Vector2(0, 0), 0, WHITE);
		}
		EndTextureMode();

		BeginDrawing();
		ClearBackground(BLACK);
		DrawRenderTextureFit(target, false, WHITE);
		EndDrawing();
	}

	static function main() {
		InitWindow(1280, 720, "status widgets");
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
		load("assets/rope_frame.png", t -> ropeFrame = t);
		load("assets/stone.png", t -> stone = t);
		load("assets/portrait.png", t -> portrait = t);
		LoadTextureAtlasAsync("assets/icons.xml", a -> atlas = a);
		while (!WindowShouldClose())
			frame();
		CloseWindow();
	}
}
