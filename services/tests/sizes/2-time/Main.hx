// The services' size ladder (tools/measure_sizes.py): each rung adds one thing to the one before; this one the game's time and a timer.
import helix.platform.adapters.events.dom.DomEventsAdapter;
import helix.platform.adapters.graphics.webgl2.WebGl2GraphicsAdapter;
import helix.platform.adapters.system.dom.DomSystemAdapter;
import helix.platform.adapters.window.dom.DomWindowAdapter;
import helix.services.time.Time;

/** A program on helix-services and what it sits on, constructing only what it uses, as a game built on them would. */
class Main {
	static var window:DomWindowAdapter;
	static var events:DomEventsAdapter;
	static var graphics:WebGl2GraphicsAdapter;
	static var system:DomSystemAdapter;
	static var time:Time;

	static function main():Void {
		window = new DomWindowAdapter({canvasId: "canvas"});
		events = new DomEventsAdapter({canvasId: "canvas"});
		graphics = new WebGl2GraphicsAdapter({canvasId: "canvas"});
		system = new DomSystemAdapter();
		time = new Time(system);
		time.every(1, () -> trace(time.elapsed));
		var frame:Float->Void = null;
		frame = _ -> {
			events.poll();
			time.poll();
			graphics.beginFrame(window.framebufferWidth, window.framebufferHeight, 0xff0a0e18);
			graphics.endFrame();
			graphics.present();
			js.Browser.window.requestAnimationFrame(frame);
		};
		js.Browser.window.requestAnimationFrame(frame);
	}
}
