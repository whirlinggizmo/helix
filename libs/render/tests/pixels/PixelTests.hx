import haxe.io.Bytes;
import helix.geometry.Mesh3D;
import helix.math.Matrix3D;
import helix.platform.IEvents;
import helix.platform.IGraphics;
import helix.platform.ISystem;
import helix.platform.IWindow;
import helix.render.*;
import helix.services.fonts.Font2D;
import helix.services.fonts.Glyph2D;
import helix.services.images.Image;
import helix.services.shaders.ShaderValues;

/** Represents one case: what it draws in a frame into the render target it reads back, and what it expects there. */
typedef PixelCase = {
	/** The case's name, in a failure's message. */
	final name:String;

	/** Draws the frame, between beginFrame and endFrame; returns the target read back. */
	final draw:() -> RenderTarget2D;

	/** Checks the pixels read back. */
	final check:Pixels->Void;
}

/** Checks helix-render's stages 1 and 2 on the GPU: each case draws a frame through the renderer and its batches into a render target, reads it
	back with `IGraphics.readPixels`, and checks its pixels against what the API says they are: 2D colors and a tint multiplied as stored,
	alpha blending as stored, shapes from a white texel, text placed by its ascent, a distance-field font's edge sharp, a program's fragment stage reading `customData`, a
	target copied on write, a clear recorded in order, a viewport and a scissor; in 3D, an unlit mesh multiplied as stored and one tone
	mapped (Neutral), instanced copies tinted, a mesh skinned by its bone texture, points of a pixel and large ones, a wide line, a
	triangle's edges, two views, and a program's material shader; lit materials (Lambert, Phong, MetallicRoughness, emissive) under
	each light kind and an ambient light, their colors computed from three.js's formulas, and a mesh drawn as large points, instanced
	too; and a render target's own sample count, a target with depth drawn
	with one sample and one without depth multisampled where the GPU can.

	Built from the hxml files beside it: in a page it runs on WebGL2, natively on GL, or SDL_GPU with `-D sdl_gpu`. It ends with
	`{passed, checks, failures}` as JSON: printed natively, exiting 1 on a failure, and in a page in `window.helixResult`, null until then.
	Run by `tools/render_checks.py`. */
@:access(helix.services.fonts)
class PixelTests {
	// The targets' size, in texels.
	static inline final SIZE = 64;
	// The skinned crowd's target size, in texels: 20 cells of 16 a side.
	static inline final CROWD_SIZE = 320;
	// How many frames a read back may take before the case fails.
	static inline final READ_FRAMES = 60;

	static var window:IWindow;
	static var events:IEvents;
	static var graphics:IGraphics;
	static var system:ISystem;
	static var renderer:Renderer;
	static var batch:Batch2D;
	static var batch3D:Batch3D;
	static var cases:Array<PixelCase>;
	static var next = 0;
	static var waiting = 0;
	static var checks = 0;
	static final failures:Array<String> = [];
	static var current = "";

	static function main():Void {
		#if js
		js.Syntax.code("window.helixResult = null");
		window = new helix.platform.adapters.window.dom.DomWindowAdapter({canvasId: "canvas"});
		events = new helix.platform.adapters.events.dom.DomEventsAdapter({canvasId: "canvas"});
		graphics = new helix.platform.adapters.graphics.webgl2.WebGl2GraphicsAdapter({canvasId: "canvas"});
		system = new helix.platform.adapters.system.dom.DomSystemAdapter();
		setup();
		var frame:Float->Void = null;
		frame = _ -> if (tick()) js.Browser.window.requestAnimationFrame(frame) else finish();
		js.Browser.window.requestAnimationFrame(frame);
		#else
		#if sdl_gpu
		window = new helix.platform.adapters.window.sdl3.Sdl3WindowAdapter({graphics: Gpu});
		graphics = new helix.platform.adapters.graphics.sdl3gpu.Sdl3GpuGraphicsAdapter();
		#else
		window = new helix.platform.adapters.window.sdl3.Sdl3WindowAdapter({graphics: Gl});
		graphics = new helix.platform.adapters.graphics.sokol.SokolGraphicsAdapter();
		#end
		events = new helix.platform.adapters.events.sdl3.Sdl3EventsAdapter();
		system = new helix.platform.adapters.system.sdl3.Sdl3SystemAdapter();
		setup();
		while (tick()) {}
		finish();
		#end
	}

