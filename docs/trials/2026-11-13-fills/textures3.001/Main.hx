import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.*;
import helix.raylib.extras.GuiSkins.*;
import helix.raylib.extras.Textures.*;
import helix.raylib.extras.TextureAtlas;

class Main {
	static inline var W = 640;
	static inline var H = 360;

	static var target:RenderTexture2D;
	static var pending = 0;
	static var atlas:TextureAtlas = null;

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

	// Loads a texture, counting it as pending until it arrives.
	static function load(path:String, set:Texture2D->Void):Void {
		pending++;
		LoadTextureAsync(path, t -> {
			set(t);
			pending--;
		});
	}

	static function ready():Bool
		return pending == 0 && atlas != null;

	static function setupSkins():Void {
		GuiClearSkins();

		// DEFAULT first: it is set on every control, so each control's own skin comes after.
		var rope = new NPatchInfo(new Rectangle(0, 0, 96, 96), 24, 24, 24, 24, NPATCH_NINE_PATCH);
		GuiSetSkin(DEFAULT, GUI_SKIN_BASE, GuiSkinFromTexture(ropeFrame, rope, null, null, null, WHITE, NPATCH_MODE_TILE, NPATCH_MODE_TILE));

		var cap = (r:Rectangle) -> new NPatchInfo(r, 16, 0, 16, 0, NPATCH_THREE_PATCH_HORIZONTAL);
		GuiSetSkin(PROGRESSBAR, GUI_SKIN_BASE, GuiSkinFromTexture(barGrey, cap(new Rectangle(0, 0, 96, 16))));
		GuiSetSkin(PROGRESSBAR, GUI_SKIN_FILL, GuiSkinFromTexture(barRed, cap(new Rectangle(0, 0, 96, 16))));
		GuiSetSkinFillMode(PROGRESSBAR, GUI_SKIN_FILL_CLIPPED);
		GuiSetSkinFillEdge(PROGRESSBAR, barTip);
	}

	// Triangle wave from 0 up to 1 and back over `period` seconds.
	static function wave(t:Float, period:Float):Float {
		var p = (t % period) / period;
		return p < 0.5 ? p * 2 : (1 - p) * 2;
	}

	static function drawHexPortrait(cx:Float, cy:Float, across:Float):Void {
		var r = across / 2;
		var pts:Array<Vector2> = [];
		var uvs:Array<Vector2> = [];
		for (i in 0...6) {
			var a = (60 * i - 90) * Math.PI / 180;
			var c = Math.cos(a);
			var s = Math.sin(a);
			pts.push(new Vector2(cx + c * r, cy + s * r));
			uvs.push(new Vector2(0.5 + c * 0.5, 0.5 + s * 0.5));
		}
		DrawTexturePoly(portrait, new Vector2(cx, cy), pts, uvs, 6, WHITE);
	}

	static function drawScene(t:Float):Void {
		// Background: stone at half size.
		DrawTextureTiled(stone, new Rectangle(0, 0, 64, 64), new Rectangle(0, 0, W, H), new Vector2(0, 0), 0, 0.5, WHITE);

		// Panel behind the widgets.
		GuiPanel(new Rectangle(10, 10, W - 20, H - 20), null);

		// Portrait and health bar.
		drawHexPortrait(76, 66, 96);
		var health = wave(t, 10) * 100;
		GuiProgressBar(new Rectangle(136, 58, 192, 16), null, null, [health], 0, 100);

		// Mana ball.
		var ball = new Rectangle(40, 150, 128, 128);
		var mana = wave(t, 6);
		var full = new Rectangle(0, 0, 128, 128);
		DrawTexturePro(ballGlass, full, ball, new Vector2(0, 0), 0, WHITE);
		DrawTextureFill(ballMana, full, ball, mana, TEXTURE_FILL_BOTTOM_TO_TOP, WHITE);
		var edge = GetTextureFillEdge(ball, mana, TEXTURE_FILL_BOTTOM_TO_TOP);
		DrawTexture(froth, Std.int(edge.x - froth.width / 2), Std.int(edge.y - froth.height / 2), WHITE);

		// Cooldown: grey icon, color revealed clockwise from twelve o'clock.
		var iconRect = new Rectangle(200, 190, 64, 64);
		var iconSrc = new Rectangle(0, 0, 64, 64);
		DrawTexturePro(icon, iconSrc, iconRect, new Vector2(0, 0), 0, GRAY);
		DrawTextureFill(icon, iconSrc, iconRect, (t % 3) / 3, TEXTURE_FILL_CLOCKWISE, WHITE);

		// Speed gauge: half circle about the hub at the bottom middle, from the left end (270 degrees) sweeping 180.
		var gaugeRect = new Rectangle(340, 170, 200, 100);
		var hub = new Vector2(100, 100);
		var speed = wave(t, 8);
		DrawTextureFillEx(gauge, new Rectangle(0, 0, 200, 100), gaugeRect, speed, TEXTURE_FILL_CLOCKWISE, hub, 270, 180, WHITE);
		var tip = GetTextureFillEdgeEx(gaugeRect, speed, TEXTURE_FILL_CLOCKWISE, hub, 270, 180);
		var a = tip.z * Math.PI / 180;
		DrawLineEx(new Vector2(tip.x, tip.y), new Vector2(tip.x + Math.sin(a) * 90, tip.y - Math.cos(a) * 90), 3, RED);

		// Ability icons from the atlas.
		var names = ["sword.png", "shield.png", "potion.png", "bow.png"];
		for (i in 0...names.length) {
			var src = GetTextureAtlasRectangle(atlas, names[i]);
			DrawTexturePro(atlas.texture, src, new Rectangle(200 + i * 72, 280, 64, 64), new Vector2(0, 0), 0, WHITE);
		}
	}

	static function frame():Void {
		BeginDrawing();
		ClearBackground(BLACK);
		if (ready()) {
			SetMouseRenderTextureFit(target, false);
			BeginTextureMode(target);
			ClearBackground(BLACK);
			drawScene(GetTime());
			EndTextureMode();
			DrawRenderTextureFit(target, false, WHITE);
		} else {
			DrawText("Loading...", 10, 10, 20, WHITE);
		}
		EndDrawing();
	}

	static function main():Void {
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
		LoadTextureAtlasAsync("assets/icons.xml", a -> atlas = a);

		var skinned = false;
		while (!WindowShouldClose()) {
			if (!skinned && ready()) {
				setupSkins();
				skinned = true;
			}
			frame();
		}
		CloseWindow();
	}
}
