import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.*;
import helix.raylib.extras.GuiSkins.*;
import helix.raylib.extras.Textures.*;
import helix.raylib.extras.TextureAtlas;

class Main {
	static inline final W = 640;
	static inline final H = 360;
	static var stone:Texture2D;
	static var barGrey:Texture2D;
	static var barRed:Texture2D;
	static var barTip:Texture2D;
	static var ballGlass:Texture2D;
	static var ballMana:Texture2D;
	static var froth:Texture2D;
	static var icon:Texture2D;
	static var gauge:Texture2D;
	static var rope:Texture2D;
	static var portrait:Texture2D;
	static var atlas:TextureAtlas;

	/** A value going 0 to 1 and back to 0 over `period` seconds. */
	static function pingPong(t:Float, period:Float):Float {
		var p = (t % period) / period;
		return p < 0.5 ? p * 2 : (1 - p) * 2;
	}

	static function ready():Bool
		return stone != null && barGrey != null && barRed != null && barTip != null && ballGlass != null && ballMana != null && froth != null
			&& icon != null && gauge != null && rope != null && portrait != null && atlas != null;

	static function main() {
		InitWindow(1280, 720, "Status widgets");
		SetTargetFPS(60);

		var target = LoadRenderTexture(W, H);
		LoadTextureAsync("assets/stone.png", t -> stone = t);
		LoadTextureAsync("assets/bar_grey.png", t -> barGrey = t);
		LoadTextureAsync("assets/bar_red.png", t -> barRed = t);
		LoadTextureAsync("assets/bar_tip.png", t -> barTip = t);
		LoadTextureAsync("assets/ball_glass.png", t -> ballGlass = t);
		LoadTextureAsync("assets/ball_mana.png", t -> ballMana = t);
		LoadTextureAsync("assets/froth.png", t -> froth = t);
		LoadTextureAsync("assets/icon.png", t -> icon = t);
		LoadTextureAsync("assets/gauge.png", t -> gauge = t);
		LoadTextureAsync("assets/rope_frame.png", t -> rope = t);
		LoadTextureAsync("assets/portrait.png", t -> portrait = t);
		LoadTextureAtlasAsync("assets/icons.xml", a -> atlas = a);

		var health = [0.0];
		var hex = 6;
		var hexPoints:Array<Vector2> = [];
		var hexTex:Array<Vector2> = [];
		for (i in 0...hex) {
			var a = (Math.PI * 2 * i) / hex;
			hexPoints.push(new Vector2(Math.cos(a) * 48, Math.sin(a) * 48));
			hexTex.push(new Vector2(0.5 + 0.5 * Math.cos(a), 0.5 + 0.5 * Math.sin(a)));
		}
		var slotNames = ["sword", "shield", "potion", "bow"];
		var white = WHITE;
		var grey = new Color(90, 90, 90, 255);

		var skinned = false;
		while (!WindowShouldClose()) {
			if (!ready()) {
				BeginDrawing();
				ClearBackground(BLACK);
				EndDrawing();
				continue;
			}
			if (!skinned) {
				skinned = true;
			// Skins: the progress bar's box, red fill (clipped, so the caps behave) and tip; the panel's rope frame.
			GuiSetSkin(DEFAULT, GUI_SKIN_BASE, GuiSkinFromTexture(rope, new NPatchInfo(new Rectangle(0, 0, 96, 96), 24, 24, 24, 24, NPATCH_NINE_PATCH), null, null, null,
				null, NPATCH_MODE_TILE, NPATCH_MODE_TILE));
			GuiSetSkin(PROGRESSBAR, GUI_SKIN_BASE, GuiSkinFromTexture(barGrey, new NPatchInfo(new Rectangle(0, 0, 96, 16), 0, 0, 16, 0, NPATCH_NINE_PATCH)));
			GuiSetSkin(PROGRESSBAR, GUI_SKIN_FILL, GuiSkinFromTexture(barRed, new NPatchInfo(new Rectangle(0, 0, 96, 16), 0, 0, 16, 0, NPATCH_NINE_PATCH)));
			GuiSetSkin(PROGRESSBAR, GUI_SKIN_FILL_EDGE, GuiSkinFromTexture(barTip, new NPatchInfo(new Rectangle(0, 0, 16, 16), 0, 0, 0, 0, NPATCH_NINE_PATCH)));
			GuiSetSkinFillMode(PROGRESSBAR, GUI_SKIN_FILL_CLIPPED);
			}
			var t = GetTime();
			health[0] = pingPong(t, 10) * 100;
			var mana = pingPong(t, 6);
			var cooldown = (t % 3) / 3;
			var speed = pingPong(t, 8);

			// The mouse answers inside the fitted render texture.
			var fit = GetRenderTextureFitRect(target, false);
			var scale = fit.width / W;
			SetMouseOffset(-Std.int(fit.x), -Std.int(fit.y));
			SetMouseScale(1 / scale, 1 / scale);

			BeginTextureMode(target);
			ClearBackground(BLACK);
			DrawTextureTiled(stone, new Rectangle(0, 0, 64, 64), new Rectangle(0, 0, W, H), new Vector2(0, 0), 0, 0.5, white);

			GuiPanel(new Rectangle(10, 10, 620, 340), null);

			// Portrait in a hexagon, beside the health bar.
			DrawTexturePoly(portrait, new Vector2(70, 70), [for (p in hexPoints) new Vector2(70 + p.x, 70 + p.y)], hexTex, hex, white);
			GuiProgressBar(new Rectangle(130, 62, 240, 16), null, null, health, 0, 100);

			// Mana ball.
			var ball = new Rectangle(440, 40, 128, 128);
			DrawTexturePro(ballGlass, new Rectangle(0, 0, 128, 128), ball, new Vector2(0, 0), 0, white);
			DrawTextureFill(ballMana, new Rectangle(0, 0, 128, 128), ball, mana, TEXTURE_FILL_BOTTOM_TO_TOP, white);
			var edge = GetTextureFillEdge(ball, mana, TEXTURE_FILL_BOTTOM_TO_TOP);
			DrawTexture(froth, Std.int(edge.x - froth.width / 2), Std.int(edge.y - froth.height / 2), white);

			// Cooldown: grey icon, color revealed clockwise.
			var iconRect = new Rectangle(40, 150, 64, 64);
			DrawTexturePro(icon, new Rectangle(0, 0, 64, 64), iconRect, new Vector2(0, 0), 0, grey);
			DrawTextureFill(icon, new Rectangle(0, 0, 64, 64), iconRect, cooldown, TEXTURE_FILL_CLOCKWISE, white);

			// Speed gauge: top half of a dial, left end round to the right.
			var gaugeRect = new Rectangle(160, 130, 200, 100);
			DrawTextureFillEx(gauge, new Rectangle(0, 0, 200, 100), gaugeRect, speed, TEXTURE_FILL_CLOCKWISE, -90, 180, white);
			// The dial's centre is the bottom middle of the texture, so the full circle's rim is on a 200 x 200 rect.
			var circle = new Rectangle(160, 130, 200, 200);
			var tip = GetTextureFillEdgeEx(circle, speed, TEXTURE_FILL_CLOCKWISE, -90, 180);
			DrawLineEx(new Vector2(260, 230), new Vector2(tip.x, tip.y), 3, RED);

			// Ability slots from the atlas.
			for (i in 0...slotNames.length) {
				var src = GetTextureAtlasRect(atlas, slotNames[i]);
				DrawTexturePro(atlas.texture, src, new Rectangle(40 + i * 72, 270, 64, 64), new Vector2(0, 0), 0, white);
			}
			EndTextureMode();

			BeginDrawing();
			ClearBackground(BLACK);
			DrawRenderTextureFit(target, false, white);
			EndDrawing();
		}
		CloseWindow();
	}
}