	/** Runs one frame: the next case, or an empty frame while a read back is awaited. False once every case has been read. */
	static function tick():Bool {
		events.poll();
		for (event in events.events)
			switch event {
				case CloseRequested | GraphicsLost:
					fail('stopped by $event, ${cases.length - next} cases not run');
					return false;
				case _:
			}
		var width = window.framebufferWidth, height = window.framebufferHeight;
		if (waiting > 0) {
			if (++waiting > READ_FRAMES) {
				fail('no read back after $READ_FRAMES frames');
				return false;
			}
			renderer.beginFrame(width, height);
			renderer.endFrame();
			graphics.present();
			return true;
		}
		if (next == cases.length)
			return false;
		var c = cases[next++];
		current = c.name;
		waiting = 1;
		try {
			renderer.beginFrame(width, height, 0xff000000);
			var target = c.draw();
			renderer.endFrame();
			graphics.readPixels(target.handle, (pixels, w, h) -> {
				waiting = 0;
				current = c.name;
				c.check(new Pixels(pixels, w, h));
			}, why -> {
				waiting = 0;
				current = c.name;
				fail('not read back: $why');
			});
		} catch (error:Dynamic) {
			waiting = 0;
			fail('threw: $error');
			return false;
		}
		graphics.present();
		return true;
	}

	/** Records a check's outcome. */
	public static function check(value:Bool, message:String):Void {
		checks++;
		if (!value)
			fail(message);
	}

	static function fail(message:String):Void
		failures.push('$current: $message');

	/** Checks a pixel's color within a tolerance a channel. */
	static function expect(p:Pixels, x:Int, y:Int, color:Int, what:String, tolerance = 3):Void {
		var found = p.get(x, y);
		var ok = true;
		for (shift in [16, 8, 0])
			if (Math.abs((found >> shift & 255) - (color >> shift & 255)) > tolerance)
				ok = false;
		check(ok, '$what: at $x, $y ${StringTools.hex(found & 0xffffff, 6)}, expected ${StringTools.hex(color & 0xffffff, 6)}');
	}

	// A target of the cases' size, depth for 3D, cleared to black at its pass.
	static function target(depth = false):RenderTarget2D
		return renderer.createRenderTarget(SIZE, SIZE, Rgba8, depth ? Buffer : None);

	// A quad mesh in the xy plane, in pixels, its vertices white.
	static function quad(x:Float, y:Float, w:Float, h:Float):Mesh3D {
		var m = new Mesh3D();
		m.positions = [x, y, 0, x + w, y, 0, x + w, y + h, 0, x, y + h, 0];
		m.texCoords = [0, 0, 1, 0, 1, 1, 0, 1];
		m.indices = [0, 1, 2, 0, 2, 3];
		return m;
	}

	// A view in the target's pixels, y down.
	static function screenView():View3D
		return new View3D().setFromScreen(SIZE, SIZE);

	// The color of the crowd's character i, 0xAARRGGBB.
	static function crowdColor(i:Int):Int
		return 0xff000000 | (20 + (i >> 1)) << 16 | (20 + i % 50 * 4) << 8 | 0x80;

	static function unlit(srgb:Bool):Material3D {
		var m = new Material3D();
		m.shading = Unlit;
		m.cull = None;
		if (srgb) {
			m.colorSpace = Srgb;
			m.toneMapped = false;
		}
		return m;
	}

