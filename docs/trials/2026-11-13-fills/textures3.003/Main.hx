import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.*;
import helix.raylib.extras.GuiSkins.*;
import helix.raylib.extras.Textures.*;
import helix.raylib.extras.TextureAtlas;

class Main {
	static inline final W = 640;
	static inline final H = 360;

	static function tri(t:Float, period:Float):Float {
		var p = (t % period) / period;
		return p < 0.5 ? p * 2 : 2 - p * 2;
	}

	static function main() {
		InitWindow(1280, 720, "Status widgets");
		SetTargetFPS(60);

		var target = LoadRenderTexture(W, H);
		var stone:Texture2D = null;
		var barGrey:Texture2D = null;
		var barRed:Texture2D = null;
		var barTip:Texture2D = null;
		var ballGlass:Texture2D = null;
		var ballMana:Texture2D = null;
		var froth:Texture2D = null;
		var icon:Texture2D = null;
		var gauge:Texture2D = null;
		var rope:Texture2D = null;
		var portrait:Texture2D = null;
		var atlas:TextureAtlas = null;
		var pending = 12;
		LoadTextureAsync("assets/stone.png", tex -> { stone = tex; pending--; });
		LoadTextureAsync("assets/bar_grey.png", tex -> { barGrey = tex; pending--; });
		LoadTextureAsync("assets/bar_red.png", tex -> { barRed = tex; pending--; });
		LoadTextureAsync("assets/bar_tip.png", tex -> { barTip = tex; pending--; });
		LoadTextureAsync("assets/ball_glass.png", tex -> { ballGlass = tex; pending--; });
		LoadTextureAsync("assets/ball_mana.png", tex -> { ballMana = tex; pending--; });
		LoadTextureAsync("assets/froth.png", tex -> { froth = tex; pending--; });
		LoadTextureAsync("assets/icon.png", tex -> { icon = tex; pending--; });
		LoadTextureAsync("assets/gauge.png", tex -> { gauge = tex; pending--; });
		LoadTextureAsync("assets/rope_frame.png", tex -> { rope = tex; pending--; });
		LoadTextureAsync("assets/portrait.png", tex -> { portrait = tex; pending--; });
		LoadTextureAtlasAsync("assets/icons.xml", a -> { atlas = a; pending--; });
		var skinned = false;
																								
		var healthValue = [0.0];
		var hex = [for (i in 0...6) {
			var a = Math.PI / 3 * i;
			{x: Math.cos(a), y: Math.sin(a)};
		}];

		while (!WindowShouldClose()) {
			if (pending > 0) {
				BeginDrawing();
				ClearBackground(BLACK);
				EndDrawing();
				continue;
			}
			if (!skinned) {
				skinned = true;
			// Panel: the rope frame, its sides tiled so the twists repeat.
			var ropePatch = new NPatchInfo(new Rectangle(0, 0, 96, 96), 24, 24, 24, 24, NPATCH_NINE_PATCH);
			GuiSetSkin(DEFAULT, GUI_SKIN_BASE,
				GuiSkinFromTexture(rope, ropePatch, null, null, null, WHITE, NPATCH_MODE_TILE, NPATCH_MODE_TILE));

			// Health bar: 16-texel round caps at each end, set after DEFAULT's so they aren't overwritten.
			var capped = (tex:Texture2D) -> new NPatchInfo(new Rectangle(0, 0, 96, 16), 16, 0, 16, 0, NPATCH_THREE_PATCH_HORIZONTAL);
			GuiSetSkin(PROGRESSBAR, GUI_SKIN_BASE, GuiSkinFromTexture(barGrey, capped(barGrey)));
			GuiSetSkin(PROGRESSBAR, GUI_SKIN_FILL, GuiSkinFromTexture(barRed, capped(barRed)));
			GuiSetSkinFillMode(PROGRESSBAR, GUI_SKIN_FILL_CLIPPED);
			GuiSetSkinFillEdge(PROGRESSBAR, barTip);

			}
			var t = GetTime();
			var health = tri(t, 10) * 100;
			var mana = tri(t, 6);
			var cooldown = (t % 3) / 3;
			var speed = tri(t, 8);

			BeginTextureMode(target);
			ClearBackground(BLACK);

			// Background: stone at half size across the screen.
			DrawTextureTiled(stone, new Rectangle(0, 0, 64, 64), new Rectangle(0, 0, W, H), new Vector2(0, 0), 0, 0.5, WHITE);

			// Panel behind the widgets.
			GuiPanel(new Rectangle(10, 10, 620, 340), null);

			// Portrait in a hexagon 96 across, beside the health bar.
			var center = new Vector2(70, 70);
			var pts = [for (h in hex) new Vector2(center.x + h.x * 48, center.y + h.y * 48)];
			var tcs = [for (h in hex) new Vector2(0.5 + h.x * 0.5, 0.5 + h.y * 0.5)];
			DrawTexturePoly(portrait, center, pts, tcs, 6, WHITE);

			// Health bar.
			healthValue[0] = health;
			GuiProgressBar(new Rectangle(130, 62, 192, 16), null, null, healthValue, 0, 100);

			// Mana ball.
			var ball = new Rectangle(40, 150, 128, 128);
			var full = new Rectangle(0, 0, 128, 128);
			DrawTexturePro(ballGlass, full, ball, new Vector2(0, 0), 0, WHITE);
			DrawTextureFill(ballMana, full, ball, mana, TEXTURE_FILL_BOTTOM_TO_TOP, WHITE);
			var edge = GetTextureFillEdge(ball, mana, TEXTURE_FILL_BOTTOM_TO_TOP);
			DrawTexture(froth, Std.int(edge.x - froth.width / 2), Std.int(edge.y - froth.height / 2), WHITE);

			// Cooldown: grey icon, color revealed clockwise.
			var iconRect = new Rectangle(220, 160, 64, 64);
			var iconSrc = new Rectangle(0, 0, 64, 64);
			DrawTexturePro(icon, iconSrc, iconRect, new Vector2(0, 0), 0, GRAY);
			DrawTextureFill(icon, iconSrc, iconRect, cooldown, TEXTURE_FILL_CLOCKWISE, WHITE);

			// Speed gauge: top half of a dial, revealed left to right about the hub at the bottom middle.
			var gaugeRect = new Rectangle(340, 160, 200, 100);
			var hub = new Vector2(100, 100);
			DrawTextureFillEx(gauge, new Rectangle(0, 0, 200, 100), gaugeRect, speed, TEXTURE_FILL_CLOCKWISE, hub, 270, 180, WHITE);
			var needle = GetTextureFillEdgeEx(gaugeRect, speed, TEXTURE_FILL_CLOCKWISE, hub, 270, 180);
			var rad = (needle.z - 90) * Math.PI / 180;
			DrawLineEx(new Vector2(needle.x, needle.y),
				new Vector2(needle.x + Math.cos(rad) * 90, needle.y + Math.sin(rad) * 90), 3, RED);

			// Ability slots from the atlas.
			var names = ["sword.png", "shield.png", "potion.png", "bow.png"];
			for (i in 0...names.length) {
				var src = GetTextureAtlasRectangle(atlas, names[i]);
				var dst = new Rectangle(340 + i * 52, 290, 48, 48);
				DrawTexturePro(atlas.texture, src, dst, new Vector2(0, 0), 0, WHITE);
			}
			EndTextureMode();

			SetMouseRenderTextureFit(target, false);
			BeginDrawing();
			ClearBackground(BLACK);
			DrawRenderTextureFit(target, false, WHITE);
			EndDrawing();
		}
		CloseWindow();
	}
}
