import haxe.io.Bytes;
import helix.platform.Blend;
import helix.platform.IEvents;
import helix.platform.IGraphics;
import helix.platform.ISystem;
import helix.platform.IWindow;
import helix.platform.Sampling;
import helix.services.shaders.Shader;
import helix.services.shaders.ShaderUniform;
import helix.services.shaders.ShaderValues;

/** Draws a textured quad through a shader of its own, with helix-platform and helix-services' shaders alone.

	The shader is `quad.vert` and `quad.frag`, compiled while the program builds. Its values are set by name: the vertex stage's
	`offsetScale` once, the fragment stage's `tint` once and its `time` each frame (its handle found once, the frame's number over 60, so
	a frame always looks alike), and its texture `image`, a 2x2 checker. Each frame hands the values to `IGraphics.draw` as they are. The
	`quit_after_frame` option (`--quit_after_frame=60` natively, `?quit_after_frame=60` in a page) quits after that frame. */
class Main {
	static var window:IWindow;
	static var events:IEvents;
	static var graphics:IGraphics;
	static var system:ISystem;
	static var program:Int;
	static var vertices:Int;
	static var indices:Int;
	static var texture:Int;
	static var pipeline:Int;
	static var values:ShaderValues;
	static var time:ShaderUniform;
	static var frame = 0;
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
		window = new helix.platform.adapters.window.sdl3.Sdl3WindowAdapter({graphics: Gl});
		graphics = new helix.platform.adapters.graphics.sokol.SokolGraphicsAdapter();
		events = new helix.platform.adapters.events.sdl3.Sdl3EventsAdapter();
		system = new helix.platform.adapters.system.sdl3.Sdl3SystemAdapter();
		setup();
		while (tick()) {}
		dispose();
		#end
	}

	/** Makes the program, its values, the quad, the texture and the pipeline. */
	static function setup():Void {
		window.title = "helix-services: a shader's values";
		var frames = system.getOption("quit_after_frame");
		if (frames != null)
			framesLeft = Std.parseInt(frames);
		var shader = Shader.compile("quad.vert", "quad.frag");
		program = graphics.createShader(shader.source);
		// Defaults are values the program makes: values made over them read what they don't write from them.
		var defaults = new ShaderValues(shader);
		defaults.writeVector(shader.getUniform("offsetScale"), 0, 0, 1, 1);
		defaults.writeColor(shader.getUniform("tint"), 0xffffffff);
		values = new ShaderValues(shader, defaults);
		values.writeVector(shader.getUniform("offsetScale"), 0, 0, .6, .6);
		values.writeColor(shader.getUniform("tint"), 0xffffc080);
		// Set each frame through its handle, found once.
		time = shader.getUniform("time");
		// A 2x2 checker, drawn nearest and repeated so the quad shows its texels.
		var checker = Bytes.alloc(16);
		for (i in 0...4)
			checker.setInt32(i * 4, i == 0 || i == 3 ? 0xffffffff : 0xff303030);
		texture = graphics.createTexture(2, 2, [checker]);
		values.writeTexture(shader.getSampler("image"), texture, new Sampling(Nearest, Repeat, Repeat));
		// Four corners: x, y in clip space, then u, v (4 texels across). 16 bytes each.
		var corners = [-1., -1, 0, 4, 1, -1, 4, 4, 1, 1, 4, 0, -1, 1, 0, 0];
		var bytes = Bytes.alloc(corners.length * 4);
		for (i in 0...corners.length)
			bytes.setFloat(i * 4, corners[i]);
		vertices = graphics.createStaticBuffer(bytes, bytes.length, false);
		var order = [0, 1, 2, 0, 2, 3];
		var indexBytes = Bytes.alloc(order.length * 4);
		for (i in 0...order.length)
			indexBytes.setInt32(i * 4, order[i]);
		indices = graphics.createStaticBuffer(indexBytes, indexBytes.length, true);
		// The records' layout from the shader's attributes, not counted by hand: x, y, then u, v.
		pipeline = graphics.createPipeline({
			shader: program,
			buffers: [shader.computeVertexBuffer(["position", "texCoord"])],
			primitive: Triangles,
			indexed: true,
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
		events.poll();
		for (event in events.events)
			switch event {
				case CloseRequested | GraphicsLost:
					return false;
				case _:
			}
		values.writeFloat(time, frame++ / 60);
		graphics.beginFrame(window.framebufferWidth, window.framebufferHeight, 0xff0a0e18);
		graphics.draw(pipeline, [vertices], null, indices, 0, 6, 0, 1, values.textures, values.samplings, values.uniforms);
		graphics.endFrame();
		graphics.present();
		return framesLeft < 0 || --framesLeft > 0;
	}

	/** Frees what was made, in the reverse order, and closes the window where the program owns one. */
	static function dispose():Void {
		graphics.disposePipeline(pipeline);
		graphics.disposeTexture(texture);
		graphics.disposeBuffer(indices);
		graphics.disposeBuffer(vertices);
		graphics.disposeShader(program);
		graphics.dispose();
		events.dispose();
		if (window.canClose())
			window.close();
	}
}
