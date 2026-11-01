// The platform's size ladder (tools/measure_sizes.py): each rung adds one thing to the one before; this one a triangle drawn: a compiled shader, a buffer and a pipeline.
import helix.platform.Blend;
import haxe.io.Bytes;
import helix.platform.tools.ShaderCompiler;
import helix.platform.adapters.events.dom.DomEventsAdapter;
import helix.platform.adapters.graphics.webgl2.WebGl2GraphicsAdapter;
import helix.platform.adapters.window.dom.DomWindowAdapter;

/** A program on helix-platform alone, constructing only what it uses, as a game built on the platform would. */
class Main {
	static var window:DomWindowAdapter;
	static var events:DomEventsAdapter;
	static var graphics:WebGl2GraphicsAdapter;
	static var pipeline:Int;
	static var buffer:Int;

	static function main():Void {
		window = new DomWindowAdapter({canvasId: "canvas"});
		events = new DomEventsAdapter({canvasId: "canvas"});
		graphics = new WebGl2GraphicsAdapter({canvasId: "canvas"});
		var vertices = Bytes.alloc(60),
			values = [0., .6, 1, 0, 0, -.6, -.6, 0, 1, 0, .6, -.6, 0, 0, 1];
		for (i in 0...values.length)
			vertices.setFloat(i * 4, values[i]);
		buffer = graphics.createStaticBuffer(vertices, 60, false);
		pipeline = graphics.createPipeline({
			shader: graphics.createShader(ShaderCompiler.compile("../triangle.vert", "../triangle.frag")),
			buffers: [
				{stride: 20, instanced: false, attributes: [{slot: 0, componentCount: 2, offset: 0}, {slot: 1, componentCount: 3, offset: 8}]}
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
		var frame:Float->Void = null;
		frame = _ -> {
			events.poll();
			graphics.beginFrame(window.framebufferWidth, window.framebufferHeight, 0xff0a0e18);
			graphics.draw(pipeline, [buffer], 0, 0, 3, 0, 1, [], [], []);
			graphics.endFrame();
			graphics.present();
			js.Browser.window.requestAnimationFrame(frame);
		};
		js.Browser.window.requestAnimationFrame(frame);
	}
}
