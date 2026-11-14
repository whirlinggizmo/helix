import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.*;
import helix.raylib.extras.GuiSkins.*;
import helix.raylib.extras.Textures.*;
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
	static var skinsSet = false;

	// A texture's name -> loaded, counted in `pending` until every one has arrived.
	static function load(path:String, done:Texture2D->Void) {
		pending++;
		LoadTextureAsync(path, t -> {
			done(t);
			pending--;
		});
	}

	// A triangle wave: 0 -> 1 -> 0 over `seconds`.
	static function pingPong(t:Float, seconds:Float):Float {
		var p = (t % seconds) / seconds;
		return p < 0.5 ? p * 2 : (1 - p) * 2;
	}

	static function setSkins() {
		// Panel: the rope frame, its twists repeating along each side.
		var rope = new NPatchInfo(new Rectangle(0, 0, 96, 96), 24, 24, 24, 24, NPATCH_NINE_PATCH);
		GuiSetSkin(DEFAULT, GUI_SKIN_BASE, GuiSkinFromTexture(ropeFrame, rope, null, null, null, WHITE, NPATCH_MODE_TILE, NPATCH_MODE_TILE));

		// Health bar: grey box, red fill revealed up to the value, a tip at its end.
		var cap = new NPatchInfo(new Rectangle(0, 0, 96, 16), 16, 0, 16, 0, NPATCH_THREE_PATCH_HORIZONTAL);
		GuiSetSkin(PROGRESSBAR, GUI_SKIN_BASE, GuiSkinFromTexture(barGrey, cap));
		GuiSetSkin(PROGRESSBAR, GUI_SKIN_FILL, GuiSkinFromTexture(barRed, cap));
		GuiSetSkinFillMode(PROGRESSBAR, GUI_SKIN_FILL_CLIPPED);
		GuiSetSkinFillEdge(PROGRESSBAR, barTip);
		skinsSet = true;
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

		while (!WindowShouldClose()) {
			frame();
		}
		CloseWindow();
	}

	static function frame() {
		if (pending == 0 && !skinsSet)
			setSkins();
		var t = GetTime();
		SetMouseRenderTextureFit(target, false);

		BeginTextureMode(target);
		ClearBackground(BLACK);
		if (skinsSet)
			drawScreen(t);
		EndTextureMode();

		BeginDrawing();
		ClearBackground(BLACK);
		DrawRenderTextureFit(target, false, WHITE);
		EndDrawing();
	}

	static function drawScreen(t:Float) {
		// Background: stone repeated at half size.
		DrawTextureTiled(stone, new Rectangle(0, 0, 64, 64), new Rectangle(0, 0, W, H), new Vector2(0, 0), 0, 0.5, WHITE);

		// Panel behind the widgets.
		GuiPanel(new Rectangle(10, 10, 620, 340), null);

		// Portrait in a hexagon 96 across (corner to corner), beside the health bar.
		var center = new Vector2(66, 66);
		var pts:Array<Vector2> = [];
		var uvs:Array<Vector2> = [];
		for (i in 0...6) {
			var a = Math.PI / 3 * i;
			var c = Math.cos(a), s = Math.sin(a);
			pts.push(new Vector2(center.x + 48 * c, center.y + 48 * s));
			uvs.push(new Vector2(0.5 + 0.375 * c, 0.5 + 0.375 * s));
		}
		DrawTexturePoly(portrait, center, pts, uvs, 6, WHITE);

		// Health bar: 0 -> 100 -> 0 over 10 seconds.
		var health = pingPong(t, 10) * 100;
		GuiProgressBar(new Rectangle(124, 58, 192, 16), null, null, [health], 0, 100);

		// Mana ball: 0 -> full -> 0 over 6 seconds.
		var mana = pingPong(t, 6);
		var ball = new Rectangle(60, 130, 128, 128);
		DrawTexturePro(ballGlass, new Rectangle(0, 0, 128, 128), ball, new Vector2(0, 0), 0, WHITE);
		DrawTextureFill(ballMana, new Rectangle(0, 0, 128, 128), ball, mana, TEXTURE_FILL_BOTTOM_TO_TOP, WHITE);
		var edge = GetTextureFillEdge(ball, mana, TEXTURE_FILL_BOTTOM_TO_TOP);
		DrawTexture(froth, Std.int(edge.x - froth.width / 2), Std.int(edge.y - froth.height / 2), WHITE);

		// Cooldown: grey icon, full colour clockwise from twelve o'clock over 3 seconds.
		var cd = (t % 3) / 3;
		var iconDest = new Rectangle(230, 150, 64, 64);
		var iconSrc = new Rectangle(0, 0, 64, 64);
		DrawTexturePro(icon, iconSrc, iconDest, new Vector2(0, 0), 0, GRAY);
		DrawTextureFill(icon, iconSrc, iconDest, cd, TEXTURE_FILL_CLOCKWISE, WHITE);

		// Speed gauge: left end (270 degrees clockwise from up) round to the right, 180 degrees.
		var speed = pingPong(t, 8);
		var gDest = new Rectangle(340, 150, 200, 100);
		var hub = new Vector2(gDest.x + 100, gDest.y + 100);
		DrawTextureFillEx(gauge, new Rectangle(0, 0, 200, 100), gDest, speed, TEXTURE_FILL_CLOCKWISE, hub, 270, 180, WHITE);
		var ge = GetTextureFillEdgeEx(gDest, speed, TEXTURE_FILL_CLOCKWISE, hub, 270, 180);
		var rad = ge.z * Math.PI / 180;
		DrawLineEx(hub, new Vector2(hub.x + Math.sin(rad) * 90, hub.y - Math.cos(rad) * 90), 3, RED);

		// Icons: a row of four slots from the atlas.
		var names = ["sword.png", "shield.png", "potion.png", "bow.png"];
		for (i in 0...names.length) {
			var src = GetTextureAtlasRect(atlas, names[i]);
			DrawTexturePro(atlas.texture, src, new Rectangle(230 + i * 72, 280, 64, 64), new Vector2(0, 0), 0, WHITE);
		}
	}
}