	/** Makes the renderer, its batches and the cases. */
	static function setup():Void {
		window.title = "helix-render: pixel tests";
		renderer = new Renderer(graphics);
		batch = new Batch2D(renderer);
		batch3D = new Batch3D(renderer);
		var grey = renderer.createTexture(Image.filled(4, 4, 0xff808080));
		var sheet = renderer.createTexture(Image.filled(8, 8, 0x00000000));
		var white = sheet.writeWhiteTexel(7, 7);
		var glyphs = [new Glyph2D(65, 0, 0, 4, 8, 1, -8, 6)];
		var font = renderer.createFont(new Font2D(Coverage, 10, 8, -2, 2, Image.filled(8, 8, 0xffffffff), glyphs));
		// An 8 x 8 glyph whose alpha rises across it, column by column, from 16 to 240: as signed distances, its outline (128) halfway.
		var ramp = haxe.io.Bytes.alloc(8 * 8 * 4);
		for (i in 0...64) {
			ramp.fill(i * 4, 3, 255);
			ramp.set(i * 4 + 3, 16 + 32 * (i % 8));
		}
		function rampFont(kind:helix.services.fonts.FontKind)
			return renderer.createFont(new Font2D(kind, 8, 8, 0, 0, new Image("ramp", 8, 8, ramp), [new Glyph2D(65, 0, 0, 8, 8, 0, -8, 8)]));
		var distanceFont = rampFont(Distance),
			coverageFont = rampFont(Coverage);
		var flash = Batch2D.compileShader("flash.frag");
		var flashValues = new ShaderValues(flash);
		flashValues.writeColor(flash.getUniform("extra"), 0xff000040);
		var solid = Material3D.compileShader("solid.frag");
		var plane = renderer.createMesh(quad(8, 8, 48, 48));
		var small = renderer.createMesh(quad(-4, -4, 8, 8));
		var skinnedMesh = quad(8, 8, 16, 16);
		skinnedMesh.jointIndices = [0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0];
		skinnedMesh.weights = [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0];
		var skinned = renderer.createMesh(skinnedMesh);
		// A crowd's character: a 4 x 4 quad, each vertex half the first joint's and half the second's.
		var crowdQuad = quad(0, 0, 4, 4);
		crowdQuad.jointIndices = [for (_ in 0...4) for (j in [0, 1, 0, 0]) j];
		crowdQuad.weights = [for (_ in 0...4) for (w in [.5, .5, 0, 0]) w];
		var crowdMesh = renderer.createMesh(crowdQuad);
		var crowdTarget = renderer.createRenderTarget(CROWD_SIZE, CROWD_SIZE, Rgba8, Buffer);
		var crowdMaterial = unlit(true);
		// Draws count skinned characters, each in a 16 pixel cell, its own pose and its own color: the first joint moves it by a, the
		// second by b, so the quad is moved by half of each.
		function crowd(count:Int, phase:Int):RenderTarget2D {
			renderer.beginTarget(crowdTarget, 0xff000000);
			batch3D.beginViews([new View3D().setFromScreen(CROWD_SIZE, CROWD_SIZE)]);
			for (i in 0...count) {
				var a = 2 * ((i * 3 + phase) % 6),
					b = 2 * ((i * 5 + phase) % 7);
				batch3D.drawMesh(crowdMesh, crowdMaterial, Matrix3D.fromTranslation(i % 20 * 16 + 2, Std.int(i / 20) * 16 + 2, 0),
					[Matrix3D.fromTranslation(a, 0, 0), Matrix3D.fromTranslation(0, b, 0)], null, crowdColor(i));
			}
			batch3D.end();
			renderer.endTarget();
			return crowdTarget;
		}
		function crowdCheck(p:Pixels, count:Int, phase:Int):Void {
			for (i in 0...count) {
				var a = 2 * ((i * 3 + phase) % 6),
					b = 2 * ((i * 5 + phase) % 7);
				var x = i % 20 * 16, y = Std.int(i / 20) * 16;
				expect(p, x + 4 + Std.int(a / 2), y + 4 + Std.int(b / 2), crowdColor(i), 'character $i at its own pose', 4);
				expect(p, x + 1, y + 1, 0x000000, 'character $i not drawn up and left of its pose', 4);
				expect(p, x + 14, y + 14, 0x000000, 'character $i not drawn down and right of its pose', 4);
			}
		}
		var canvas = target(), copied = target(), threeD = target(true);
		var single = renderer.createRenderTarget(SIZE, SIZE, Rgba8, Buffer, 1);
		var multi = renderer.createRenderTarget(SIZE, SIZE, Rgba8, None, 4);
		// A rectangle whose right edge, at 10.6, covers the middle of column 10 but not all of it.
		function edge(t:RenderTarget2D):RenderTarget2D {
			renderer.beginTarget(t, 0xff000000);
			batch.begin();
			batch.fillRectangle(0, 0, 10.6, 64, 0xffffffff);
			batch.end();
			renderer.endTarget();
			return t;
		}
		cases = [
			{
				name: "a target with depth and one sample",
				draw: () -> edge(single),
				check: p -> {
					check(single.msaaSampleCount == 1, 'one sample asked, ${single.msaaSampleCount} given');
					expect(p, 10, 32, 0xffffff, "column 10 covered at its middle, wholly, with no samples between", 0);
					expect(p, 11, 32, 0x000000, "column 11 not at all", 0);
				}
			},
			{
				name: "a target without depth, multisampled where the GPU can",
				draw: () -> edge(multi),
				check: p -> {
					var partial = p.get(10, 32) & 255;
					if (multi.msaaSampleCount > 1)
						check(partial > 20 && partial < 235, 'column 10 partly covered by ${multi.msaaSampleCount} samples: $partial');
					else
						check(partial == 255, 'no multisampling for the format here: column 10 whole, $partial');
					expect(p, 4, 32, 0xffffff, "inside the rectangle");
				}
			},
			{
				name: "2D: a tint and alpha blending as stored",
				draw: () -> {
					renderer.beginTarget(canvas, 0xff0000ff);
					batch.begin();
					batch.drawTexture(grey, 0, 0, 0xff808080);
					batch.fillRectangle(32, 0, 32, 32, 0x80ff0000);
					batch.end();
					renderer.endTarget();
					canvas;
				},
				check: p -> {
					expect(p, 1, 1, 0x404040, "a 0x80 tint on a 0x80 texel");
					expect(p, 48, 16, 0x80007f, "half red over blue");
					expect(p, 16, 48, 0x0000ff, "the clear");
				}
			},
			{
				name: "2D: shapes from a white texel, text, a program's shader",
				draw: () -> {
					renderer.beginTarget(canvas, 0xff000000);
					batch.begin();
					batch.shapeRegion = white;
					batch.fillCircle(16, 16, 12, 0xff00ff00);
					batch.strokeRectangle(36, 4, 24, 24, 4, 0xffffff00);
					batch.shapeRegion = null;
					batch.drawText(font, "A", 0, 40, 0xffff8000);
					batch.shaderValues = flashValues;
					batch.customData = 0xff804000;
					batch.fillRectangle(40, 40, 20, 20, 0xffffffff);
					batch.resetState();
					batch.end();
					renderer.endTarget();
					canvas;
				},
				check: p -> {
					expect(p, 16, 16, 0x00ff00, "the circle's middle");
					expect(p, 16, 2, 0x000000, "past its edge");
					expect(p, 37, 16, 0xffff00, "the outline, centered on the edge");
					expect(p, 48, 16, 0x000000, "inside the outline");
					expect(p, 3, 44, 0xff8000, "the glyph, its top at the ascent below y");
					expect(p, 3, 38, 0x000000, "above it");
					expect(p, 50, 50, 0x804040, "customData read by the program's shader, its uniform added");
				}
			},
			{
				name: "2D: a distance-field font's edge sharp, a coverage font's as stored",
				// Each glyph 32 pixels square, a texel 4: the outline at x 16.
				draw: () -> {
					renderer.beginTarget(canvas, 0xff000000);
					batch.begin();
					batch.drawText(distanceFont, "A", 0, 0, 0xffffffff, 32);
					batch.drawText(coverageFont, "A", 0, 32, 0xffffffff, 32);
					batch.end();
					renderer.endTarget();
					canvas;
				},
				check: p -> {
					expect(p, 13, 16, 0x000000, "outside the outline: none, where the stored alpha is 0.42");
					expect(p, 18, 16, 0xffffff, "inside it: all, where the stored alpha is 0.58");
					expect(p, 13, 48, 0x6c6c6c, "a coverage font's alpha as stored", 8);
					expect(p, 18, 48, 0x949494, "and inside", 8);
				}
			},
			{
				name: "a target drawn into again after a draw read it",
				draw: () -> {
					renderer.beginTarget(canvas, 0xffff0000);
					renderer.endTarget();
					renderer.beginTarget(copied, 0xff000000);
					batch.begin();
					batch.drawTextureRegion(canvas, 0, 0, 64, 64, 0, 0, 32, 64);
					batch.end();
					renderer.endTarget();
					renderer.beginTarget(canvas);
					batch.begin();
					batch.fillRectangle(32, 0, 32, 64, 0xff00ff00);
					batch.end();
					renderer.endTarget();
					renderer.beginTarget(copied);
					batch.begin();
					batch.drawTextureRegion(canvas, 0, 0, 64, 64, 32, 0, 32, 64);
					batch.end();
					renderer.endTarget();
					copied;
				},
				check: p -> {
					expect(p, 24, 32, 0xff0000, "the first draw shows the target as it was");
					expect(p, 40, 32, 0xff0000, "the second its copy's left, kept");
					expect(p, 60, 32, 0x00ff00, "and what was drawn into it after");
				}
			},
			{
				name: "a clear in order, a viewport and a scissor",
				draw: () -> {
					renderer.beginTarget(canvas, 0xff000000);
					batch.begin();
					batch.fillRectangle(0, 0, 64, 64, 0xffff0000);
					renderer.clearTarget(0xff0000ff);
					batch.fillRectangle(0, 0, 8, 8, 0xff00ff00);
					batch.end();
					renderer.applyViewport(32, 32, 32, 32);
					batch.begin();
					batch.fillRectangle(0, 0, 8, 8, 0xffffffff);
					batch.end();
					renderer.resetViewport();
					batch.begin();
					renderer.applyScissor(0, 32, 16, 32);
					batch.fillRectangle(0, 32, 32, 32, 0xffffff00);
					batch.end();
					renderer.endTarget();
					canvas;
				},
				check: p -> {
					expect(p, 4, 4, 0x00ff00, "drawn after the clear");
					expect(p, 20, 4, 0x0000ff, "the clear's color, the draw before it dropped");
					expect(p, 36, 36, 0xffffff, "in the viewport, from its top left");
					expect(p, 44, 44, 0x0000ff, "past the rectangle drawn there");
					expect(p, 8, 48, 0xffff00, "inside the scissor");
					expect(p, 24, 48, 0x0000ff, "outside it");
				}
			},
			{
				name: "3D: unlit meshes, as stored and tone mapped",
				draw: () -> {
					renderer.beginTarget(threeD, 0xff000000);
					batch3D.beginViews([screenView()]);
					var stored = unlit(true);
					stored.baseColor = 0xff808080;
					stored.baseColorTexture = grey;
					batch3D.drawMesh(plane, stored, Matrix3D.fromScale(.5, 1, 1));
					var mapped = unlit(false);
					batch3D.drawMesh(plane, mapped, Matrix3D.fromScale(.5, 1, 1).appendTranslation(32, 0, 0));
					batch3D.end();
					renderer.endTarget();
					threeD;
				},
				check: p -> {
					expect(p, 12, 32, 0x404040, "a 0x80 base color on a 0x80 texel, as stored");
					expect(p, 50, 32, 0xf0f0f0, "white through Neutral tone mapping", 4);
					expect(p, 2, 2, 0x000000, "the clear");
				}
			},
			{
				name: "3D: instanced copies, skinning, a program's material",
				draw: () -> {
					renderer.beginTarget(threeD, 0xff000000);
					batch3D.beginViews([screenView()]);
					batch3D.drawMeshInstanced(small, unlit(true), [Matrix3D.fromTranslation(8, 8, 0), Matrix3D.fromTranslation(24, 8, 0)],
						[0xffff0000, 0xff00ff00]);
					// The second joint moves its corners 32 pixels down.
					batch3D.drawMesh(skinned, unlit(true), Matrix3D.fromTranslation(0, 16, 0), [new Matrix3D(), Matrix3D.fromTranslation(0, 24, 0)]);
					var material = unlit(true);
					material.baseColor = 0xff2040c0;
					material.shaderValues = new ShaderValues(solid);
					batch3D.drawMesh(small, material, Matrix3D.fromTranslation(52, 8, 0));
					batch3D.end();
					renderer.endTarget();
					threeD;
				},
				check: p -> {
					expect(p, 8, 8, 0xff0000, "the first copy, red");
					expect(p, 24, 8, 0x00ff00, "the second, green");
					expect(p, 10, 32, 0xffffff, "the skinned quad's unmoved corner");
					expect(p, 22, 50, 0xffffff, "its corner moved by the second joint's matrix");
					expect(p, 52, 8, 0x2040c0, "the program's material shader");
				}
			},
			{
				name: "3D: 200 skinned characters in one frame, each its own pose",
				draw: () -> crowd(200, 0),
				check: p -> crowdCheck(p, 200, 0)
			},
			{
				name: "3D: 400 skinned characters, more than the frame before held",
				draw: () -> crowd(400, 1),
				check: p -> crowdCheck(p, 400, 1)
			},
			{
				name: "3D: 400 skinned characters again, in new poses",
				draw: () -> crowd(400, 2),
				check: p -> crowdCheck(p, 400, 2)
			},
			{
				name: "3D: points, a wide line, a triangle's edges",
				draw: () -> {
					renderer.beginTarget(threeD, 0xff000000);
					batch3D.beginViews([screenView()]);
					batch3D.drawPoints([4.5, 4.5, 0], 0xffff0000);
					batch3D.pointSize = 8;
					batch3D.drawPoints([16, 16, 0], 0xff00ff00);
					batch3D.resetState();
					batch3D.drawLines([32, 8, 0, 60, 8, 0], 0xff0000ff, null, 6);
					batch3D.polygonMode = Lines;
					batch3D.drawTriangles(null, [8, 32, 0, 56, 32, 0, 32, 60, 0], null, [0xffffffff, 0xffffffff, 0xffffffff]);
					batch3D.resetState();
					batch3D.end();
					renderer.endTarget();
					threeD;
				},
				check: p -> {
					expect(p, 4, 4, 0xff0000, "a one-pixel point, the pixel it falls in");
					expect(p, 5, 5, 0x000000, "and not the next");
					expect(p, 13, 13, 0x00ff00, "an 8-pixel point, 3 from its middle");
					expect(p, 21, 16, 0x000000, "and not 5 from it");
					expect(p, 46, 10, 0x0000ff, "a 6-pixel line, 2 from its middle");
					expect(p, 46, 13, 0x000000, "and not 5 from it");
					expect(p, 32, 40, 0x000000, "a triangle's middle, drawn as its edges");
				}
			},
			{
				name: "3D: two views, each drawn",
				draw: () -> {
					renderer.beginTarget(threeD, 0xff000000);
					var left = new View3D().setFromScreen(32, 64).setViewport(0, 0, 32, 64);
					var right = new View3D().setFromScreen(32, 64).setViewport(32, 0, 32, 64);
					batch3D.beginViews([left, right]);
					batch3D.fillRectangle(4, 4, 8, 8, 0xffffffff);
					batch3D.end();
					renderer.endTarget();
					threeD;
				},
				check: p -> {
					expect(p, 8, 8, 0xffffff, "in the left view");
					expect(p, 40, 8, 0xffffff, "in the right, its own pixels");
					expect(p, 20, 8, 0x000000, "between them");
				}
			}
		];
		litCases(threeD, small);
		// Batch draws tone mapped: a rectangle and a wide line, white through Neutral as the tone-mapped mesh shows it.
		cases.push({
			name: "3D: batch draws tone mapped, narrow and wide",
			draw: () -> {
				renderer.beginTarget(threeD, 0xff000000);
				batch3D.beginViews([screenView()]);
				batch3D.toneMapped = true;
				batch3D.fillRectangle(4, 4, 24, 24, 0xffffffff);
				batch3D.drawLines([32, 16, 0, 60, 16, 0], 0xffffffff, null, 6);
				batch3D.resetState();
				batch3D.fillRectangle(4, 40, 24, 20, 0xffffffff);
				batch3D.end();
				renderer.endTarget();
				threeD;
			},
			check: p -> {
				expect(p, 16, 16, 0xf0f0f0, "a white rectangle through Neutral tone mapping", 4);
				expect(p, 46, 16, 0xf0f0f0, "a wide white line through it", 4);
				expect(p, 16, 50, 0xffffff, "white as stored once toneMapped is off again");
			}
		});
		// Into a target holding linear light, 2D draws are decoded from sRGB: a 0x80 texel is 0.216 there, which a draw of the target into an
		// sRGB one writes as stored, 0x37.
		if (graphics.canRender(Rgba16f)) {
			var linear = renderer.createRenderTarget(SIZE, SIZE, Rgba16f, None, 1);
			cases.push({
				name: "2D: decoded to linear light into an RGBA16F target",
				draw: () -> {
					renderer.beginTarget(linear, 0xff000000);
					batch.begin();
					batch.drawTexture(grey, 0, 0);
					batch.end();
					renderer.endTarget();
					renderer.beginTarget(canvas, 0xff0000ff);
					batch.begin();
					batch.drawTextureRegion(linear, 0, 0, 4, 4, 0, 0, 4, 4);
					batch.end();
					renderer.endTarget();
					canvas;
				},
				check: p -> {
					expect(p, 1, 1, 0x373737, "a 0x80 texel as linear light, drawn back as stored");
				}
			});
		}
	}

