// helix-render's size ladder (tools/gen_sizes.py): each rung adds one thing to the one before; this one text: a TrueType font loaded from beside the page, rasterized by the page's canvas, measured and drawn, and wrapped in a layout.
import helix.platform.adapters.events.dom.DomEventsAdapter;
import helix.platform.adapters.filesystem.browser.BrowserFileSystemAdapter;
import helix.platform.adapters.fontrasterizer.canvas.CanvasFontRasterizerAdapter;
import helix.platform.adapters.graphics.webgl2.WebGl2GraphicsAdapter;
import helix.platform.adapters.http.fetchapi.FetchApiHttpAdapter;
import helix.platform.adapters.imagedecoder.canvas.CanvasImageDecoderAdapter;
import helix.platform.adapters.window.dom.DomWindowAdapter;
import helix.render.Batch2D;
import helix.render.GpuFont2D;
import helix.render.Renderer;
import helix.render.TextLayout2D;
import helix.render.TextureRegion2D;
import helix.services.assets.Assets;
import helix.services.assets.RevalidateCache;
import helix.services.assets.ServerSource;
import helix.services.fonts.Fonts;
import helix.services.images.Image;
import helix.services.images.Images;

/** A program on helix-render and what it sits on, constructing only what it uses, as a game built on them would. */
@:adds("helix.platform.adapters.http.fetchapi", "helix.platform.adapters.filesystem.browser", "helix.platform.adapters.fontrasterizer.canvas",
	"helix.platform.adapters.imagedecoder.canvas", "helix.formats.text", "helix.formats.truetype.TrueTypeTables", "helix.log.Log", "helix.math.RectPacker2D",
	"helix.math.Vector2D", "helix.render.GpuFont2D", "helix.render.TextLayout2D", "helix.services.assets.AssetCache", "helix.services.assets.AssetRequest",
	"helix.services.assets.AssetSource", "helix.services.assets.Assets", "helix.services.assets.CacheDecision", "helix.services.assets.KeptCopies",
	"helix.services.assets.RevalidateCache", "helix.services.assets.ServerSource", "helix.services.fonts.Font2D", "helix.services.fonts.Fonts",
	"helix.services.fonts.FontsOptions", "helix.services.fonts.Glyph2D", "helix.services.images.Images")
class Main {
	static var window:DomWindowAdapter;
	static var events:DomEventsAdapter;
	static var graphics:WebGl2GraphicsAdapter;
	static var renderer:Renderer;
	static var batch:Batch2D;
	static var sprite:TextureRegion2D;
	static var font:Null<GpuFont2D> = null;
	static var layout:Null<TextLayout2D> = null;

	static function main():Void {
		window = new DomWindowAdapter({canvasId: "canvas"});
		events = new DomEventsAdapter({canvasId: "canvas"});
		graphics = new WebGl2GraphicsAdapter({canvasId: "canvas"});
		renderer = new Renderer(graphics);
		batch = new Batch2D(renderer);
		sprite = TextureRegion2D.fromTexture(renderer.createTexture(Image.filled(16, 16, 0xffffc040)), 8, 8);
		var httpClient = new FetchApiHttpAdapter();
		var downloads = new BrowserFileSystemAdapter({name: "cache"});
		var assets = new Assets([new ServerSource("assets/", httpClient, new RevalidateCache(downloads))]);
		var decoder = new CanvasImageDecoderAdapter();
		var rasterizer = new CanvasFontRasterizerAdapter();
		var fonts = new Fonts(rasterizer, assets, new Images(decoder, assets));
		fonts.load("ui.ttf", 20, [for (c in 32...127) c], loaded -> {
			font = renderer.createFont(loaded);
			layout = new TextLayout2D(font, "A paragraph, wrapped and centered.");
			layout.maxWidth = 200;
			layout.align = Center;
		});
		var turn = 0.;
		var frame:Float->Void = null;
		frame = _ -> {
			events.poll();
			httpClient.poll();
			downloads.poll();
			assets.poll();
			rasterizer.poll();
			renderer.beginFrame(window.framebufferWidth, window.framebufferHeight, 0xff0a0e18);
			batch.begin();
			batch.drawSprite(sprite, 100, 100, turn += .01);
			if (font != null) {
				batch.drawText(font, "Score", 8, 8);
				batch.drawText(font, "fps", 300 - font.measureText("fps").x, 8);
				batch.drawTextLayout(layout, 8, 40);
			}
			batch.end();
			renderer.endFrame();
			graphics.present();
			js.Browser.window.requestAnimationFrame(frame);
		};
		js.Browser.window.requestAnimationFrame(frame);
	}
}
