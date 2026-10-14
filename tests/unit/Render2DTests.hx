import haxe.io.Bytes;
import helix.graphics.IGraphics;
import helix.graphics.PipelineKind;
import helix.graphics.Sampling;
import helix.graphics.ShaderSource;
import helix.graphics.TextureFormat;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Node2D;
import helix.render2d.Polygon2D;
import helix.render2d.Stage2D;
import helix.render2d.Text2D;
import helix.render2d.Texture2D;

/** Graphics that only counts: handles, and the draws and viewports of a frame. */
class CountingGraphics implements IGraphics {
	var next = 1;

	public var draws:Array<{vertices:Int, first:Int, sampling:Sampling}> = [];
	public var viewports:Array<Array<Int>> = [];
	public var uploaded:Null<Bytes>;

	public function new() {}

	public function createTexture(width:Int, height:Int, levels:Array<Bytes>, format:TextureFormat = Rgba8):Int
		return next++;

	public function canSample(format:TextureFormat):Bool
		return format == Rgba8 || format == Astc4x4;

	public function createBuffer(capacityBytes:Int):Int
		return next++;

	public function createStaticBuffer(data:Bytes, bytes:Int, index:Bool):Int
		return next++;

	public function createPipeline(kind:PipelineKind, alpha:Bool, shader:Int = 0, doubleSided:Bool = false, clockwise:Bool = false):Int
		return next++;

	public var screen:Null<{textures:Array<Int>, uniforms:Array<Null<Bytes>>}>;

	public function createShader(source:ShaderSource):Int
		return next++;

	public function destroyShader(handle:Int):Void {}

	public function drawScreen(pipeline:Int, textures:Array<Int>, samplings:Array<Sampling>, uniforms:Array<Null<Bytes>>):Void
		screen = {textures: textures, uniforms: uniforms};

	public function updateBuffer(handle:Int, data:Bytes, usedBytes:Int):Void
		uploaded = data.sub(0, usedBytes);

	public function createRenderTarget(width:Int, height:Int):Int
		return next++;

	public function beginTargetPass(target:Int, clearColor:Int):Void {}

	public function endTargetPass():Void {}

	public function beginFrame(width:Int, height:Int, clearColor:Int):Void {
		draws = [];
		viewports = [];
	}

	public function setViewport(x:Int, y:Int, w:Int, h:Int):Void
		viewports.push([x, y, w, h]);

	public function draw(pipeline:Int, buffer:Int, texture:Int, sampling:Sampling, vertices:Int, firstVertex:Int, ?uniforms:Bytes):Void
		draws.push({vertices: vertices, first: firstVertex, sampling: sampling});

	public var meshPipelines:Array<Int> = [];

	public function drawMesh(pipeline:Int, vertices:Int, indices:Int, indexCount:Int, instances:Int, firstInstance:Int, instanceCount:Int,
			textures:Array<Int>, samplings:Array<Sampling>, uniforms:Array<Null<Bytes>>):Void
		meshPipelines.push(pipeline);

	public function endFrame():Void {}

	public function destroyTexture(handle:Int):Void {}

	public function destroyBuffer(handle:Int):Void {}

	public function destroyPipeline(handle:Int):Void {}

	public function shutdown():Void {}
}

