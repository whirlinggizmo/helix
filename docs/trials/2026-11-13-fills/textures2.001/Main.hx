import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.*;
import helix.raylib.extras.GuiSkins.*;
import helix.raylib.extras.Textures.*;
import helix.raylib.extras.GuiSkin;
import helix.raylib.extras.TextureAtlas;

class Main {
	static inline final W = 640;
	static inline final H = 360;

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

	static var pending = 0;
	static var ready = false;

	static function load(path:String, set:Texture2D->Void) {
		pending++;
		LoadTextureAsync(path, t -> {
			set(t);
			pending--;
		});
	}

	// A triangle wave: 0 to 1 and back over `seconds`.
	static function pingPong(t:Float, seconds:Float):Float {
		var p = (t % seconds) / seconds;
		return p < 0.5 ? p * 2 : 2 - p * 2;
	}

	static function setupSkins() {
		// The panel: rope frame, its twists tiled along each side.
		var rope = GuiSkinFromTexture(ropeFrame, {source: new Rectangle(0, 0, 96, 96), left: 24, top: 24, right: 24, bottom: 24, layout: NPATCH_NINE_PATCH},
			null, null, null, WHITE, NPATCH_MODE_TILE, NPATCH_MODE_TILE);
		GuiSetSkin(DEFAULT, GUI_SKIN_BASE, rope);

		// The health bar: box and progress are 96 x 16 with caps of 16 texels.
		GuiSetSkin(PROGRESSBAR, GUI_SKIN_BASE,
			GuiSkinFromTexture(barGrey, {source: new Rectangle(0, 0, 96, 16), left: 16, top: 0, right: 16, bottom: 0, layout: NPATCH_THREE_PATCH_HORIZONTAL}));
		GuiSetSkin(PROGRESSBAR, GUI_SKIN_FILL,
			GuiSkinFromTexture(barRed, {source: new Rectangle(0, 0, 96, 16), left: 16, top: 0, right: 16, bottom: 0, layout: NPATCH_THREE_PATCH_HORIZONTAL}));
		GuiSetSkinFillMode(PROGRESSBAR, GUI_SKIN_FILL_CLIPPED);
		GuiSetSkinFillEdge(PROGRESSBAR, barTip);
	}

	static function drawScene(t:Float) {
		ClearBackground(BLACK);

		// Background: stone at half size across the screen.
		DrawTextureTiled(stone, new Rectangle(0, 0, 64, 64), new Rectangle(0, 0, W, H), new Vector2(0, 0), 0, 0.5, WHITE);

		// Panel behind the widgets.
		GuiPanel(new Rectangle(10, 10, W - 20, H - 20), null);

		// Portrait in a hexagon 96 across, beside the health bar.
		var pc = new Vector2(70, 70);
		var pts:Array<Vector2> = [];
		var tcs:Array<Vector2> = [];
		for (i in 0...6) {
			var a = Math.PI / 3 * i;
			pts.push(new Vector2(pc.x + 48 * Math.cos(a), pc.y + 48 * Math.sin(a)));
			tcs.push(new Vector2(0.5 + 0.5 * Math.cos(a), 0.5 + 0.5 * Math.sin(a)));
		}
		DrawTexturePoly(portrait, pc, pts, tcs, 6, WHITE);

		// Health bar.
		var healthRef = [pingPong(t, 10) * 100];
		GuiProgressBar(new Rectangle(130, 62, 192, 16), "", "", healthRef, 0, 100);

		// Mana ball with froth on its surface.
		var mana = pingPong(t, 6);
		var ball = new Rectangle(40, 190, 128, 128);
		DrawTexturePro(ballGlass, new Rectangle(0, 0, 128, 128), ball, new Vector2(0, 0), 0, WHITE);
		DrawTextureFill(ballMana, new Rectangle(0, 0, 128, 128), ball, mana, TEXTURE_FILL_BOTTOM_TO_TOP, WHITE);
		var edge = GetTextureFillEdge(ball, mana, TEXTURE_FILL_BOTTOM_TO_TOP);
		DrawTexture(froth, Std.int(edge.x - froth.width / 2), Std.int(edge.y - froth.height / 2), WHITE);

		// Cooldown: grey icon, color revealed clockwise.
		var cd = new Rectangle(200, 120, 64, 64);
		var cdAmount = (t % 3) / 3;
		DrawTexturePro(icon, new Rectangle(0, 0, 64, 64), cd, new Vector2(0, 0), 0, GRAY);
		DrawTextureFill(icon, new Rectangle(0, 0, 64, 64), cd, cdAmount, TEXTURE_FILL_CLOCKWISE, WHITE);

		// Speed gauge: half circle from the left end around to the right, needle at the edge.
		var g = new Rectangle(380, 120, 200, 100);
		var hub = new Vector2(g.x + 100, g.y + 100);
		var speed = pingPong(t, 8);
		DrawTextureFillEx(gauge, new Rectangle(0, 0, 200, 100), g, speed, TEXTURE_FILL_CLOCKWISE, new Vector2(100, 100), -90, 180, WHITE);
		var ge = GetTextureFillEdgeEx(g, speed, TEXTURE_FILL_CLOCKWISE, new Vector2(100, 100), -90, 180);
		var ang = ge.z * Math.PI / 180;
		DrawLineEx(hub, new Vector2(hub.x + 90 * Math.sin(ang), hub.y - 90 * Math.cos(ang)), 3, RED);

		// Ability icons from the atlas.
		var names = ["sword.png", "shield.png", "potion.png", "bow.png"];
		for (i in 0...names.length) {
			var src = GetTextureAtlasRect(atlas, names[i]);
			DrawTexturePro(atlas.texture, src, new Rectangle(300 + i * 70, 260, 64, 64), new Vector2(0, 0), 0, WHITE);
		}
	}

	static function frame() {
		if (!ready && pending == 0) {
			ready = true;
			setupSkins();
		}
		var t = GetTime();
		if (!ready) {
			BeginDrawing();
			ClearBackground(BLACK);
			EndDrawing();
			return;
		}
		SetMouseRenderTextureFit(target, false);
		BeginTextureMode(target);
		drawScene(t);
		EndTextureMode();

		BeginDrawing();
		ClearBackground(BLACK);
		DrawRenderTextureFit(target, false, WHITE);
		EndDrawing();
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
		load("assets/rope_frame.png", t -> ropeFrame = t);
		load("assets/stone.png", t -> stone = t);
		load("assets/portrait.png", t -> portrait = t);
		pending++;
		LoadTextureAtlasAsync("assets/icons.xml", a -> {
			atlas = a;
			pending--;
		});

		while (!WindowShouldClose())
			frame();
	}
}
