import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.extras.GuiSkins.*;
import helix.raylib.extras.Textures.*;
import helix.raylib.extras.TextureAtlas;

class Main {
	static inline final W = 640;
	static inline final H = 360;

	// A value that goes 0 to 1 and back, one full trip taking `seconds`.
	static function pingPong(t:Float, seconds:Float):Float {
		var p = (t % seconds) / seconds;
		return p < 0.5 ? p * 2 : 2 - p * 2;
	}

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
	static var target:RenderTexture2D;
	static var atlas:TextureAtlas;
	static var pending = 0;
	static var hexPoints:Array<Vector2> = [];
	static var hexUV:Array<Vector2> = [];
	static var healthValue:Array<Float> = [0];
	static var ready = false;

	static function load(path:String, done:Texture2D->Void) {
		pending++;
		LoadTextureAsync(path, t -> {
			done(t);
			if (--pending == 0) setup();
		});
	}

	static function setup() {

		// Panel: the rope frame, its twists repeating along each side.
		var ropePatch = new NPatchInfo(new Rectangle(0, 0, 96, 96), 24, 24, 24, 24, NPATCH_NINE_PATCH);
		GuiSetSkin(DEFAULT, GUI_SKIN_BASE, GuiSkinFromTexture(rope, ropePatch, null, null, null, WHITE, NPATCH_MODE_TILE_FIT, NPATCH_MODE_TILE_FIT));

		// Health bar: box and progress, round caps of 16 texels.
		var greyPatch = new NPatchInfo(new Rectangle(0, 0, 96, 16), 16, 0, 16, 0, NPATCH_THREE_PATCH_HORIZONTAL);
		var redPatch = new NPatchInfo(new Rectangle(0, 0, 96, 16), 16, 0, 16, 0, NPATCH_THREE_PATCH_HORIZONTAL);
		GuiSetSkin(PROGRESSBAR, GUI_SKIN_BASE, GuiSkinFromTexture(barGrey, greyPatch));
		GuiSetSkin(PROGRESSBAR, GUI_SKIN_FILL, GuiSkinFromTexture(barRed, redPatch));
		GuiSetSkinFillMode(PROGRESSBAR, GUI_SKIN_FILL_CLIPPED);
		GuiSetSkinFillEdge(PROGRESSBAR, barTip);

		// Hexagon for the portrait, 96 across (point to point), centered on (cx, cy).
		var hexR = 48.0;
						for (i in 0...6) {
			var a = Math.PI / 3 * i;
			var dx = Math.cos(a), dy = Math.sin(a);
			hexPoints.push(new Vector2(dx * hexR, dy * hexR));
			hexUV.push(new Vector2(0.5 + dx * hexR / 96, 0.5 + dy * hexR / 96));
		}

		ready = true;
	}

	static function main() {
		InitWindow(1280, 720, "Status widgets");
		SetTargetFPS(60);

		target = LoadRenderTexture(W, H);
		load("assets/stone.png", t -> stone = t);
		load("assets/bar_grey.png", t -> barGrey = t);
		load("assets/bar_red.png", t -> barRed = t);
		load("assets/bar_tip.png", t -> barTip = t);
		load("assets/ball_glass.png", t -> ballGlass = t);
		load("assets/ball_mana.png", t -> ballMana = t);
		load("assets/froth.png", t -> froth = t);
		load("assets/icon.png", t -> icon = t);
		load("assets/gauge.png", t -> gauge = t);
		load("assets/rope_frame.png", t -> rope = t);
		load("assets/portrait.png", t -> portrait = t);
		pending++;
		LoadTextureAtlasAsync("assets/icons.xml", a -> {
			atlas = a;
			if (--pending == 0) setup();
		});

		var slotNames = ["sword.png", "shield.png", "potion.png", "bow.png"];

		while (!WindowShouldClose()) {
			if (!ready) {
				BeginDrawing();
				ClearBackground(BLACK);
				DrawText("Loading...", 10, 10, 20, WHITE);
				EndDrawing();
				continue;
			}
			var t = GetTime();
			var health = pingPong(t, 10);
			var mana = pingPong(t, 6);
			var cooldown = (t % 3) / 3;
			var speed = pingPong(t, 8);

			// The mouse reads in the render texture's pixels.
			SetMouseRenderTextureFit(target, false);

			BeginTextureMode(target);
			ClearBackground(BLACK);

			// Background: stone at half size.
			DrawTextureTiled(stone, new Rectangle(0, 0, 64, 64), new Rectangle(0, 0, W, H), new Vector2(0, 0), 0, 0.5, WHITE);

			// Panel.
			GuiPanel(new Rectangle(8, 8, W - 16, H - 16), null);

			// Portrait in a hexagon beside the health bar.
			var pc = new Vector2(70, 70);
			var pts = [for (p in hexPoints) new Vector2(pc.x + p.x, pc.y + p.y)];
			DrawTexturePoly(portrait, pc, pts, hexUV, 6, WHITE);

			// Health bar.
			healthValue[0] = health * 100;
			GuiProgressBar(new Rectangle(130, 62, 288, 16), null, null, healthValue, 0, 100);

			// Mana ball.
			var ball = new Rectangle(450, 30, 128, 128);
			var full = new Rectangle(0, 0, 128, 128);
			DrawTexturePro(ballGlass, full, ball, new Vector2(0, 0), 0, WHITE);
			DrawTextureFill(ballMana, full, ball, mana, TEXTURE_FILL_BOTTOM_TO_TOP, WHITE);
			var edge = GetTextureFillEdge(ball, mana, TEXTURE_FILL_BOTTOM_TO_TOP);
			DrawTexture(froth, Std.int(edge.x - froth.width / 2), Std.int(edge.y - froth.height / 2), WHITE);

			// Cooldown: grey icon, color revealed clockwise.
			var iconRect = new Rectangle(60, 180, 64, 64);
			var iconSrc = new Rectangle(0, 0, 64, 64);
			DrawTexturePro(icon, iconSrc, iconRect, new Vector2(0, 0), 0, GRAY);
			DrawTextureFill(icon, iconSrc, iconRect, cooldown, TEXTURE_FILL_CLOCKWISE, WHITE);

			// Speed gauge: top half circle, hub at the bottom middle, left end to right end.
			var gaugeRect = new Rectangle(180, 170, 200, 100);
			var hub = new Vector2(100, 100);
			var gaugeSrc = new Rectangle(0, 0, 200, 100);
			DrawTextureFillEx(gauge, gaugeSrc, gaugeRect, speed, TEXTURE_FILL_CLOCKWISE, hub, 270, 180, WHITE);
			var ge = GetTextureFillEdgeEx(gaugeRect, speed, TEXTURE_FILL_CLOCKWISE, hub, 270, 180);
			var rad = (ge.z - 90) * Math.PI / 180;
			DrawLineEx(new Vector2(ge.x, ge.y), new Vector2(ge.x + Math.cos(rad) * 90, ge.y + Math.sin(rad) * 90), 3, RED);

			// Icon slots from the atlas.
			for (i in 0...slotNames.length) {
				var src = GetTextureAtlasRectangle(atlas, slotNames[i]);
				var dst = new Rectangle(420 + i * 48, 200, 40, 40);
				DrawTexturePro(atlas.texture, src, dst, new Vector2(0, 0), 0, WHITE);
			}

			EndTextureMode();

			BeginDrawing();
			ClearBackground(BLACK);
			DrawRenderTextureFit(target, false, WHITE);
			EndDrawing();
		}

		UnloadTextureAtlas(atlas);
		UnloadRenderTexture(target);
		CloseWindow();
	}
}