/** Polygon2D, Node2D's transforms, and Stage2D's walk, culling and cameras, through a Batch2D on graphics that only counts. */
class Render2DTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float):Bool
		return Math.abs(a - b) < 1e-9;

	// The area the triangles cover, summed.
	static function covered(points:Array<Float>, triangles:Array<Int>):Float {
		var sum = 0., i = 0;
		while (i < triangles.length) {
			sum += Math.abs(Polygon2D.doubleArea([
				for (k in 0...3)
					for (c in 0...2)
						points[triangles[i + k] * 2 + c]
			])) / 2;
			i += 3;
		}
		return sum;
	}

	static function main():Void {
		// Polygons: a square either way round, and a concave arrow, covered exactly by n - 2 triangles.
		var square = [0., 0, 10, 0, 10, 10, 0, 10];
		var reversed = [0., 10, 10, 10, 10, 0, 0, 0];
		var arrow = [0., 0, 10, 5, 0, 10, 3, 5];
		for (points in [square, reversed, arrow]) {
			var triangles = Polygon2D.triangulate(points);
			check(triangles.length == (points.length / 2 - 2) * 3, "A simple polygon of n points is n - 2 triangles");
			check(near(covered(points, triangles), Math.abs(Polygon2D.doubleArea(points)) / 2), "The triangles cover the polygon exactly");
		}
		check(Polygon2D.doubleArea(square) > 0, "Clockwise on screen (y down) is a positive area");
		check(Node2D.polygon([0, 0, 1, 1]) == null
			&& Node2D.polygon([0, 0, 1, 1, 2]) == null, "A polygon needs 3 points, x and y in pairs");

		// Transforms: a child of a turned, scaled, placed parent; toLocal undoes toWorld.
		var stage = new Stage2D(),
			parent = Node2D.group(),
			child = Node2D.circle(1);
		parent.setPosition(100, 50);
		parent.setRotation(Math.PI / 2);
		parent.setScale(2, 2);
		child.setPosition(10, 0);
		parent.add(child);
		stage.add(parent);
		var gpu = new CountingGraphics(),
			batch = new Batch2D(gpu),
			camera = new Camera2D();
		camera.setViewport(400, 300);
		camera.pixels(1);
		gpu.beginFrame(400, 300, 0);
		batch.begin(camera);
		stage.draw(batch, camera);
		batch.end();
		// Turned a quarter clockwise on screen (y down), +x points down: 10 along x, doubled, is 20 below the parent.
		check(near(child.toWorldX(0, 0), 100) && near(child.toWorldY(0, 0), 70), "A child is placed by its parent's turn, scale and position");
		check(near(child.toLocalX(child.toWorldX(3, -4), child.toWorldY(3, -4)), 3)
			&& near(child.toLocalY(child.toWorldX(3, -4), child.toWorldY(3, -4)), -4),
			"toLocal undoes toWorld");
		parent.setPosition(0, 0);
		gpu.beginFrame(400, 300, 0);
		batch.begin(camera);
		stage.draw(batch, camera);
		batch.end();
		check(near(child.toWorldY(0, 0), 20), "Moving the parent moves the child at the next draw");
		check(!child.add(parent) && !parent.add(parent), "No node becomes its own ancestor");

		// A mirrored sprite covers the same box; a sprite with no texture draws nothing.
		var texture = Texture2D.fromRgba(gpu, 4, 2, Bytes.alloc(32));
		var sprite = Node2D.sprite(texture);
		check(sprite.getWidth() == 4 && sprite.getHeight() == 2, "A sprite with no size is its texture's size in texels");
		sprite.setSource(1, 0, 2, 2);
		check(sprite.getWidth() == 2 && sprite.getSourceWidth() == 2, "A region gives it the region's size");
		check(!Node2D.circle(1).setSource(0, 0, 1, 1) && !Node2D.circle(1).setTexture(texture), "Sprite calls refuse other kinds");

		// Culling: of three circles, the one far outside the view isn't drawn; hidden nodes and their children aren't either.
		var culled = new Stage2D();
		for (x in [10., 390, 5000]) {
			var c = Node2D.circle(5);
			c.setPosition(x, 150);
			culled.add(c);
		}
		var hidden = Node2D.group();
		hidden.add(Node2D.circle(5));
		hidden.setVisible(false);
		culled.add(hidden);
		gpu.beginFrame(400, 300, 0);
		batch.begin(camera);
		culled.draw(batch, camera);
		batch.end();
		check(culled.getDrawnCount() == 2, "Only nodes in view, and shown, are drawn");

		// Two cameras in one batch: a run each, each in its own viewport.
		var left = new Camera2D(), right = new Camera2D();
		left.setViewport(400, 300);
		left.setViewportArea(0, 0, 200, 300);
		left.pixels(1);
		right.setViewport(400, 300);
		right.setViewportArea(200, 0, 200, 300);
		right.pixels(1);
		gpu.beginFrame(400, 300, 0);
		batch.begin(left);
		batch.rect(0, 0, 10, 10, -1);
		stage.draw(batch, right);
		batch.end();
		check(gpu.draws.length == 2 && gpu.viewports.length == 2 && gpu.viewports[0][0] == 0 && gpu.viewports[1][0] == 200,
			"A camera change splits the batch, each part in its camera's viewport");
		check(gpu.draws[0].vertices == 6 && gpu.draws[1].first == 6, "The parts follow each other in the one upload");

		// The transform places vertices: a rect at the origin, moved 10 right, starts at clip x of world 10.
		gpu.beginFrame(400, 300, 0);
		batch.begin(camera);
		batch.setTransform(1, 0, 0, 1, 10, 0);
		batch.rect(0, 0, 1, 1, -1);
		batch.end();
		check(Math.abs(gpu.uploaded.getFloat(0) - camera.clipX(10)) < 1e-6, "setTransform places what follows");
		// Sampling: its bits round-trip, and a change of a texture's sampling splits the batch's run, each part sampled as it was then.
		var sampling = new Sampling(true, Repeat, Mirror);
		check(sampling.isLinear()
			&& sampling.getWrapU() == Repeat
			&& sampling.getWrapV() == Mirror
			&& (sampling : Int) < Sampling.COUNT,
			"Sampling keeps its filter and wraps");
		check(!sampling.withLinear(false).isLinear() && sampling.withWrap(Clamp, Clamp).getWrapV() == Clamp, "with* change one part");
		gpu.beginFrame(400, 300, 0);
		batch.begin(camera);
		texture.setSampling(Sampling.LINEAR);
		batch.image(texture, 0, 0, 4, 4);
		texture.setSampling(Sampling.NEAREST);
		batch.image(texture, 4, 0, 4, 4);
		batch.image(texture, 8, 0, 4, 4);
		batch.end();
		check(gpu.draws.length == 2 && gpu.draws[0].sampling.isLinear() && !gpu.draws[1].sampling.isLinear() && gpu.draws[1].vertices == 12,
			"A texture drawn smooth then sharp is two runs, sampled as each was drawn");

		// KTX 1: a 5 x 3 ASTC 4x4 file with its mipmaps (2 x 1, 1 x 1): one block a level.
		var file = new haxe.io.BytesBuffer();
		for (b in [0xAB, 0x4B, 0x54, 0x58, 0x20, 0x31, 0x31, 0xBB, 0x0D, 0x0A, 0x1A, 0x0A])
			file.addByte(b);
		for (v in [0x04030201, 0, 1, 0, 0x93B0, 0x1908, 5, 3, 0, 0, 1, 3, 4])
			file.addInt32(v);
		file.addInt32(0); // key/value data: 4 bytes of nothing
		var levelSizes = [2 * 1 * 16, 16, 16];
		for (size in levelSizes) {
			file.addInt32(size);
			for (i in 0...size)
				file.addByte(i);
		}
		var ktx = helix.render2d.Ktx.read(file.getBytes());
		check(ktx.format == Astc4x4 && ktx.width == 5 && ktx.height == 3 && ktx.levels.length == 3 && ktx.levels[0].length == 32,
			"A KTX file's format, size and levels are read");
		var bad = false;
		try
			helix.render2d.Ktx.read(Bytes.alloc(64))
		catch (e:Dynamic)
			bad = true;
		check(bad, "A file that isn't KTX is refused");
		check((Astc4x4 : TextureFormat).levelBytes(5, 3) == 32 && (Rgba8 : TextureFormat).levelBytes(5, 3) == 60,
			"Level sizes: blocks of 4x4, or 4 bytes a texel");

		// "name.ktx" tries the variants this GPU samples (here ASTC only), then the PNG; a variant named outright is tried alone.
		var textures = new helix.render2d.Textures(null, null, gpu);
		check(textures.getCandidates("a/b.ktx").join(",") == "a/b.astc.ktx,a/b.png", "name.ktx: this GPU's variants, then name.png");
		check(textures.getCandidates("a/b.bc7.ktx").join(",") == "a/b.bc7.ktx" && textures.getCandidates("a/b.png").join(",") == "a/b.png",
			"Other paths are themselves");
		// TrueType: the example fonts' characters, outlines and kerning; a baked atlas whose glyphs fit it, with its white texel.
		var komika = new helix.render2d.TrueType(sys.io.File.getBytes("examples/assets/fonts/Komika/KOMIKAH_.ttf"));
		var a = komika.getGlyphIndex("A".code),
			v = komika.getGlyphIndex("V".code);
		check(a > 0 && v > 0 && komika.getGlyphIndex(0x4E00) == 0, "Characters map to glyphs; one the font lacks to 0");
		check(komika.getOutline(a).length > 0
			&& komika.getOutline(komika.getGlyphIndex(" ".code)).length == 0, "A letter has an outline, a space none");
		var h = komika.getGlyphIndex("H".code);
		check(komika.getKerning(a, v) < 0 && komika.getKerning(h, h) == 0, "GPOS kerning closes AV and leaves HH");
		var baked = helix.render2d.FontBaker.bake(komika, [for (c in 32...127) c], 32, 6, 512);
		var fits = true;
		for (g in baked.glyphs)
			fits = fits && g.x + g.width <= baked.width && g.y + g.height < baked.height;
		check(fits
			&& baked.field.get(baked.width * baked.height - 1) == 255, "Glyphs fit the atlas above its free row; the white texel is set");
		check(Math.abs(baked.ascent - baked.descent - 32) < 1e-9, "The baked height is ascent to descent");
		var font = helix.render2d.Font2D.fromTrueType(gpu, sys.io.File.getBytes("examples/assets/fonts/Komika/KOMIKAH_.ttf"));
		check(font.getGlyph(0xE9) != null && font.getGlyph(0x7F) == null && font.getKerning("A".code, "V".code) < 0,
			"A loaded font has Latin-1 and kerning in font pixels");
		check(Text2D.measure(font, "AV", 32) < Text2D.measure(font, "A", 32) + Text2D.measure(font, "V", 32), "Kerning narrows a measured pair");
		var cff = false;
		try
			new helix.render2d.TrueType(Bytes.ofString("OTTO and twelve"))
		catch (e:Dynamic)
			cff = true;
		check(cff, "A file that isn't TrueType is refused");
		// A screen effect's parameters land at their std140 offsets: a float, a vec3 at 16, a vec4 array's second element at 48, a mat4's second
		// column at 96 + 16; the framework's block 1 holds the frame's size and the time; an unset texture is drawn as the frame.
		var stages = {vertex: "", fragment: ""};
		var text = haxe.Json.stringify({
			helixShader: 1,
			kind: "screen",
			attributes: [],
			glsl410: stages,
			glsl300es: stages,
			uniformBlocks: [
				{
					slot: 0,
					stage: "vertex",
					size: 16,
					glslName: "v",
					vec4s: 1,
					name: "helix_screen_vs_params"
				},
				{
					slot: 1,
					stage: "fragment",
					size: 16,
					glslName: "f",
					vec4s: 1,
					name: "helix_screen_params"
				},
				{
					slot: 2,
					stage: "fragment",
					size: 160,
					glslName: "params",
					vec4s: 10,
					name: "params",
					members: [
						{
							name: "strength",
							type: "float",
							offset: 0,
							count: 1
						},
						{
							name: "shift",
							type: "vec3",
							offset: 16,
							count: 1
						},
						{
							name: "weights",
							type: "vec4",
							offset: 32,
							count: 3
						},
						{
							name: "grade",
							type: "mat4",
							offset: 96,
							count: 1
						}
					]
				}
			],
			textures: [
				{
					slot: 0,
					stage: "fragment",
					name: "helix_screen_texture",
					glslName: "a"
				},
				{
					slot: 1,
					stage: "fragment",
					name: "noise_texture",
					glslName: "b"
				}
			]
		});
		var shader = helix.graphics.Shader.fromText(gpu, text),
			effect = new helix.graphics.ScreenEffect(gpu, shader);
		check(effect.getParameters().setFloat("strength", .5)
			&& effect.getParameters().setValues("shift", [1, 2, 3])
			&& effect.getParameters().setValues("weights", [0, 0, 0, 0, 7])
			&& effect.getParameters().setValues("grade", [0, 0, 0, 0, 9]),
			"Parameters are set by name");
		check(!effect.getParameters().setFloat("missing", 1)
			&& !effect.getParameters().setValues("strength", [1, 2])
			&& !effect.getParameters().setTexture("helix_screen_texture", texture),
			"Unknown parameters, too many values and the framework's texture are refused");
		effect.draw(texture, 640, 480, 2.5);
		var block = gpu.screen.uniforms[2], info = gpu.screen.uniforms[1];
		check(block.getFloat(0) == .5 && block.getFloat(16) == 1 && block.getFloat(24) == 3 && block.getFloat(48) == 7 && block.getFloat(112) == 9,
			"Values land at their std140 offsets");
		check(info.getFloat(0) == 640 && info.getFloat(4) == 480 && info.getFloat(8) == 2.5, "Block 1 holds the frame's size and the time");
		check(gpu.screen.textures.length == 2 && gpu.screen.textures[1] == texture.getHandle(), "An unset texture is drawn as the frame");
		var other = helix.graphics.Shader.fromText(gpu, StringTools.replace(text, '"screen"', '"surface"'));
		var refused = false;
		try
			new helix.graphics.ScreenEffect(gpu, other)
		catch (e:Dynamic)
			refused = true;
		check(refused, "A shader of another kind isn't a screen effect");
		// A mirrored model (a negative scale) draws through another pipeline than an ordinary one: its front faces wind the other way.
		var stage3D = new helix.render3d.Stage3D(gpu),
			cube = helix.render3d.Mesh.cube(1, 1, 1),
			material = new helix.render3d.Material();
		var plain = helix.render3d.Node.model(cube, material),
			mirrored = helix.render3d.Node.model(cube, material);
		plain.setPosition(-2, 0, 0);
		mirrored.setPosition(2, 0, 0);
		mirrored.setScale(-1, 1, 1);
		stage3D.add(plain);
		stage3D.add(mirrored);
		var view = new helix.render3d.Camera3D();
		view.setViewport(400, 300);
		gpu.meshPipelines = [];
		stage3D.draw(view);
		check(stage3D.getDrawCount() == 2 && gpu.meshPipelines.length == 2 && gpu.meshPipelines[0] != gpu.meshPipelines[1],
			"A mirrored model is its own run, through another pipeline");
		stage3D.destroy();
		batch.destroy();
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}
}
