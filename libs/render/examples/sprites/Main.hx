import helix.render.Batch2D;
import helix.render.DrawList2D;
import helix.render.GpuFont2D;
import helix.render.Renderer;
import helix.render.TextLayout2D;
import helix.render.TextureRegion2D;
import helix.geometry.Camera2D;
import helix.math.Matrix2D;
import helix.platform.IEvents;
import helix.platform.IFileSystem;
import helix.platform.IFontRasterizer;
import helix.platform.IGraphics;
import helix.platform.IImageDecoder;
import helix.platform.IPollable;
import helix.platform.ISystem;
import helix.platform.IWindow;
import helix.platform.Sampling;
import helix.services.assets.Assets;
import helix.services.assets.FileSystemSource;
import helix.services.assets.RevalidateCache;
import helix.services.assets.ServerSource;
import helix.services.fonts.Fonts;
import helix.services.images.Images;
import helix.services.time.Time;
#if js
import helix.platform.IHttp;
#end

/** Shows helix-render's 2D batch: a ship sprite from a sheet, turning about its frames' middle and flipped, under a camera that follows
	it; asteroids drawn as shapes from a white texel on the same sheet, so rocks and ship are one GPU draw; and a panel of wrapped, centered text, recorded once as a draw list, replayed over it all in the screen's pixels. What is off
	screen is culled, as `Batch2D.culling` is on.

	The window, its events and the loop are the platform's, written out as a program does them until the layer above the services does.
	Its motion follows the frame's number, a sixtieth of a second a frame, so a frame always looks alike; `-D sdl_gpu`
	(`build-native-gpu.hxml`) draws with SDL_GPU, and the `frames` option (`HELIX_FRAMES=60` natively, `?frames=60` in a page) stops after
	that many frames. */
class Main {
	static inline final STORY = "The belt is thick tonight. Steer with the arrow keys, keep clear of the rocks, and bring the cargo home before the fuel runs out.";

	static var window:IWindow;
	static var events:IEvents;
	static var graphics:IGraphics;
	static var system:ISystem;
	static var decoder:IImageDecoder;
	static var rasterizer:IFontRasterizer;
	static final polled:Array<IPollable> = [];
	static var time:Time;
	static var renderer:Renderer;
	static var batch:Batch2D;
	static final camera = new Camera2D();
	static var ship:Null<TextureRegion2D> = null;
	static var flame:Null<TextureRegion2D> = null;
	static var font:Null<GpuFont2D> = null;
	static var story:Null<TextLayout2D> = null;
	// The story's panel, recorded once its font is in, replayed each frame at the screen's top left.
	static final panel = new DrawList2D();
	static final panelPlace = Matrix2D.fromTranslation(16, 16);
	// Each rock's x, y, radius and spin.
	static var frame = 0;
	static var framesLeft = -1;
	static final rocks = [
		for (i in 0...12) [Math.cos(i) * 300, Math.sin(i * 1.7) * 200, 12 + i % 4 * 6, i * .3]
	];

	static function main():Void {
		#if js
		window = new helix.platform.adapters.window.dom.DomWindowAdapter({canvasId: "canvas"});
		events = new helix.platform.adapters.events.dom.DomEventsAdapter({canvasId: "canvas"});
		graphics = new helix.platform.adapters.graphics.webgl2.WebGl2GraphicsAdapter({canvasId: "canvas"});
		system = new helix.platform.adapters.system.dom.DomSystemAdapter();
		decoder = new helix.platform.adapters.imagedecoder.canvas.CanvasImageDecoderAdapter();
		rasterizer = new helix.platform.adapters.fontrasterizer.canvas.CanvasFontRasterizerAdapter();
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
		decoder = new helix.platform.adapters.imagedecoder.stb.StbImageDecoderAdapter();
		rasterizer = new helix.platform.adapters.fontrasterizer.stb.StbFontRasterizerAdapter();
		#end
		window.title = "helix-render: sprites, shapes and text";
		setup();
		#if js
		var frame:Float->Void = null;
		frame = _ -> if (tick()) js.Browser.window.requestAnimationFrame(frame) else dispose();
		js.Browser.window.requestAnimationFrame(frame);
		#else
		while (tick()) {}
		dispose();
		#end
	}

