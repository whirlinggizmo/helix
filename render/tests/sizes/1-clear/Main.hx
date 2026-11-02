// helix-render's size ladder (tools/measure_sizes.py): each rung adds one thing to the one before; this one the renderer's frame, the screen cleared each frame through it.
import helix.platform.adapters.events.dom.DomEventsAdapter;
import helix.platform.adapters.graphics.webgl2.WebGl2GraphicsAdapter;
import helix.platform.adapters.window.dom.DomWindowAdapter;
import helix.render.Renderer;

/** A program on helix-render and what it sits on, constructing only what it uses, as a game built on them would. */
@:adds("helix.platform", "helix.platform.adapters.events.dom", "helix.platform.adapters.graphics.webgl2", "helix.platform.adapters.window.dom",
	"helix.platform.adapters.shared", "helix.platform.adapters.shared.dom", "helix.render", "helix.services.shaders")
class Main {
	static var window:DomWindowAdapter;
	static var events:DomEventsAdapter;
	static var graphics:WebGl2GraphicsAdapter;
	static var renderer:Renderer;

	static function main():Void {
		window = new DomWindowAdapter({canvasId: "canvas"});
		events = new DomEventsAdapter({canvasId: "canvas"});
		graphics = new WebGl2GraphicsAdapter({canvasId: "canvas"});
		renderer = new Renderer(graphics);
		var frame:Float->Void = null;
		frame = _ -> {
			events.poll();
			renderer.beginFrame(window.framebufferWidth, window.framebufferHeight, 0xff0a0e18);
			renderer.endFrame();
			graphics.present();
			js.Browser.window.requestAnimationFrame(frame);
		};
		js.Browser.window.requestAnimationFrame(frame);
	}
}