	// Linear light encoded as an sRGB byte, clamped, as a target holds it.
	static function encode(linear:Float):Int {
		var c = Math.max(0, Math.min(1, linear));
		return Math.round((c <= .0031308 ? c * 12.92 : 1.055 * Math.pow(c, 1 / 2.4) - .055) * 255);
	}

	// An sRGB byte decoded to linear light.
	static function decode(byte:Int):Float {
		var c = byte / 255;
		return c <= .04045 ? c / 12.92 : Math.pow((c + .055) / 1.055, 2.4);
	}

	// A grey of linear light as a pixel.
	static function grey(linear:Float):Int {
		var e = encode(linear);
		return e << 16 | e << 8 | e;
	}

	// A point or spot light's light reaching a pixel's middle on the plane z 0 facing +z, three.js's: its intensity over the distance
	// squared, times the cosine at the surface, the range's window (pow2(saturate(1 - pow4(d / range)))) and a spot's smoothstep between its
	// cones' cosines along the axis -z.
	static function irradianceAt(x:Int, y:Int, lx:Float, ly:Float, lz:Float, intensity:Float, range = 0., ?cones:Array<Float>):Float {
		var dx = lx - (x + .5), dy = ly - (y + .5), dz = lz;
		var d2 = dx * dx + dy * dy + dz * dz, d = Math.sqrt(d2);
		var falloff = 1 / Math.max(d2, .01);
		if (range > 0) {
			var w = Math.max(0, 1 - Math.pow(d / range, 4));
			falloff *= w * w;
		}
		if (cones != null) {
			var cosInner = Math.cos(cones[0]), cosOuter = Math.cos(cones[1]), angle = dz / d;
			var t = Math.max(0, Math.min(1, (angle - cosOuter) / (cosInner - cosOuter)));
			falloff *= t * t * (3 - 2 * t);
		}
		return intensity * falloff * Math.max(0, dz / d);
	}