	/** Makes the services, the renderer and its batch, and loads the sheet and the font. */
	static function setup():Void {
		var frames = system.getOption("frames");
		if (frames != null)
			framesLeft = Std.parseInt(frames);
		#if js
		var httpClient:IHttp = new helix.platform.adapters.http.fetchapi.FetchApiHttpAdapter();
		var downloads:IFileSystem = new helix.platform.adapters.filesystem.browser.BrowserFileSystemAdapter({name: system.getCacheDirectory()});
		polled.push(httpClient);
		polled.push(downloads);
		var assets = new Assets([
			new ServerSource(system.getProgramDirectory() + "assets/", httpClient, new RevalidateCache(downloads))
		]);
		#else
		var shipped:IFileSystem = new helix.platform.adapters.filesystem.native.NativeFileSystemAdapter({
			directory: haxe.io.Path.join([system.getProgramDirectory(), "../web/assets"]),
			readOnly: true
		});
		polled.push(shipped);
		var assets = new Assets([new FileSystemSource(shipped)]);
		#end
		var images = new Images(decoder, assets);
		var fonts = new Fonts(rasterizer, assets, images);
		time = new Time(system);
		for (p in ([events, decoder, rasterizer, assets, images, time] : Array<IPollable>))
			polled.push(p);

		renderer = new Renderer(graphics);
		batch = new Batch2D(renderer);
		// The sheet, 64 x 34: the ship in its first 32 x 32 cell, its flame in the next, each turned about its middle; its bottom right
		// texel, in the two rows below the frames that no frame reads, made white for the shapes.
		images.load("ship.png", image -> {
			var sheet = renderer.createTexture(image);
			sheet.sampling = Sampling.NEAREST;
			var frames = TextureRegion2D.split(sheet, 32, 32, 0, 0, 2, 16, 16);
			ship = frames[0];
			flame = frames[1];
			batch.shapeRegion = sheet.writeWhiteTexel(sheet.width - 1, sheet.height - 1);
		});
		fonts.load("ui.ttf", 20, [for (c in 32...127) c], loaded -> {
			font = renderer.createFont(loaded);
			story = new TextLayout2D(font, STORY);
			story.maxWidth = 320;
			story.align = Center;
			var padding = 12.;
			panel.makeEmpty();
			panel.fillRoundedRectangle(0, 0, story.maxWidth + padding * 2, story.height + padding * 2, 10, 0xc0101828);
			panel.strokeRoundedRectangle(0, 0, story.maxWidth + padding * 2, story.height + padding * 2, 10, 2, 0xff4080c0);
			panel.drawTextLayout(story, padding, padding, 0xffe0e8f0);
		});
	}

	/** Runs one frame; false once the program should stop. */
	static function tick():Bool {
		for (p in polled)
			p.poll();
		for (event in events.events)
			switch event {
				case CloseRequested | GraphicsLost:
					return false;
				case _:
			}
		var width = window.framebufferWidth, height = window.framebufferHeight;
		var t = frame++ / 60;
		// The ship flies a circle; the camera keeps it in the middle of the screen.
		var shipX = Math.cos(t * .5) * 150, shipY = Math.sin(t * .5) * 150;
		var heading = t * .5 + Math.PI / 2;
		camera.transform.position.set(shipX, shipY);
		camera.offset.set(width / 2, height / 2);

		renderer.beginFrame(width, height, 0xff0b0f1a);
		batch.beginCamera(camera);
		for (rock in rocks) {
			var spin = rock[3] + t;
			var corners = [
				for (k in 0...7) [
					rock[0] + Math.cos(spin + k * .9) * rock[2],
					rock[1] + Math.sin(spin + k * .9) * rock[2] * .8
				]
			];
			batch.fillPolygon([for (c in corners) for (v in c) v], 0xff5a4a3a);
			batch.strokePolygon([for (c in corners) for (v in c) v], 2, 0xff8a7a6a);
		}
		batch.drawLine(-400, 0, 400, 0, 1, 0x40ffffff);
		if (ship != null) {
			// Drawn about its frames' middle; on the circle's far half flipped top to bottom, so it isn't upside down.
			var far = Math.cos(heading) < 0;
			batch.drawSprite(flame, shipX, shipY, heading, 1, 1, 0xffffa040, false, far);
			batch.drawSprite(ship, shipX, shipY, heading, 1, 1, 0xffffffff, false, far);
		}
		batch.end();

		// The panel, in the screen's pixels.
		batch.begin();
		batch.drawList(panel, panelPlace);
		if (font != null) {
			var fps = 'fps ${Math.round(time.fps)}';
			batch.drawText(font, fps, width - font.measureText(fps).x - 16, 16, 0xff80ff80);
		}
		batch.end();
		renderer.endFrame();
		graphics.present();
		return framesLeft < 0 || --framesLeft > 0;
	}

	/** Frees what was made: the renderer frees the sheet and the font's atlas still held. */
	static function dispose():Void {
		renderer.dispose();
		graphics.dispose();
		events.dispose();
		if (window.canClose())
			window.close();
	}
}
