// helix-render's size ladder (tools/measure_sizes.py): each rung adds one thing to the one before; this one 3D: a cube made in memory, drawn unlit through a camera by the 3D batch, over the 2D.
import helix.geometry.Camera3D;
import helix.geometry.Mesh3D;
import helix.math.Matrix3D;
import helix.platform.adapters.events.dom.DomEventsAdapter;
import helix.platform.adapters.filesystem.browser.BrowserFileSystemAdapter;
import helix.platform.adapters.fontrasterizer.canvas.CanvasFontRasterizerAdapter;
import helix.platform.adapters.graphics.webgl2.WebGl2GraphicsAdapter;
import helix.platform.adapters.http.fetchapi.FetchApiHttpAdapter;
import helix.platform.adapters.imagedecoder.canvas.CanvasImageDecoderAdapter;
import helix.platform.adapters.window.dom.DomWindowAdapter;
import helix.render.Batch2D;
import helix.render.Batch3D;
import helix.render.GpuFont2D;
import helix.render.GpuMesh3D;
import helix.render.Material3D;
import helix.render.Renderer;
import helix.render.TextLayout2D;
import helix.render.TextureRegion2D;
import helix.services.assets.Assets;
import helix.services.fonts.Fonts;
import helix.services.images.Image;
import helix.services.images.Images;

/** A program on helix-render and what it sits on, constructing only what it uses, as a game built on them would. */
@:adds("helix.geometry.Camera3D", "helix.geometry.Frustum3D", "helix.geometry.Mesh3D", "helix.math.Bounds3D", "helix.math.Quaternion3D",
	"helix.math.Transform3D", "helix.math.Trig", "helix.math.Vector3D", "helix.render.Batch3D", "helix.render.Fog3D", "helix.render.GpuMesh3D",
	"helix.render.Material3D", "helix.render.MeshState3D", "helix.render.RenderFill", "helix.render.RenderView", "helix.render.View3D",
	"helix.services.shaders.ShaderBlockValues", "helix.services.shaders.compiled")
class Main {
	static var window:DomWindowAdapter;
	static var events:DomEventsAdapter;
	static var graphics:WebGl2GraphicsAdapter;
	static var renderer:Renderer;
	static var batch:Batch2D;
	static var batch3D:Batch3D;
	static var cube:GpuMesh3D;
	static var material:Material3D;
	static final camera = new Camera3D();
	static final place = new Matrix3D();
	static var sprite:TextureRegion2D;
	static var font:Null<GpuFont2D> = null;
	static var layout:Null<TextLayout2D> = null;

	static function main():Void {
		window = new DomWindowAdapter({canvasId: "canvas"});
		events = new DomEventsAdapter({canvasId: "canvas"});
		graphics = new WebGl2GraphicsAdapter({canvasId: "canvas"});
		renderer = new Renderer(graphics);
		batch = new Batch2D(renderer);
		batch3D = new Batch3D(renderer);
		cube = renderer.createMesh(Mesh3D.fromBox(1, 1, 1));
		material = new Material3D();
		material.shading = Unlit;
		camera.transform.position.set(0, 2, 5);
		camera.transform.lookAt(0, 0, 0);
		sprite = TextureRegion2D.fromTexture(renderer.createTexture(Image.filled(16, 16, 0xffffc040)), 8, 8);
		var httpClient = new FetchApiHttpAdapter();
		var downloads = new BrowserFileSystemAdapter({name: "cache"});
		var assets = new Assets({sources: [HttpServer("assets/")], httpClient: httpClient, cacheFileSystem: downloads});
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
			rasterizer.poll();
			renderer.beginFrame(window.framebufferWidth, window.framebufferHeight, 0xff0a0e18);
			batch3D.begin(camera);
			batch3D.drawMesh(cube, material, Matrix3D.fromRotation(0, 1, 0, turn, place), null, null, 0xffc0e0ff);
			batch3D.end();
			batch.begin();
			batch.drawSprite(sprite, 100, 100, turn += .01);
			batch.drawLine(0, 0, 100, 50, 2, 0xffffffff);
			batch.drawPolyline([0, 0, 50, 20, 80, 0], 3, 0xff80ff80);
			batch.fillRectangle(200, 200, 40, 30, 0xff4080ff);
			batch.strokeRectangle(200, 200, 40, 30, 2, 0xffffffff);
			batch.fillRoundedRectangle(260, 200, 60, 30, 8, 0xc0101828);
			batch.strokeRoundedRectangle(260, 200, 60, 30, 8, 2, 0xff4080c0);
			batch.fillCircle(150, 150, 20, 0xffffd700);
			batch.strokeCircle(150, 150, 24, 2, 0xffffffff);
			batch.fillEllipse(400, 150, 30, 15, 0xffff8040);
			batch.strokeEllipse(400, 150, 34, 19, 2, 0xffffffff);
			batch.fillPolygon([300, 300, 340, 310, 320, 350, 310, 320], 0xff5a4a3a);
			batch.strokePolygon([300, 300, 340, 310, 320, 350, 310, 320], 2, 0xff8a7a6a);
			batch.fillTriangle(500, 300, 540, 300, 520, 340, 0xffff4040);
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