	// A directional light's highlight on the plane z 0 facing +z seen along +z, its light arriving from (0, -sin a, cos a): three.js's
	// BRDF_BlinnPhong (Phong) or BRDF_GGX (MetallicRoughness), times the light falling on the surface.
	static function highlight(angle:Float, intensity:Float, f0:Float, phong:Bool, shininess:Float, roughness:Float):Float {
		var nl = Math.cos(angle);
		// The half vector between (0, -sin a, cos a) and (0, 0, 1).
		var hy = -Math.sin(angle),
			hz = Math.cos(angle) + 1,
			hl = Math.sqrt(hy * hy + hz * hz);
		var nh = hz / hl, vh = hz / hl, nv = 1.;
		var fresnel = f0 + (1 - f0) * Math.pow(1 - vh, 5);
		if (phong)
			return intensity * nl * fresnel * .25 * (shininess * .5 + 1) * Math.pow(nh, shininess) / Math.PI;
		var a = roughness * roughness, a2 = a * a;
		var gv = nl * Math.sqrt(a2 + (1 - a2) * nv * nv),
			gl = nv * Math.sqrt(a2 + (1 - a2) * nl * nl);
		var visibility = .5 / (gv + gl);
		var denominator = nh * nh * (a2 - 1) + 1;
		return intensity * nl * fresnel * visibility * a2 / (Math.PI * denominator * denominator);
	}

