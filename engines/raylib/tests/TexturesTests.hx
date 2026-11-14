import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.extras.GuiSkins.*;
import helix.raylib.extras.TextureAtlas;
import helix.raylib.extras.Textures.*;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Runtime;
import helix.raylib.modules.RTextureAtlases;
import helix.raylib.modules.RCore;
import helix.raylib.modules.RGui;
import helix.raylib.modules.RTextureFills;
import helix.services.screen.Screen;

/** Checks `extras.Textures` and the fills `extras.GuiSkins` draws with it, on graphics that keep nothing: a stretched `DrawTextureNPatchEx`
	drawing what `DrawTextureNPatch` draws, its tiles repeated or fitted; a fill across drawing `DrawTexturePro`'s quad for the part filled;
	a radial fill's wedge cut from dest by its area, the origin anywhere; the fill's edge; a tiled draw's copies cut at dest's sides; a
	polygon closed; both atlas readers and their refusals; the fitted render texture's rectangle and mouse; and a progress bar's fill
	clipped to its value with its edge at the end. Run by helix.py test on the interpreter, Node and natively. */
@:access(helix.raylib.internal.Frame)
@:access(helix.raylib.modules.RTextureFills)
@:access(helix.raylib.modules.RTextureAtlases)
@:access(helix.raylib.modules.RCore)
@:access(helix.raylib.extras.TextureAtlas)
@:access(helix.raylib.modules.RGui)
class TexturesTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float, message:String):Void
		check(Math.abs(a - b) < 1e-3, '$message: $a, not $b');

	// The frame's sprite records so far, each its 12 floats (four corners, then u0, v0, u1, v1), and the frame emptied for the next draws.
	static function records():Array<Array<Float>> {
		var frame = Runtime.frame;
		var out = [];
		for (s in 0...frame.sprites)
			out.push([for (i in 0...12) frame.spriteData.getFloat(s * 52 + i * 4)]);
		frame.draw(64, 64, true);
		return out;
	}

	// Everything drawn since the last read, sprite records and immediate vertices, as bytes, the frame drawn after.
	static function drawn():String {
		var f = Runtime.frame, out = new StringBuf();
		f.flush();
		for (d in f.pass.draws) {
			if (d.buffers != null)
				continue;
			if (d.sprite) {
				for (i in d.firstInstance...d.firstInstance + d.instances)
					out.add(f.spriteData.sub(i * 52, 52).toHex());
			} else
				for (k in d.first...d.first + d.count) {
					var i = d.indices == 0 ? k : Std.int(k / 6) * 4 + [0, 1, 2, 0, 2, 3][k % 6];
					out.add(f.data.sub(i * 36, 36).toHex());
				}
			out.add(";");
		}
		f.draw(64, 64, true);
		return out.toString();
	}

	// How many immediate vertices are waiting, the frame emptied after.
	static function vertices():Int {
		var count = Runtime.frame.vertices;
		Runtime.frame.draw(64, 64, true);
		return count;
	}

	// A convex polygon's area, its points x, y, x, y...
	static function area(points:Array<Float>):Float {
		var sum = 0., n = Std.int(points.length / 2);
		for (i in 0...n) {
			var j = (i + 1) % n;
			sum += points[i * 2] * points[j * 2 + 1] - points[j * 2] * points[i * 2 + 1];
		}
		return Math.abs(sum) / 2;
	}

	static function main():Void {
		SetTraceLogLevel(LOG_NONE);
		var graphics = new CountingGraphics();
		Runtime.graphics = graphics;
		Runtime.frame = new Frame(graphics);
		var window = new FakeWindow();
		window.logicalWidth = 1280;
		window.logicalHeight = 720;
		Runtime.window = window;
		Runtime.events = new FakeEvents();
		Runtime.screen = new Screen(window, Runtime.events);
		Runtime.frame.begin(64, 64);
		var texture = LoadTextureFromImage(GenImageColor(64, 32, WHITE));
		var zero = new Vector2(0, 0);
		var patch = new NPatchInfo(new Rectangle(0, 0, 64, 32), 8, 8, 8, 8, NPATCH_NINE_PATCH);

		// Stretched, a patch is DrawTextureNPatch's.
		DrawTextureNPatchEx(texture, patch, new Rectangle(10, 10, 150, 40), new Vector2(3, 4), 20, NPATCH_MODE_STRETCH, NPATCH_MODE_STRETCH, RED);
		var ex = drawn();
		DrawTextureNPatch(texture, patch, new Rectangle(10, 10, 150, 40), new Vector2(3, 4), 20, RED);
		check(ex == drawn(), "a stretched patch is DrawTextureNPatch's");

		// Tiled across: a middle of 48 texels over 134 pixels is two tiles and one cut at 38, between the two borders; down, stretched.
		DrawTextureNPatchEx(texture, patch, new Rectangle(0, 0, 150, 40), zero, 0, NPATCH_MODE_TILE, NPATCH_MODE_STRETCH, WHITE);
		var tiled = records();
		check(tiled.length == 5 * 3, 'five columns of three rows, not ${tiled.length} cells');
		var columns = [for (r in tiled) if (r[1] == 0) r[0]];
		check(columns.join(",") == "0,8,56,104,142", 'the columns start at 0, 8, 56, 104 and 142, not $columns');
		var cut = tiled.filter(r -> r[0] == 104 && r[1] == 0)[0];
		near(cut[8] * 64, 8, "the cut tile starts at the middle's start");
		near(cut[10] * 64, 46, "and ends 38 texels on");
		// Fitted: 134 pixels is three tiles of a little under 45.
		DrawTextureNPatchEx(texture, patch, new Rectangle(0, 0, 150, 40), zero, 0, NPATCH_MODE_TILE_FIT, NPATCH_MODE_STRETCH, WHITE);
		var fitted = records();
		check(fitted.length == 5 * 3, 'three fitted tiles, not ${fitted.length / 3 - 2}');
		near(fitted.filter(r -> r[1] == 0)[3][0], 8 + 2 * 134 / 3, "the third fitted tile's start");

		// A fill across is DrawTexturePro's quad for the part filled, flipped or not.
		var source = new Rectangle(0, 0, 64, 32),
			dest = new Rectangle(20, 30, 128, 64);
		DrawTextureFill(texture, source, dest, 0.25, TEXTURE_FILL_LEFT_TO_RIGHT, BLUE);
		var fill = drawn();
		DrawTexturePro(texture, new Rectangle(0, 0, 16, 32), new Rectangle(20, 30, 32, 64), zero, 0, BLUE);
		check(fill == drawn(), "a quarter left to right");
		DrawTextureFill(texture, source, dest, 0.5, TEXTURE_FILL_BOTTOM_TO_TOP, BLUE);
		fill = drawn();
		DrawTexturePro(texture, new Rectangle(0, 16, 64, 16), new Rectangle(20, 62, 128, 32), zero, 0, BLUE);
		check(fill == drawn(), "half bottom to top");
		DrawTextureFill(texture, source, dest, 0, TEXTURE_FILL_LEFT_TO_RIGHT, BLUE);
		check(drawn() == "", "empty draws nothing");
		DrawTextureFill(texture, source, dest, 2, TEXTURE_FILL_RIGHT_TO_LEFT, BLUE);
		fill = drawn();
		DrawTexturePro(texture, source, dest, zero, 0, BLUE);
		check(fill == drawn(), "more than full is full");

		// A radial fill's wedge: dest cut to it, by area, about the middle, a corner, or a point outside.
		inline function wedge(originX:Float, originY:Float, from:Float, to:Float):Float
			return area(RTextureFills.wedge(100, 100, originX, originY, from, to).copy());
		near(wedge(50, 50, 0, 90), 2500, "a quarter about the middle");
		near(wedge(50, 50, 45, 225), 5000, "half about the middle, from a corner");
		near(wedge(0, 0, 90, 180), 10000, "right to down about the top-left is all of it");
		near(wedge(0, 0, 0, 90), 0, "up to right about the top-left is none of it");
		near(wedge(50, 100, 270, 360), 5000, "a gauge's left half, about the bottom's middle");
		near(wedge(50, 150, 330, 360), 50 * (150 - 50 * Math.sqrt(3)) + 5000 / (2 * Math.sqrt(3)), "about a point below");
		// Drawn: the whole circle is two halves, each a fan.
		DrawTextureFill(texture, source, dest, 1, TEXTURE_FILL_CLOCKWISE, WHITE);
		check(vertices() > 0, "a radial fill draws");
		DrawTextureFillEx(texture, source, dest, 0, TEXTURE_FILL_CLOCKWISE, zero, 0, 360, WHITE);
		check(vertices() == 0, "an empty radial fill draws nothing");

		// The edge: across, at the amount; radial, the origin and the angle.
		var edge = GetTextureFillEdge(dest, 0.25, TEXTURE_FILL_LEFT_TO_RIGHT);
		check(edge.x == 52 && edge.y == 62 && edge.z == 0, 'a quarter across ends at (52, 62), not $edge');
		GetTextureFillEdge(dest, 0.25, TEXTURE_FILL_BOTTOM_TO_TOP, edge);
		check(edge.x == 84 && edge.y == 78, 'a quarter up ends at (84, 78), not $edge');
		GetTextureFillEdgeEx(dest, 0.5, TEXTURE_FILL_CLOCKWISE, new Vector2(64, 64), 270, 180, edge);
		check(edge.x == 84 && edge.y == 94 && edge.z == 0, 'half a gauge from the left is straight up, about the hub: not $edge');
		GetTextureFillEdgeEx(dest, 0.25, TEXTURE_FILL_COUNTER_CLOCKWISE, new Vector2(64, 64), 10, 360, edge);
		near(edge.z, 280, "counterclockwise, wrapped");
		GetTextureFillEdge(dest, 1, TEXTURE_FILL_CLOCKWISE, edge);
		check(edge.x == 84 && edge.y == 62 && edge.z == 0, 'full, about the middle, back at the start: $edge');

		// Tiled: 100 by 50 in copies of 16 is seven across and four down, the last cut.
		DrawTextureTiled(texture, new Rectangle(0, 0, 32, 32), new Rectangle(0, 0, 100, 50), zero, 0, 0.5, WHITE);
		var copies = records();
		check(copies.length == 28, 'seven by four copies, not ${copies.length}');
		var last = copies[copies.length - 1];
		near(last[4] - last[0], 4, "the last column cut to 4 pixels");
		near(last[10] * 64, 8, "showing 8 texels");
		near(last[3] - last[1], 2, "the last row cut to 2 pixels");

		// A polygon of six points is six triangles, closed back to the first.
		var points = [
			for (i in 0...6)
				new Vector2(50 + 20 * Math.cos(i * Math.PI / 3), 50 + 20 * Math.sin(i * Math.PI / 3))
		];
		var texcoords = [for (p in points) new Vector2((p.x - 30) / 40, (p.y - 30) / 40)];
		DrawTexturePoly(texture, new Vector2(50, 50), points, texcoords, 6, WHITE);
		check(vertices() == 18, "six triangles");

		// The atlases: TexturePacker's hash and array, and Starling's XML; their refusals.
		var hash = RTextureAtlases.parseJson('{"frames": {"sword.png": {"frame": {"x": 1, "y": 2, "w": 3, "h": 4}},'
			+ ' "bow.png": {"frame": {"x": 5, "y": 6, "w": 7, "h": 8}}}, "meta": {"image": "icons.png"}}');
		check(hash.names.join(",") == "sword.png,bow.png" && hash.sheet == "icons.png", 'a hash, in order: ${hash.names}');
		var r = GetTextureAtlasRectangle(hash, "bow.png");
		check(r.x == 5 && r.y == 6 && r.width == 7 && r.height == 8, 'bow.png at (5, 6), 7 by 8, not $r');
		var array = RTextureAtlases.parseJson('{"frames": [{"filename": "a", "frame": {"x": 1, "y": 1, "w": 2, "h": 2}}], "meta": {"image": "s.png"}}');
		check(array.names.join(",") == "a", "an array");
		var xml = RTextureAtlases.parseXml('<?xml version="1.0"?><!-- <SubTexture name="no"/> --><TextureAtlas imagePath="sheet.png"><SubTexture name="shield.png" x="10" y="20" width="30" height="40"/>'
			+ '<SubTexture name="potion.png" x="1" y="2" width="3" height="4"/></TextureAtlas>');
		check(xml.names.join(",") == "shield.png,potion.png" && xml.sheet == "sheet.png", 'Starling\'s XML: ${xml.names}');
		GetTextureAtlasRectangle(xml, "shield.png", r);
		check(r.x == 10 && r.y == 20 && r.width == 30 && r.height == 40, 'shield.png at (10, 20), not $r');
		GetTextureAtlasRectangle(xml, "axe.png", r);
		check(r.width == 0 && r.height == 0, "a name it lacks is an empty rectangle");
		inline function refused(parse:String->Null<TextureAtlas>, text:String, says:String):Void {
			var atlas = parse(text);
			check(atlas == null && RTextureAtlases.refusal.indexOf(says) >= 0, 'refused with "$says", not "${RTextureAtlases.refusal}"');
		}
		refused(RTextureAtlases.parseJson, '{"frames": {}}', "names no texture");
		refused(RTextureAtlases.parseJson, '{"frames": {"a": {"frame": {"x": 0, "y": 0, "w": 1, "h": 1}, "rotated": true}}, "meta": {"image": "s.png"}}',
			"packed rotated");
		refused(RTextureAtlases.parseJson, '{"frames": ', "isn't JSON");
		refused(RTextureAtlases.parseXml, '<Atlas/>', "no TextureAtlas element");
		refused(RTextureAtlases.parseXml, '<TextureAtlas', "isn't XML");
		var said = "";
		RTextureAtlases.loadAtlas("icons.txt", a -> {}, why -> said = why);
		check(said.indexOf("Not an atlas") >= 0, 'another format refused: "$said"');

		// The fit: 640 by 360 on 1280 by 720 is twice its size; on 1000 by 720, 1.5625 times, or once as a whole number, centered.
		var target = LoadRenderTexture(640, 360);
		var at = GetRenderTextureFitRectangle(target, false);
		check(at.x == 0 && at.y == 0 && at.width == 1280 && at.height == 720, 'twice its size, not $at');
		window.logicalWidth = 1000;
		GetRenderTextureFitRectangle(target, false, at);
		near(at.width, 1000, "as wide as the screen");
		check(at.y == Math.ffloor((720 - 562.5) / 2), 'centered down: $at');
		GetRenderTextureFitRectangle(target, true, at);
		check(at.width == 640 && at.x == 180 && at.y == 180, 'a whole scale, centered: $at');
		SetMouseRenderTextureFit(target, true);
		check(RCore.mouseOffsetX == -180 && RCore.mouseScaleX == 1, "the mouse offset to the render texture's corner");
		SetMouseOffset(0, 0);
		SetMouseScale(1, 1);

		// A progress bar's fill clipped to its value, its edge centered on the fill's end: half of a bar 200 across.
		var skin = GuiSkinFromTexture(texture, new NPatchInfo(new Rectangle(0, 0, 64, 32), 8, 0, 8, 0, NPATCH_THREE_PATCH_HORIZONTAL));
		skin.fillMode = GUI_SKIN_FILL_CLIPPED;
		skin.fillEdge = LoadTextureFromImage(GenImageColor(6, 10, WHITE));
		GuiSetSkin(PROGRESSBAR, GUI_SKIN_FILL, skin);
		records();
		check(RGui.drawSkin(PROGRESSBAR, 1, STATE_NORMAL, new Rectangle(0, 0, 100, 20), new Rectangle(0, 0, 200, 20), RED), "the fill hook is set");
		var cells = records();
		check(cells.length == 3, 'the start cap, the middle up to the value and the edge, not ${cells.length} records');
		near(cells[1][4], 100, "the middle cut at the value");
		near(cells[1][10] * 64, 32, "showing the middle's first half");
		check(cells[2][0] == 97 && cells[2][1] == 5 && cells[2][4] == 103, 'the edge centered at (100, 10): ${cells[2]}');
		GuiClearSkins();
		check(!RGui.drawSkin(PROGRESSBAR, 1, STATE_NORMAL, new Rectangle(0, 0, 100, 20), new Rectangle(0, 0, 200, 20), RED),
			"cleared, the fill is raygui's again");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
