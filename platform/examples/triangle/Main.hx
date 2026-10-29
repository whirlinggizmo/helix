import haxe.io.Bytes;
import helix.platform.IEvents;
import helix.platform.IGraphics;
import helix.platform.ISystem;
import helix.platform.IWindow;
import helix.platform.tools.ShaderCompiler;

/** Draws one triangle with helix-platform alone: a window, its events, the GPU and the loop, nothing above them.

	Each frame polls the events, starts the screen's pass, draws through one pipeline, ends the pass and presents. The shader is
	`triangle.vert` and `triangle.frag`, compiled while the program builds. Natively it draws with GL, or with SDL_GPU when built with
	`-D sdl_gpu` (`build-native-gpu.hxml`). The `frames` option (`HELIX_FRAMES=60` natively, `?frames=60` in a page) stops after that many
	frames, for a check that runs it unattended. */
class Main {
	static var window:IWindow;
	static var events:IEvents;
	static var graphics:IGraphics;
	static var system:ISystem;
	static var shader:Int;
	static var buffer:Int;
	static var pipeline:Int;
	static var hidden = false;
	static var framesLeft = -1;

	static function main():Void {
		#if js
		window = new helix.platform.adapters.window.dom.DomWindowAdapter({canvasId: "canvas"});
		events = new helix.platform.adapters.events.dom.DomEventsAdapter({canvasId: "canvas"});
		graphics = new helix.platform.adapters.graphics.webgl2.WebGl2GraphicsAdapter({canvasId: "canvas"});
		system = new helix.platform.adapters.system.dom.DomSystemAdapter();
		setup();
		var frame:Float->Void = null;
		frame = _ -> if (tick()) js.Browser.window.requestAnimationFrame(frame) else dispose();
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
		dispose();
		#end
	}

	/** Makes the program, the vertices and the pipeline. */
	static function setup():Void {
		window.title = "helix-platform: a triangle";
		var frames = system.getOption("frames");
		if (frames != null)
			framesLeft = Std.parseInt(frames);
		shader = graphics.createShader(ShaderCompiler.compile("triangle.vert", "triangle.frag"));
		// Three vertices: x, y in clip space, then red, green, blue. 20 bytes each.
		var vertices = Bytes.alloc(60),
			values = [0., .6, 1, 0, 0, -.6, -.6, 0, 1, 0, .6, -.6, 0, 0, 1];
		for (i in 0...values.length)
			vertices.setFloat(i * 4, values[i]);
		buffer = graphics.createStaticBuffer(vertices, 60, false);
		pipeline = graphics.createPipeline({
			shader: shader,
			buffers: [
				{stride: 20, instanced: false, attributes: [{slot: 0, componentCount: 2, offset: 0}, {slot: 1, componentCount: 3, offset: 8}]}
			],
			primitive: Triangles,
			indexed: false,
			blend: Opaque,
			depthTest: Off,
			depthWrite: false,
			cull: None,
			clockwise: false,
			depthOnly: false,
			flip: None
		});
	}

	/** Runs one frame; false once the program should stop. */
	static function tick():Bool {
		if (hidden)
			events.wait(.25);
		events.poll();
		for (event in events.events)
			switch event {
				case Hidden:
					hidden = true;
				case Shown:
					hidden = false;
				case CloseRequested | GraphicsLost:
					return false;
				case _:
			}
		if (hidden)
			return true;
		graphics.beginFrame(window.framebufferWidth, window.framebufferHeight, 0xff0a0e18);
		graphics.draw(pipeline, [buffer], 0, 0, 3, 0, 1, [], [], []);
		graphics.endFrame();
		graphics.present();
		return framesLeft < 0 || --framesLeft > 0;
	}

	/** Frees what was made, in the reverse order, and closes the window where the program owns one. */
	static function dispose():Void {
		graphics.disposePipeline(pipeline);
		graphics.disposeBuffer(buffer);
		graphics.disposeShader(shader);
		graphics.dispose();
		events.dispose();
		if (window.canClose())
			window.close();
	}
}