	// A lit material of a shading and a base color, written as its light is: not tone mapped, both sides drawn.
	static function litMaterial(shading:Shading3D, base:Int):Material3D {
		var m = new Material3D();
		m.shading = shading;
		m.baseColor = base;
		m.cull = None;
		m.toneMapped = false;
		return m;
	}

	// Draws a mesh in a batch of its own, lit by these lights alone.
	static function drawLit(mesh:GpuMesh3D, material:Material3D, x:Float, y:Float, lights:Array<Light3D>):Void {
		batch3D.lights.resize(0);
		for (l in lights)
			batch3D.lights.push(l);
		batch3D.beginViews([screenView()]);
		batch3D.drawMesh(mesh, material, Matrix3D.fromTranslation(x, y, 0));
		batch3D.end();
		batch3D.lights.resize(0);
	}

	/** Adds the cases of lit materials, each light kind, and large points: colors computed from three.js's formulas, each shading
		drawn on the plane z 0 facing the eye in the target's pixels, a quarter of the target a cell. */
	static function litCases(threeD:RenderTarget2D, small:GpuMesh3D):Void {
		// A quad turned to face the eye: under a view whose y runs down, its corners wound the other way.
		var facing = quad(0, 0, 32, 32);
		facing.indices = [0, 2, 1, 0, 3, 2];
		var cell = renderer.createMesh(facing);
		var corners = renderer.createMesh(quad(16, 16, 32, 32));
		// A directional light of π shining along a direction.
		function directional(x:Float, y:Float, z:Float):DirectionalLight3D {
			var l = new DirectionalLight3D();
			l.direction.set(x, y, z);
			return l;
		}
		cases.push({
			name: "3D lit: Lambert under a directional, an ambient and a hemisphere light",
			draw: () -> {
				renderer.beginTarget(threeD, 0xff000000);
				drawLit(cell, litMaterial(Lambert, 0xff808080), 0, 0, [directional(0, 0, -1)]);
				// Arriving 60 degrees from the normal: half the light.
				drawLit(cell, litMaterial(Lambert, 0xffffffff), 32, 0, [directional(0, Math.sin(Math.PI / 3), -Math.cos(Math.PI / 3))]);
				batch3D.environment = new Environment3D();
				batch3D.environment.setAmbient(0xff808080, Math.PI);
				drawLit(cell, litMaterial(Lambert, 0xffffffff), 0, 32, []);
				batch3D.environment = new Environment3D();
				// The sky along x, the surface facing z: halfway between the sky and the black ground.
				var hemisphere = new HemisphereLight3D();
				hemisphere.groundColor = 0xff000000;
				hemisphere.up.set(1, 0, 0);
				drawLit(cell, litMaterial(Lambert, 0xffffffff), 32, 32, [hemisphere]);
				renderer.endTarget();
				threeD;
			},
			check: p -> {
				expect(p, 16, 16, 0x808080, "a directional light of π facing the surface: its base color");
				expect(p, 48, 16, grey(.5), "at 60 degrees: half");
				expect(p, 16, 48, 0x808080, "an ambient light of π, 0x808080: its color on white");
				expect(p, 48, 48, grey(.5), "a hemisphere light across the surface: half its sky");
			}
		});
		cases.push({
			name: "3D lit: point and spot lights, falling off and in cones as three.js's",
			draw: () -> {
				renderer.beginTarget(threeD, 0xff000000);
				var point = new PointLight3D();
				point.position.set(16, 16, 4);
				point.intensity = 16 * Math.PI;
				drawLit(cell, litMaterial(Lambert, 0xffffffff), 0, 0, [point]);
				var ranged = new PointLight3D();
				ranged.position.set(48, 16, 2);
				ranged.intensity = 4 * Math.PI;
				ranged.range = 6;
				drawLit(cell, litMaterial(Lambert, 0xffffffff), 32, 0, [ranged]);
				var spot = new SpotLight3D();
				spot.position.set(32, 48, 6);
				spot.direction.set(0, 0, -1);
				spot.setCone(.3, .6);
				spot.intensity = 36 * Math.PI;
				drawLit(cell, litMaterial(Lambert, 0xffffffff), 0, 32, [spot]);
				drawLit(cell, litMaterial(Lambert, 0xffffffff), 32, 32, [spot]);
				renderer.endTarget();
				threeD;
			},
			check: p -> {
				inline function lambert(x:Int, y:Int, e:Float)
					expect(p, x, y, grey(e / Math.PI), 'diffuse light ${e / Math.PI}');
				lambert(16, 16, irradianceAt(16, 16, 16, 16, 4, 16 * Math.PI));
				lambert(22, 16, irradianceAt(22, 16, 16, 16, 4, 16 * Math.PI));
				lambert(26, 26, irradianceAt(26, 26, 16, 16, 4, 16 * Math.PI));
				lambert(48, 16, irradianceAt(48, 16, 48, 16, 2, 4 * Math.PI, 6));
				lambert(51, 16, irradianceAt(51, 16, 48, 16, 2, 4 * Math.PI, 6));
				expect(p, 55, 16, 0x000000, "past the range");
				lambert(31, 48, irradianceAt(31, 48, 32, 48, 6, 36 * Math.PI, 0, [.3, .6]));
				lambert(34, 48, irradianceAt(34, 48, 32, 48, 6, 36 * Math.PI, 0, [.3, .6]));
				lambert(35, 49, irradianceAt(35, 49, 32, 48, 6, 36 * Math.PI, 0, [.3, .6]));
				expect(p, 37, 48, 0x000000, "past the spot's outer cone");
			}
		});
		var angle = Math.PI / 6;
		cases.push({
			name: "3D lit: Phong's highlight, MetallicRoughness's dielectric and metal, emissive light",
			draw: () -> {
				renderer.beginTarget(threeD, 0xff000000);
				var sun = directional(0, Math.sin(angle), -Math.cos(angle));
				var phong = litMaterial(Phong, 0xff202020);
				phong.specularColor = 0xff404040;
				drawLit(cell, phong, 0, 0, [sun]);
				var dielectric = litMaterial(MetallicRoughness, 0xff404040);
				dielectric.roughness = .5;
				drawLit(cell, dielectric, 32, 0, [sun]);
				var metal = litMaterial(MetallicRoughness, 0xff808080);
				metal.metallic = 1;
				metal.roughness = .6;
				drawLit(cell, metal, 0, 32, [sun]);
				var glowing = litMaterial(MetallicRoughness, 0xffffffff);
				glowing.emissiveColor = 0xff404040;
				glowing.emissiveStrength = 2;
				drawLit(cell, glowing, 32, 32, []);
				renderer.endTarget();
				threeD;
			},
			check: p -> {
				var cosine = Math.cos(angle);
				var spec = decode(0x40), base = decode(0x20);
				expect(p, 16, 16, grey(Math.PI * cosine * base / Math.PI + highlight(angle, Math.PI, spec, true, 30, 0)),
					"Phong: diffuse and Blinn-Phong's highlight");
				expect(p, 48, 16, grey(cosine * decode(0x40) + highlight(angle, Math.PI, .04, false, 0, .5)),
					"a dielectric: diffuse and GGX's highlight of 0.04");
				expect(p, 16, 48, grey(highlight(angle, Math.PI, decode(0x80), false, 0, .6)), "a metal: GGX's highlight of its color, no diffuse");
				expect(p, 48, 48, grey(decode(0x40) * 2), "unlit but for its emissive light, its strength 2");
			}
		});
		cases.push({
			name: "3D: a mesh drawn as large points, and instanced copies",
			draw: () -> {
				renderer.beginTarget(threeD, 0xff000000);
				batch3D.beginViews([screenView()]);
				batch3D.polygonMode = Points;
				batch3D.pointSize = 6;
				batch3D.drawMesh(corners, unlit(true), new Matrix3D());
				batch3D.pointSize = 4;
				batch3D.drawMeshInstanced(small, unlit(true), [Matrix3D.fromTranslation(8, 56, 0), Matrix3D.fromTranslation(40, 56, 0)],
					[0xffff0000, 0xff00ff00]);
				batch3D.resetState();
				batch3D.end();
				renderer.endTarget();
				threeD;
			},
			check: p -> {
				expect(p, 18, 18, 0xffffff, "a corner's point, 2 from its middle");
				expect(p, 46, 46, 0xffffff, "the opposite corner's");
				expect(p, 21, 16, 0x000000, "and not 5 from it");
				expect(p, 32, 32, 0x000000, "the quad's middle, drawn as its corners");
				expect(p, 5, 53, 0xff0000, "the first copy's corner, red");
				expect(p, 37, 53, 0x00ff00, "the second's, green");
			}
		});
	}

