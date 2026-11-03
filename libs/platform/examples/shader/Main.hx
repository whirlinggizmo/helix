import helix.platform.Blend;
import haxe.io.Bytes;
import helix.platform.IEvents;
import helix.platform.IGraphics;
import helix.platform.ISystem;
import helix.platform.IWindow;
import helix.platform.Sampling;
import helix.platform.tools.ShaderCompiler;

/** Draws a checkered square through a compiled shader with helix-platform alone: a texture, and uniforms set each frame.

	The shader is `shader.vert` and `shader.frag`, compiled while the program builds. The texture is 2 x 2 texels made here, repeated
	across the square by the shader and sampled nearest. Each frame the vertex stage's block moves the square from side to side and the
	fragment stage's block darkens and brightens it, both from the frame's number. Natively it draws with GL, or with SDL_GPU when built
	with `-D sdl_gpu` (`build-native-gpu.hxml`). The `frames` option (`--frames=60` natively, `?frames=60` in a page) stops after
	that many frames, for a check that runs it unattended. */
class Main {
	static var window:IWindow;
	static var events:IEvents;
	static var graphics:IGraphics;
	static var system:ISystem;
	static var shader:Int;
	static var buffer:Int;
	static var texture:Int;
	static var pipeline:Int;
	static var hidden = false;
	static var framesLeft = -1;
	static var frame = 0;
	// The uniform blocks' bytes, rewritten each frame: the vertex stage's offset, the fragment stage's tint.
	static var place = Bytes.alloc(16);
	static var shade = Bytes.alloc(16);

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

	/** Makes the program, the texture, the vertices and the pipeline. */
	static function setup():Void {
		window.title = "helix-platform: a shader";
		place.fill(0, 16, 0);
		var frames = system.getOption("frames");
		if (frames != null)
			framesLeft = Std.parseInt(frames);
		shader = graphics.createShader(ShaderCompiler.compile("shader.vert", "shader.frag"));
		// Two colors in a 2 x 2 checker, RGBA8, rows top first.
		var cream = [240, 220, 180, 255], teal = [40, 120, 140, 255];
		var texels = Bytes.alloc(16);
		for (i => rgba in [cream, teal, teal, cream])
			for (c in 0...4)
				texels.set(i * 4 + c, rgba[c]);
		texture = graphics.createTexture(2, 2, [texels]);
		// A square half the height of the window as two triangles: x, y in clip space, then u, v (v down, as the texture's rows run).
		var values = [
			-.5, -.5, 0, 1, .5, -.5, 1, 1,  .5, .5, 1, 0,
			-.5, -.5, 0, 1, .5,  .5, 1, 0, -.5, .5, 0, 0
		];
		var vertices = Bytes.alloc(values.length * 4);
		for (i in 0...values.length)
			vertices.setFloat(i * 4, values[i]);
		buffer = graphics.createStaticBuffer(vertices, vertices.length, false);
		pipeline = graphics.createPipeline({
			shader: shader,
			buffers: [
				{stride: 16, instanced: false, attributes: [{slot: 0, format: Float2, offset: 0}, {slot: 1, format: Float2, offset: 8}]}
			],
			primitive: Triangles,
			indexed: false,
			blend: Blend.OPAQUE,
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
		// The uniforms: the square a quarter of the way to either side at most, its brightness between a half and the texture's own. Blocks
		// are numbered by stage: the vertex stage's place at 0, the fragment stage's shade at 4 + 1.
		place.setFloat(0, .25 * Math.sin(frame * .05));
		var brightness = .75 + .25 * Math.cos(frame * .08);
		for (i in 0...3)
			shade.setFloat(i * 4, brightness);
		shade.setFloat(12, 1);
		graphics.beginFrame(window.framebufferWidth, window.framebufferHeight, 0xff0a0e18);
		graphics.draw(pipeline, [buffer], 0, 0, 6, 0, 1, [texture], [new Sampling(Nearest, Repeat, Repeat)], [place, null, null, null, null, shade]);
		graphics.endFrame();
		graphics.present();
		frame++;
		return framesLeft < 0 || --framesLeft > 0;
	}

	/** Frees what was made, in the reverse order, and closes the window where the program owns one. */
	static function dispose():Void {
		graphics.disposePipeline(pipeline);
		graphics.disposeBuffer(buffer);
		graphics.disposeTexture(texture);
		graphics.disposeShader(shader);
		graphics.dispose();
		events.dispose();
		if (window.canClose())
			window.close();
	}
}
