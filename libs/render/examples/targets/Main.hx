import helix.platform.IEvents;
import helix.platform.IGraphics;
import helix.platform.ISystem;
import helix.platform.IWindow;
import helix.render.Batch2D;
import helix.render.RenderTarget2D;
import helix.render.Renderer;

/** Shows helix-render's frame: a render target drawn into, drawn on the screen, then drawn into again in the same frame, so the screen
	shows it as it was at each draw (copy on write): on the left the turning square alone, on the right with a ring over it. Below them,
	a red bar drawn and then cleared away (`Renderer.clearTarget`, recorded in order with the batch open), a strip drawn in a viewport
	of its own, and a disc clipped by a scissor to its left half.

	The window, its events and the loop are the platform's, written out as a program does them until the layer above the services does.
	Its motion follows the frame's number, a sixtieth of a second a frame, so a frame always looks alike; `-D sdl_gpu`
	(`build-native-gpu.hxml`) draws with SDL_GPU, and the `frames` option (`HELIX_FRAMES=60` natively, `?frames=60` in a page) stops after
	that many frames. */
class Main {
	static var window:IWindow;
	static var events:IEvents;
	static var graphics:IGraphics;
	static var system:ISystem;
	static var renderer:Renderer;
	static var batch:Batch2D;
	static var canvas:RenderTarget2D;
	static var frame = 0;
	static var framesLeft = -1;

	static function main():Void {
		#if js
		window = new helix.platform.adapters.window.dom.DomWindowAdapter({canvasId: "canvas"});
		events = new helix.platform.adapters.events.dom.DomEventsAdapter({canvasId: "canvas"});
		graphics = new helix.platform.adapters.graphics.webgl2.WebGl2GraphicsAdapter({canvasId: "canvas"});
		system = new helix.platform.adapters.system.dom.DomSystemAdapter();
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
		#end
		window.title = "helix-render: a frame's passes";
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

	/** Makes the renderer, its batch and the render target. */
	static function setup():Void {
		var frames = system.getOption("frames");
		if (frames != null)
			framesLeft = Std.parseInt(frames);
		renderer = new Renderer(graphics);
		batch = new Batch2D(renderer);
		canvas = renderer.createRenderTarget(160, 160);
	}

	/** Runs one frame; false once the program should stop. */
	static function tick():Bool {
		events.poll();
		for (event in events.events)
			switch event {
				case CloseRequested | GraphicsLost:
					return false;
				case _:
			}
		var t = frame++ / 60;
		renderer.beginFrame(window.framebufferWidth, window.framebufferHeight, 0xff141820);
		// A bar drawn, then cleared away with the batch open: the screen's draws so far are dropped, the clear's color under what follows.
		batch.begin();
		batch.fillRectangle(40, 240, 360, 40, 0xffff0000);
		renderer.clearTarget(0xff202830);
		batch.end();
		// The target, cleared, with a turning square.
		renderer.beginTarget(canvas, 0xff283848);
		batch.begin();
		batch.transform.makeIdentity()
			.appendTranslation(-40, -40, batch.transform)
			.appendRotation(t, batch.transform)
			.appendTranslation(80, 80, batch.transform);
		batch.fillRectangle(0, 0, 80, 80, 0xff40c0ff);
		batch.resetState();
		batch.end();
		renderer.endTarget();
		batch.begin();
		batch.drawTexture(canvas, 40, 40);
		batch.end();
		// Drawn into again after the screen read it: a fresh copy, holding what it held, the ring added.
		renderer.beginTarget(canvas);
		batch.begin();
		batch.strokeCircle(80, 80, 60, 10, 0xffffa040);
		batch.end();
		renderer.endTarget();
		batch.begin();
		batch.drawTexture(canvas, 240, 40);
		batch.end();
		// A strip in a viewport of its own: (0, 0) is the viewport's top left.
		renderer.applyViewport(440, 40, 120, 160);
		batch.begin();
		batch.fillRectangle(0, 0, 120, 160, 0xff60d080);
		batch.end();
		renderer.resetViewport();
		// A disc clipped to its left half.
		batch.begin();
		renderer.applyScissor(40, 300, 100, 200);
		batch.fillCircle(140, 400, 80, 0xffe0e0e0);
		renderer.resetScissor();
		batch.end();
		renderer.endFrame();
		graphics.present();
		return framesLeft < 0 || --framesLeft > 0;
	}

	/** Frees what was made: the renderer frees the target still held. */
	static function dispose():Void {
		renderer.dispose();
		graphics.dispose();
		events.dispose();
		if (window.canClose())
			window.close();
	}
}