	/** Frees what was made, says how it went and closes the window where the program owns one. */
	static function finish():Void {
		// A case that threw leaves its frame open; what was made is then left to the process's end.
		if (!renderer.inFrame)
			renderer.dispose();
		graphics.dispose();
		events.dispose();
		var result = {passed: failures.length == 0, checks: checks, failures: failures};
		#if js
		js.Syntax.code("window.helixResult = {0}", result);
		#else
		Sys.println(haxe.Json.stringify(result));
		if (window.canClose())
			window.close();
		Sys.exit(result.passed ? 0 : 1);
		#end
	}
}

/** Represents pixels read back: RGBA8, rows top first. */
class Pixels {
	/** The bytes. */
	public final bytes:Bytes;

	/** The width, in pixels. */
	public final width:Int;

	/** The height, in pixels. */
	public final height:Int;

	/** Creates them. */
	public function new(bytes:Bytes, width:Int, height:Int) {
		this.bytes = bytes;
		this.width = width;
		this.height = height;
	}

	/** Returns a pixel as 0xAARRGGBB. */
	public function get(x:Int, y:Int):Int {
		var at = (y * width + x) * 4;
		return bytes.get(at + 3) << 24 | bytes.get(at) << 16 | bytes.get(at + 1) << 8 | bytes.get(at + 2);
	}
}
