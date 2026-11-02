// helix-render's size ladder (tools/measure_sizes.py): each rung adds one thing to the one before; this one sprites: a texture made from an image in memory, drawn turned by the 2D batch.
import helix.platform.adapters.events.dom.DomEventsAdapter;
import helix.platform.adapters.graphics.webgl2.WebGl2GraphicsAdapter;
import helix.platform.adapters.window.dom.DomWindowAdapter;
import helix.render.Batch2D;
import helix.render.Renderer;
import helix.render.TextureRegion2D;
import helix.services.images.Image;

/** A program on helix-render and what it sits on, constructing only what it uses, as a game built on them would. */
@:adds("helix.services.shaders.compiled", "helix.services.images.Image", "helix.math", "helix.geometry")
class Main {
	static var window:DomWindowAdapter;
	static var events:DomEventsAdapter;
	static var graphics:WebGl2GraphicsAdapter;
	static var renderer:Renderer;
	static var batch:Batch2D;
	static var sprite:TextureRegion2D;

	static function main():Void {
		window = new DomWindowAdapter({canvasId: "canvas"});
		events = new DomEventsAdapter({canvasId: "canvas"});
		graphics = new WebGl2GraphicsAdapter({canvasId: "canvas"});
		renderer = new Renderer(graphics);
		batch = new Batch2D(renderer);
		sprite = TextureRegion2D.fromTexture(renderer.createTexture(Image.filled(16, 16, 0xffffc040)), 8, 8);
		var turn = 0.;
		var frame:Float->Void = null;
		frame = _ -> {
			events.poll();
			renderer.beginFrame(window.framebufferWidth, window.framebufferHeight, 0xff0a0e18);
			batch.begin();
			batch.drawSprite(sprite, 100, 100, turn += .01);
			batch.end();
			renderer.endFrame();
			graphics.present();
			js.Browser.window.requestAnimationFrame(frame);
		};
		js.Browser.window.requestAnimationFrame(frame);
	}
}
