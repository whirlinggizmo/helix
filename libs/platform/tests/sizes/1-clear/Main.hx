// The platform's size ladder (tools/gen_sizes.py): each rung adds one thing to the one before; this one a window cleared each frame: the window, its events and the GPU.
import haxe.io.Bytes;
import helix.platform.adapters.events.dom.DomEventsAdapter;
import helix.platform.adapters.graphics.webgl2.WebGl2GraphicsAdapter;
import helix.platform.adapters.window.dom.DomWindowAdapter;

/** A program on helix-platform alone, constructing only what it uses, as a game built on the platform would. */
@:adds("helix.platform", "helix.platform.adapters.events.dom", "helix.platform.adapters.graphics.webgl2", "helix.platform.adapters.window.dom",
	"helix.platform.adapters.shared", "helix.platform.adapters.shared.dom")
class Main {
	static var window:DomWindowAdapter;
	static var events:DomEventsAdapter;
	static var graphics:WebGl2GraphicsAdapter;

	static function main():Void {
		window = new DomWindowAdapter({canvasId: "canvas"});
		events = new DomEventsAdapter({canvasId: "canvas"});
		graphics = new WebGl2GraphicsAdapter({canvasId: "canvas"});
		var frame:Float->Void = null;
		frame = _ -> {
			events.poll();
			graphics.beginFrame(window.framebufferWidth, window.framebufferHeight, 0xff0a0e18);
			graphics.endFrame();
			graphics.present();
			js.Browser.window.requestAnimationFrame(frame);
		};
		js.Browser.window.requestAnimationFrame(frame);
	}
}
