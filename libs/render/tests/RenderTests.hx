import haxe.io.Bytes;
import helix.geometry.Camera2D;
import helix.geometry.Camera3D;
import helix.geometry.Mesh3D;
import helix.math.Bounds3D;
import helix.math.Matrix2D;
import helix.math.Matrix3D;
import helix.platform.Blend;
import helix.render.*;
import helix.services.fonts.Font2D;
import helix.services.fonts.Glyph2D;
import helix.services.images.Image;

/** Checks helix-render's work on the CPU over a recording stand-in for the GPU: the frame's passes in order, copies made on write and
	their textures pooled, clears recorded in order, viewports and scissors; the 2D batch's joining and splitting of GPU draws, culling,
	shapes, sprites and draw lists; text measured, wrapped and aligned, a character a font lacks drawn as its stand-in and warned of once;
	the 3D batch's views, points, lines, polygon modes, instances,
	meshes, materials, mesh state and skinning. */
@:access(helix.services.fonts)
@:access(helix.render)
class RenderTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function throws(f:() -> Void, part:String, message:String):Void {
		var thrown:Null<String> = null;
		try
			f()
		catch (e:Dynamic)
			thrown = Std.string(e);
		check(thrown != null && thrown.indexOf(part) >= 0, '$message (threw ${thrown})');
	}

	static function near(a:Float, b:Float, within = 1e-4):Bool
		return Math.abs(a - b) <= within;

	// A font of fixed glyphs: size 10, ascent 8, descent -2, gap 2; each glyph 4 wide, advancing 5; a space advancing 3.
	static function font():Font2D {
		var glyphs = [
			for (c in 33...127)
				new Glyph2D(c, (c - 33) * 4 % 64, Std.int((c - 33) * 4 / 64) * 8, 4, 8, 0, -8, 5)
		];
		glyphs.push(new Glyph2D(32, 0, 0, 0, 0, 0, 0, 3));
		return new Font2D(Coverage, 10, 8, -2, 2, Image.filled(64, 64, 0xffffffff), glyphs);
	}

	static function vertexX(d:Dynamic, i:Int, stride:Int):Float
		return (d.vertices : Bytes).getFloat((d.first + i) * stride);

	static function vertexY(d:Dynamic, i:Int, stride:Int):Float
		return (d.vertices : Bytes).getFloat((d.first + i) * stride + 4);

	static function main():Void {
		frames();
		batching2D();
		culling2D();
		text();
		missingGlyphs();
		shapes();
		lists2D();
		views3D();
		draws3D();
		meshes3D();
		var space:ColorSpace = Linear, align:TextAlign2D = Right;
		check('$space $align' == "Linear Right", "the enums print as their names: $space $align");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}

	static function frames():Void {
		var g = new RecordingGraphics(),
			r = new Renderer(g),
			b = new Batch2D(r);
		var target = r.createRenderTarget(64, 32),
			other = r.createRenderTarget(16, 16, Rgba8, None);
		check(target.msaaSampleCount == 4 && other.msaaSampleCount == 4, "the screen's count when omitted, with depth or without");
		var plain = r.createRenderTarget(8, 8, Rgba8, Buffer, 1),
			many = r.createRenderTarget(8, 8, Rgba8, None, 8),
			odd = r.createRenderTarget(8, 8, Rgba8, None, 3);
		check(plain.msaaSampleCount == 1
			&& many.msaaSampleCount == 4
			&& odd.msaaSampleCount == 2
			&& g.log.indexOf('target ${plain.handle} 8 8 samples 1') >= 0,
			"a count given, passed to the platform, held to what it draws with and rounded down to a power of two");
		throws(() -> r.createRenderTarget(0, 4), "above 0", "a size of 0 refused");
		throws(() -> r.endFrame(), "no frame", "endFrame outside a frame");
		r.beginFrame(200, 100, 0xff102030);
		throws(() -> r.beginFrame(10, 10), "already", "a frame inside a frame");
		r.beginTarget(target, 0xff800000);
		throws(() -> r.beginTarget(other), "already open", "a target pass inside another");
		b.begin();
		throws(() -> r.endTarget(), "batch", "endTarget with a batch open");
		b.fillRectangle(0, 0, 10, 10, 0xffffffff);
		throws(() -> b.drawTexture(target, 0, 0), "draws into", "a target drawn into itself");
		b.end();
		r.endTarget();
		b.begin();
		b.drawTexture(target, 0, 0);
		b.end();
		r.beginTarget(other);
		r.endTarget();
		r.endFrame();
		var passes = [
			for (l in g.log)
				if (StringTools.startsWith(l, "begin") || StringTools.startsWith(l, "resume")) l
		];
		check(passes.length == 3
			&& StringTools.startsWith(passes[0], 'begin target ${target.handle} clear 128 0 0 255')
			&& passes[1] == 'resume target ${other.handle}'
			&& passes[2] == "begin screen 200 100 clear FF102030",
			"target passes first, in the order begun, then the screen's: "
			+ passes);
		check(g.log.indexOf("viewport 0 0 200 100") > 0, "the screen's viewport from the bottom left");

		// Copy on write: a target read, then drawn into again.
		g.forget();
		var first = target.handle;
		r.beginFrame(200, 100);
		b.begin();
		b.drawTexture(target, 0, 0);
		b.end();
		r.beginTarget(target);
		b.begin();
		b.fillRectangle(0, 0, 4, 4, 0xffffffff);
		b.end();
		r.endTarget();
		check(target.handle != first
			&& target.sharedTexture.texture == target.handle, "a target read then drawn into takes a fresh texture");
		b.begin();
		b.drawTexture(target, 0, 0);
		b.end();
		r.endFrame();
		var second = target.handle;
		check(g.draws[0].textures[0] == first && g.draws[2].textures[0] == first && g.draws[3].textures[0] == second,
			"the copy pass reads the old texture, the screen's first draw the old, its second the new");
		check(g.log.indexOf('begin target $second clear 0 0 0 0') >= 0, "the fresh texture cleared, then the old copied into it");
		check(g.textures.exists(first), "the old texture kept after the frame, pooled");
		// The next frame takes the pooled one back: two textures, ping-ponged.
		r.beginFrame(200, 100);
		b.begin();
		b.drawTexture(target, 0, 0);
		b.end();
		r.beginTarget(target, 0xff000000);
		r.endTarget();
		r.endFrame();
		check(target.handle == first, "a target read and redrawn each frame ping-pongs between two textures");
		// A frame where nothing reads it: no copy, and the pooled texture freed after a frame unused.
		r.beginFrame(200, 100);
		r.beginTarget(target, 0xff000000);
		r.endTarget();
		r.endFrame();
		r.beginFrame(200, 100);
		r.endFrame();
		check(!g.textures.exists(second), "a pooled texture unused for a frame is freed");

		// clearTarget with a batch open: the draws before dropped, the batch still open.
		g.forget();
		r.beginFrame(200, 100);
		b.begin();
		b.fillRectangle(0, 0, 4, 4, 0xffff0000);
		r.clearTarget(0xff00ff00);
		check(b.open, "a batch stays open through a clear");
		b.fillRectangle(0, 0, 8, 8, 0xff0000ff);
		b.end();
		r.endFrame();
		check(g.draws.length == 1 && g.draws[0].count == 6 && g.log.indexOf("begin screen 200 100 clear FF00FF00") >= 0,
			"the draws before a clear dropped, the pass cleared to its color");

		// Viewport and scissor, from the top left, given to the platform from the bottom left.
		g.forget();
		r.beginFrame(200, 100);
		r.applyViewport(10, 20, 50, 30);
		check(r.viewportWidth == 50 && r.viewportHeight == 30, "the viewport's size");
		b.begin();
		throws(() -> r.applyViewport(0, 0, 1, 1), "batch open", "a viewport set with a batch open");
		r.applyScissor(5, 10, 20, 40);
		b.fillRectangle(0, 0, 4, 4, 0xffffffff);
		r.resetScissor();
		b.end();
		r.resetViewport();
		r.endFrame();
		check(g.log.indexOf("viewport 10 50 50 30") >= 0
			&& g.log.indexOf("scissor 5 50 20 40") >= 0
			&& g.log.indexOf("reset scissor") >= 0,
			"a viewport and a scissor from the bottom left: " + g.log);

		// Updates before the pass they are called in; disposal after the frame.
		var texture = r.createTexture(Image.filled(4, 4, 0xffffffff));
		g.forget();
		r.beginFrame(200, 100);
		texture.update(Image.filled(2, 2, 0xff000000), 1, 1);
		var region = texture.writeWhiteTexel(3, 3);
		check(region.regionX == 3 && region.regionWidth == 1, "a white texel's region");
		throws(() -> texture.update(Image.filled(4, 4, 0), 2, 0), "outside", "an update outside the texture");
		throws(() -> target.update(Image.filled(1, 1, 0)), "render target", "an update of a render target");
		b.begin();
		b.drawTexture(texture, 0, 0);
		b.end();
		var held = texture.handle;
		texture.dispose();
		check(texture.handle == 0 && texture.sharedTexture.texture == 0 && g.textures.exists(held), "disposed in a frame: freed after it");
		r.endFrame();
		check(g.log[0] == 'update $held 1 1 2 2' && g.log[1] == 'update $held 3 3 1 1' && !g.textures.exists(held),
			"updates before the pass; the texture freed after the frame");
		r.beginFrame(10, 10);
		b.begin();
		throws(() -> b.drawTexture(texture, 0, 0), "disposed", "a disposed texture's draw");
		b.end();
		r.endFrame();
		// Resize: the old texture freed after the frame.
		var before = target.handle;
		target.resize(32, 32);
		check(target.width == 32 && target.handle != before && !g.textures.exists(before), "a resize outside a frame frees the old at once");
		r.dispose();
		check([for (_ in g.textures) 1].length == 0, "dispose frees every texture");
	}

	static function batching2D():Void {
		var g = new RecordingGraphics(),
			r = new Renderer(g),
			b = new Batch2D(r);
		var sheet = r.createTexture(Image.filled(64, 64, 0xffffffff)),
			other = r.createTexture(Image.filled(8, 8, 0xffffffff));
		var a = new TextureRegion2D(sheet, 0, 0, 16, 16),
			c = new TextureRegion2D(sheet, 16, 0, 16, 16);
		r.beginFrame(400, 300);
		b.begin();
		b.drawSprite(a, 10, 10);
		b.customData = 0x11223344;
		b.drawSprite(c, 40, 10);
		b.transform.appendTranslation(5, 0, b.transform);
		b.drawSprite(a, 70, 10);
		b.shapeRegion = sheet.writeWhiteTexel(63, 63);
		b.fillCircle(100, 100, 10, 0xffff0000);
		b.drawSprite(a, 70, 10);
		b.end();
		r.endFrame();
		check(g.draws.length == 2,
			"sprites of one sheet, customData and a transform between them, one GPU draw; assigning shapeRegion ends it: " + g.draws.length);
		var d = g.draws[0];
		check(d.count == 18 && near(vertexX(d, 12, 24), 75), "three quads, the third moved by the transform");
		check(d.vertices.get((d.first + 6) * 24 + 20) == 0x22
			&& d.vertices.get((d.first + 6) * 24 + 23) == 0x11, "customData's bytes in the vertex");
		check(g.draws[1].textures[0] == sheet.handle, "shapes drawn from the sheet's white texel join its GPU draw");
		var u = g.draws[1].vertices.getFloat(g.draws[1].first * 24 + 8);
		check(near(u, 63.5 / 64), "a shape reads the white texel's center");
		b.resetState();
		check(b.transform.tx == 0 && b.customData == 0 && b.blend == Blend.ALPHA, "resetState puts the draw state back");

		g.forget();
		r.beginFrame(400, 300);
		b.begin();
		b.drawSprite(a, 10, 10);
		b.drawTexture(other, 0, 0);
		b.blend = Blend.ADDITIVE;
		b.drawTexture(other, 0, 0);
		b.blend = Blend.ALPHA;
		b.drawSprite(a, 10, 10);
		r.applyScissor(0, 0, 10, 10);
		b.drawSprite(a, 10, 10);
		b.end();
		r.endFrame();
		check(g.draws.length == 5
			&& g.draws[2].pipeline.blend == Blend.ADDITIVE, "a texture, a blend and a scissor each start the next GPU draw");
		check(g.draws[0].pipeline.depthTest == Off && g.draws[0].pipeline.cull == None && g.draws[0].pipeline.flip == ClipScale,
			"2D: no depth, no culling, flipped by the clip scale");
		throws(() -> b.drawTexture(other, 0, 0), "outside begin", "a draw outside begin and end");
		// A sprite's flips and origin.
		g.forget();
		r.beginFrame(400, 300);
		b.begin();
		b.drawSprite(TextureRegion2D.fromTexture(other, 4, 4), 100, 100, 0, 2, 1, -1, true);
		b.end();
		r.endFrame();
		var s = g.draws[0];
		check(near(vertexX(s, 0, 24), 108) && near(vertexX(s, 1, 24), 92) && near(vertexY(s, 0, 24), 96),
			"a sprite placed by its origin, scaled, and mirrored by flipX about it");
		r.dispose();
	}

	static function culling2D():Void {
		var g = new RecordingGraphics(),
			r = new Renderer(g),
			b = new Batch2D(r);
		var t = r.createTexture(Image.filled(8, 8, 0xffffffff));
		var camera = new Camera2D();
		camera.transform.position.set(1000, 1000);
		r.beginFrame(100, 100);
		b.beginCamera(camera);
		b.drawTexture(t, 0, 0);
		b.fillCircle(1050, 1050, 4, 0xffffffff);
		b.end();
		b.begin();
		b.drawTexture(t, 200, 0);
		b.culling = false;
		b.drawTexture(t, 200, 0);
		b.culling = true;
		b.end();
		r.endFrame();
		check(g.draws.length == 2 && g.draws[1].count == 6, "what is out of the camera's or the viewport's view skipped; with culling off drawn");
		r.dispose();
	}

	static function text():Void {
		var g = new RecordingGraphics(),
			r = new Renderer(g),
			b = new Batch2D(r);
		var f = r.createFont(font());
		check(f.lineHeight == 12, "a line's height: ascent, descent and gap");
		var size = f.measureText("ab c");
		check(near(size.x, 5 + 5 + 3 + 4 * 0 + 5) && near(size.y, 10), "one line: the advances, its height ascent to descent: " + size);
		size = f.measureText("ab\nabc", 20, 1);
		check(near(size.x, (15) * 2 + 2) && near(size.y, (12 + 10) * 2), "two lines at twice the size, letter spacing between characters: " + size);
		var layout = new TextLayout2D(f, "aaaa bbbb cc", 10);
		check(layout.lineCount == 1 && near(layout.width, 20 + 3 + 20 + 3 + 10), "no width: one line");
		layout.maxWidth = 45;
		check(layout.lineCount == 2 && near(layout.width, 43) && near(layout.height, 22), "wrapped between words: "
			+ layout.lineCount
			+ " "
			+ layout.width);
		layout.text = "aaaaaaaaaaaa";
		check(layout.lineCount == 2 && near(layout.width, 45), "a word wider than the box broken between characters");
		layout.text = "aa\n\nbb";
		check(layout.lineCount == 3, "line breaks kept, an empty line too");
		layout.maxWidth = -5;
		check(layout.maxWidth == 0, "a width below 0 is 0");
		layout.text = "a";
		layout.maxWidth = 100;
		layout.align = Right;
		r.beginFrame(200, 200);
		b.begin();
		b.drawTextLayout(layout, 10, 0);
		b.drawText(f, "a b", 0, 50);
		b.end();
		r.endFrame();
		var d = g.draws[0];
		check(d.textures[0] == f.atlas.handle && near(vertexX(d, 0, 24), 10 + 100 - 5) && near(vertexY(d, 0, 24), 0),
			"a right-aligned line ends at the box's right edge, its glyph's top at the ascent");
		check(d.count == 18 && near(vertexX(d, 6, 24), 0) && near(vertexX(d, 12, 24), 8) && near(vertexY(d, 6, 24), 50),
			"a space draws nothing; text's top at y");
		r.dispose();
		kerning();
	}

	// A font's kerning pairs: measured, laid out and drawn unless kerned is false; a hard-edged font's atlas sampled nearest.
	static function kerning():Void {
		var g = new RecordingGraphics(),
			r = new Renderer(g),
			b = new Batch2D(r);
		var base = font();
		var f = r.createFont(new Font2D(Coverage, 10, 8, -2, 2, base.atlas, base.glyphs, [{first: 97, second: 98, amount: -2}]));
		check(near(f.measureText("ab").x, 8) && near(f.measureText("ab", 20).x, 16) && near(f.measureText("ba").x, 10),
			"a pair kerned as the font gives it, at the size drawn; another pair not");
		check(near(f.measureText("ab", null, 0, false).x, 10), "unkerned when kerned is false");
		var layout = new TextLayout2D(f, "abab");
		check(near(layout.width, 16), "a layout kerned");
		layout.kerned = false;
		check(near(layout.width, 20), "a layout unkerned");
		r.beginFrame(64, 64);
		b.begin();
		b.drawText(f, "ab", 0, 0);
		b.drawText(f, "ab", 0, 20, 0xffffffff, null, 0, false);
		b.end();
		r.endFrame();
		var d = g.draws[0];
		check(near(vertexX(d, 6, 24), 3) && near(vertexX(d, 18, 24), 5), "drawn kerned, and unkerned when asked");
		check(f.atlas.sampling == helix.platform.Sampling.LINEAR, "a coverage font's atlas sampled linearly");
		var hard = r.createFont(new Font2D(Bitmap, 10, 8, -2, 2, base.atlas, base.glyphs));
		check(hard.atlas.sampling == helix.platform.Sampling.NEAREST, "a hard-edged font's atlas sampled nearest");
		r.dispose();
	}

	static function missingGlyphs():Void {
		var g = new RecordingGraphics(),
			r = new Renderer(g),
			b = new Batch2D(r);
		var warnings:Array<String> = [];
		var listener = (level:helix.log.LogLevel, line:String) -> if (level == Warning) warnings.push(line);
		helix.log.Log.listen(listener);
		var f = r.createFont(font());
		check(near(f.measureText("aé").x, 10), "a character the font lacks measured as its '?'");
		r.beginFrame(64, 64);
		b.begin();
		b.drawText(f, "ééü", 0, 0);
		b.drawText(f, "a\tb\r", 0, 20);
		b.end();
		r.endFrame();
		var question = f.font.getGlyph("?".code);
		check(g.draws[0].count == 6 * 5 && near(vertexX(g.draws[0], 6, 24), 5), "each character it lacks drawn as its '?', advancing as it does");
		check(near((g.draws[0].vertices : Bytes).getFloat(g.draws[0].first * 24 + 8), question.x / 64), "from the '?' glyph's place on the atlas");
		check(warnings.length == 2 && warnings[0].indexOf("U+00E9") >= 0 && warnings[1].indexOf("U+00FC") >= 0,
			'warned once per character a font lacks, not for a control character: $warnings');
		f.dispose();

		var noQuestion = r.createFont(new Font2D(Coverage, 10, 8, -2, 2, Image.filled(8, 8, 0xffffffff), [new Glyph2D(65, 0, 0, 4, 8, 0, -8, 5)]));
		check(near(noQuestion.measureText("AéA").x, 10) && warnings.length == 3 && warnings[2].indexOf("nothing") >= 0,
			"with neither '?' nor .notdef, a character it lacks skipped, and warned of: " + warnings);
		noQuestion.measureText("é");
		check(warnings.length == 3, "warned once per font");
		noQuestion.dispose();
		var notdef = new Glyph2D(-1, 4, 0, 4, 8, 0, -8, 7);
		var withNotdef = r.createFont(new Font2D(Coverage, 10, 8, -2, 2, Image.filled(8, 8, 0xffffffff), [new Glyph2D(65, 0, 0, 4, 8, 0, -8, 5), notdef],
			null, notdef));
		check(near(withNotdef.measureText("Aé").x, 12) && warnings.length == 4 && warnings[3].indexOf(".notdef") >= 0,
			"without a '?', its .notdef: " + warnings);
		withNotdef.dispose();
		helix.log.Log.unlisten(listener);
		r.dispose();
	}

	static function shapes():Void {
		var count = 0;
		var t = new Tessellator2D((_, _, _, _, _, _) -> count++);
		check(!t.fillPolygon([0, 0, 10, 10, 10, 0, 0, 10]) && count == 0, "a polygon whose edges cross is refused, nothing drawn");
		check(t.fillPolygon([0, 0, 10, 0, 10, 10, 5, 4, 0, 10]) && count == 3, "a concave pentagon is three triangles");
		count = 0;
		t.stroke([0, 0, 10, 0, 10, 10], false, 2);
		check(count == 6, "two segments and a mitered corner: " + count);
		count = 0;
		t.stroke([0, 0, 10, 0, 0, .5], false, 2);
		check(count == 5, "a sharp corner bevelled, its miter past twice the thickness: " + count);
		t.scale = 1;
		var small = t.segments(10);
		t.scale = 10;
		check(t.segments(10) > small, "a curve cut finer where it is drawn larger");
	}

	static function lists2D():Void {
		var g = new RecordingGraphics(),
			r = new Renderer(g),
			b = new Batch2D(r);
		var list = new DrawList2D();
		list.fillRectangle(0, 0, 20, 10, 0xffffffff);
		list.drawLine(0, 0, 40, 0, 2, 0xffffffff);
		var points = [0., 0, 5, 5, 0, 10];
		list.fillPolygon(points, 0xffffffff);
		points[0] = 1000;
		check(list.callCount == 3 && list.bounds.maxX == 41 && list.bounds.minY == -1, "a list's box around what it holds; arrays copied");
		r.beginFrame(100, 100);
		b.begin();
		b.drawList(list, Matrix2D.fromTranslation(10, 10));
		b.drawList(list, Matrix2D.fromTranslation(500, 10));
		b.end();
		r.endFrame();
		check(g.draws.length == 1 && g.draws[0].count == 6 + 6 + 3 && near(vertexX(g.draws[0], 0, 24), 10),
			"replayed placed, one GPU draw; a list out of view skipped whole");
		check(list.makeEmpty().callCount == 0 && list.bounds.isEmpty, "makeEmpty");
		r.dispose();
	}

	static function views3D():Void {
		var view = new View3D().setFromScreen(100, 50);
		var box = new Bounds3D().set(10, 10, 0, 20, 20, 0);
		check(view.isInView(box), "a box in a screen view");
		check(!view.isInView(new Bounds3D().set(200, 10, 0, 210, 20, 0)), "one past its right");
		var camera = new Camera3D();
		camera.transform.position.set(0, 0, 10);
		view.setFromCamera(camera, 1);
		check(view.isInView(new Bounds3D().set(-1, -1, -1, 1, 1, 1)) && !view.isInView(new Bounds3D().set(-1, -1, 20, 1, 1, 21)),
			"in front of the camera, and behind it");
		var g = new RecordingGraphics(),
			r = new Renderer(g),
			b = new Batch3D(r);
		var left = new View3D().setFromScreen(50, 100).setViewport(0, 0, 50, 100);
		var right = new View3D().setFromScreen(50, 100).setViewport(50, 0, 50, 100);
		r.beginFrame(100, 100);
		throws(() -> b.beginViews([new View3D().setViewport(60, 0, 50, 100)]), "outside", "a view past the viewport");
		b.beginViews([left, right]);
		b.drawLine(10, 10, 0, 20, 20, 0, 0xffffffff);
		b.end();
		r.endFrame();
		check(g.draws.length == 2 && g.log.indexOf("viewport 0 0 50 100") >= 0 && g.log.indexOf("viewport 50 0 50 100") >= 0,
			"a draw drawn once in each view, in its rectangle");
		r.dispose();
	}

	static function draws3D():Void {
		var g = new RecordingGraphics(),
			r = new Renderer(g),
			b = new Batch3D(r);
		var screen = new View3D().setFromScreen(100, 100);
		r.beginFrame(100, 100);
		b.beginViews([screen]);
		b.drawPoints([10, 10, 0, 20, 20, 0], 0xffffffff);
		b.pointSize = 8;
		b.drawPoints([10, 10, 0], 0xffffffff);
		b.resetState();
		b.drawLines([0, 0, 0, 50, 50, 0], 0xffffffff, null, 4);
		b.drawLines([0, 0, 0, 50, 50, 0, 90, 10, 0], 0xffffffff, null, 1, true);
		b.polygonMode = Lines;
		b.drawTriangles(null, [0, 0, 0, 10, 0, 0, 0, 10, 0]);
		b.resetState();
		b.drawSprite(new TextureRegion2D(r.white, 0, 0, 1, 1), 50, 50, 0, 10, 10);
		b.drawPoints([500, 500, 0], 0xffffffff);
		b.end();
		r.endFrame();
		var kinds = [for (d in g.draws) '${d.pipeline.primitive}:${d.count}'];
		check(kinds.join(" ") == "Points:2 Triangles:6 Triangles:6 Lines:10 Triangles:6",
			"one-pixel points, a large point and a wide line as quads, thin lines, a triangle's edges, a sprite in the plane; out of view skipped: " +
			kinds.join(" "));
		check(g.draws[1].pipeline.buffers[0].stride == 60 && g.draws[0].pipeline.buffers[0].stride == 40,
			"quads made in the vertex stage read 60-byte vertices");
		r.dispose();
	}

	static function meshes3D():Void {
		var g = new RecordingGraphics(),
			r = new Renderer(g),
			b = new Batch3D(r);
		var mesh = r.createMesh(Mesh3D.fromBox(1, 1, 1));
		check(mesh.vertexCount == 24 && mesh.triangleCount == 12 && near(mesh.bounds.maxX, .5), "a box's mesh: its counts and box");
		var material = new Material3D();
		var camera = new Camera3D();
		camera.transform.position.set(0, 0, 10);
		r.beginFrame(100, 100);
		b.begin(camera);
		throws(() -> b.drawMesh(mesh, material, new Matrix3D()), "stage 2", "a lit material waits for stage 2");
		material.shading = Unlit;
		var state = new MeshState3D();
		state.depthTest = Off;
		b.drawMesh(mesh, material, new Matrix3D(), null, null, 0xff808080, state);
		b.drawMesh(mesh, material, Matrix3D.fromTranslation(0, 0, 50));
		var copies = [for (i in 0...4) Matrix3D.fromTranslation(i * 100 - 100, 0, 0)];
		b.drawMeshInstanced(mesh, material, copies, null, null, 1, 3);
		b.polygonMode = Lines;
		b.drawMesh(mesh, material, new Matrix3D());
		b.resetState();
		b.end();
		r.endFrame();
		check(g.draws.length == 3, "a mesh behind the camera culled: " + g.draws.length);
		var d = g.draws[0];
		check(d.pipeline.depthTest == Off && d.pipeline.indexed && d.count == 36 && d.pipeline.cull == Back,
			"the state's depth test in place of the material's, its cull kept, indexed");
		check(g.draws[1].instanceCount == 1 && g.draws[1].firstInstance == 0, "instanced copies out of view left out: " + g.draws[1].instanceCount);
		check(g.draws[2].pipeline.primitive == Lines && g.draws[2].count == 72, "a mesh's edges in polygon mode Lines");
		// Skinning: two joints, a vertex on each.
		var skinned = new Mesh3D();
		skinned.positions = [0, 0, 0, 1, 0, 0, 0, 1, 0];
		skinned.jointIndices = [0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0];
		skinned.weights = [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0];
		var gpu = r.createMesh(skinned);
		check(gpu.hasJoints && gpu.jointBoxes.length == 2, "a joint's box for each joint");
		var skin = [new Matrix3D(), Matrix3D.fromTranslation(0, 5, 0)];
		var bounds = gpu.computeBounds(Matrix3D.fromTranslation(10, 0, 0), skin);
		check(near(bounds.maxY, 6) && near(bounds.minX, 10), "exact bounds posed on the CPU: " + bounds.maxY);
		g.forget();
		r.beginFrame(100, 100);
		b.begin(camera);
		b.drawMesh(gpu, material, new Matrix3D(), skin);
		b.end();
		r.endFrame();
		var updated = [for (i => l in g.log) if (StringTools.startsWith(l, "update")) i],
			drawn = [for (i => l in g.log) if (StringTools.startsWith(l, "draw")) i];
		check(updated.length == 1 && drawn.length == 1 && updated[0] < drawn[0], "a skin's matrices written before its draw: " + g.log);
		gpu.dispose();
		r.beginFrame(100, 100);
		b.begin(camera);
		throws(() -> b.drawMesh(gpu, material, new Matrix3D()), "disposed", "a disposed mesh's draw");
		b.end();
		r.endFrame();
		r.dispose();
	}
}
