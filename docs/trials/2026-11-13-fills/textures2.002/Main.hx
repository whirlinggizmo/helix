import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.*;
import helix.raylib.extras.GuiSkins.*;
import helix.raylib.extras.GuiSkin;
import helix.raylib.extras.Textures.*;
import helix.raylib.extras.TextureAtlas;

class Main {
	static inline final W = 640;
	static inline final H = 360;

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
	static var target:RenderTexture2D;
	static var health = [0.0];

	static function load(path:String, set:Texture2D->Void) {
		LoadTextureAsync(path, t -> {
			set(t);
			pending--;
		});
	}

	static function skinsReady() {
		var ropePatch:NPatchInfo = {
			source: new Rectangle(0, 0, 96, 96),
			left: 24,
			top: 24,
			right: 24,
			bottom: 24,
			layout: NPATCH_NINE_PATCH
		};
		// Rope twists repeat along each side, fitted to a whole number of twists.
		GuiSetSkin(DEFAULT, GUI_SKIN_BASE, GuiSkinFromTexture(rope, ropePatch, null, null, null, WHITE, NPATCH_MODE_TILE_FIT, NPATCH_MODE_TILE_FIT));

		GuiSetSkin(PROGRESSBAR, GUI_SKIN_BASE, GuiSkinFromSheet(barGrey, 96, 16, 16, 0, 16, 0));
		GuiSetSkin(PROGRESSBAR, GUI_SKIN_FILL, GuiSkinFromSheet(barRed, 96, 16, 16, 0, 16, 0));
		GuiSetSkinFillMode(PROGRESSBAR, GUI_SKIN_FILL_CLIPPED);
		GuiSetSkinFillEdge(PROGRESSBAR, barTip);
	}

	static function main() {
		InitWindow(1280, 720, "Status widgets");
		SetTargetFPS(60);
		target = LoadRenderTexture(W, H);

		load("assets/bar_grey.png", t -> barGrey = t);
		load("assets/bar_red.png", t -> barRed = t);
		load("assets/bar_tip.png", t -> barTip = t);
		load("assets/ball_glass.png", t -> ballGlass = t);
		load("assets/ball_mana.png", t -> ballMana = t);
		load("assets/froth.png", t -> froth = t);
		load("assets/icon.png", t -> icon = t);
		load("assets/gauge.png", t -> gauge = t);
		load("assets/rope_frame.png", t -> rope = t);
		load("assets/stone.png", t -> stone = t);
		load("assets/portrait.png", t -> portrait = t);
		LoadTextureAtlasAsync("assets/icons.xml", a -> {
			atlas = a;
			pending--;
		});

		var skinned = false;
		var fitScale = false;

		while (!WindowShouldClose()) {
			if (pending == 0 && !skinned) {
				skinsReady();
				skinned = true;
			}
			var t = GetTime();
			SetMouseRenderTextureFit(target, fitScale);

			BeginTextureMode(target);
			ClearBackground(BLACK);
			if (skinned)
				drawScreen(t);
			EndTextureMode();

			BeginDrawing();
			ClearBackground(BLACK);
			DrawRenderTextureFit(target, fitScale, WHITE);
			EndDrawing();
		}
		CloseWindow();
	}

	/** A value going 0 to 1 and back over `period` seconds. */
	static function pingPong(t:Float, period:Float):Float {
		var p = (t % period) / period;
		return p < 0.5 ? p * 2 : (1 - p) * 2;
	}

	static function drawScreen(t:Float) {
		// Background: the stone at half its size.
		DrawTextureTiled(stone, new Rectangle(0, 0, 64, 64), new Rectangle(0, 0, W, H), new Vector2(0, 0), 0, 0.5, WHITE);

		// Panel behind the widgets, its frame the rope.
		GuiPanel(new Rectangle(10, 10, 620, 340), null);

		// Portrait in a hexagon 96 across, beside the health bar.
		var c = new Vector2(66, 66);
		var pts:Array<Vector2> = [];
		var uvs:Array<Vector2> = [];
		for (i in 0...6) {
			var a = Math.PI / 3 * i;
			pts.push(new Vector2(c.x + 48 * Math.cos(a), c.y + 48 * Math.sin(a)));
			uvs.push(new Vector2(0.5 + 0.5 * Math.cos(a) * 96 / 128, 0.5 + 0.5 * Math.sin(a) * 96 / 128));
		}
		DrawTexturePoly(portrait, c, pts, uvs, 6, WHITE);

		// Health bar.
		health[0] = pingPong(t, 10) * 100;
		GuiProgressBar(new Rectangle(124, 50, 192, 32), null, null, health, 0, 100);

		// Mana ball.
		var mana = pingPong(t, 6);
		var ball = new Rectangle(440, 30, 128, 128);
		DrawTexturePro(ballGlass, new Rectangle(0, 0, 128, 128), ball, new Vector2(0, 0), 0, WHITE);
		DrawTextureFill(ballMana, new Rectangle(0, 0, 128, 128), ball, mana, TEXTURE_FILL_BOTTOM_TO_TOP, WHITE);
		var edge = GetTextureFillEdge(ball, mana, TEXTURE_FILL_BOTTOM_TO_TOP);
		DrawTexture(froth, Std.int(edge.x - froth.width / 2), Std.int(edge.y - froth.height / 2), WHITE);

		// Cooldown: grey icon, color icon revealed clockwise from twelve o'clock.
		var cool = (t % 3) / 3;
		var iconRect = new Rectangle(40, 200, 64, 64);
		var src = new Rectangle(0, 0, 64, 64);
		DrawTexturePro(icon, src, iconRect, new Vector2(0, 0), 0, GRAY);
		DrawTextureFill(icon, src, iconRect, cool, TEXTURE_FILL_CLOCKWISE, WHITE);

		// Speed gauge: half circle revealed left to right about the hub (bottom middle).
		var speed = pingPong(t, 8);
		var gr = new Rectangle(160, 190, 200, 100);
		var hub = new Vector2(100, 100);
		DrawTextureFillEx(gauge, new Rectangle(0, 0, 200, 100), gr, speed, TEXTURE_FILL_CLOCKWISE, hub, -90, 180, WHITE);
		var ne = GetTextureFillEdgeEx(gr, speed, TEXTURE_FILL_CLOCKWISE, hub, -90, 180);
		var rad = (ne.z - 90) * Math.PI / 180;
		DrawLineEx(new Vector2(ne.x, ne.y), new Vector2(ne.x + 90 * Math.cos(rad), ne.y + 90 * Math.sin(rad)), 3, RED);

		// Ability slots from the atlas.
		var names = ["sword.png", "shield.png", "potion.png", "bow.png"];
		for (i in 0...names.length) {
			var r = atlas.names.indexOf(names[i]) >= 0 ? GetTextureAtlasRect(atlas, names[i]) : new Rectangle(0, 0, 0, 0);
			DrawTexturePro(atlas.texture, r, new Rectangle(380 + i * 56, 250, 48, 48), new Vector2(0, 0), 0, WHITE);
		}
	}
}
