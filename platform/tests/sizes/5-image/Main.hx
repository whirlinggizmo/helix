// The platform's size ladder (tools/measure_sizes.py): each rung adds one thing to the one before; this one an image downloaded and decoded into a texture.
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import helix.platform.tools.ShaderCompiler;
import helix.platform.adapters.audio.webaudio.WebAudioAdapter;
import helix.platform.adapters.audiodecoder.webaudio.WebAudioDecoderAdapter;
import helix.platform.adapters.events.dom.DomEventsAdapter;
import helix.platform.adapters.graphics.webgl2.WebGl2GraphicsAdapter;
import helix.platform.adapters.http.fetchapi.FetchApiHttpAdapter;
import helix.platform.adapters.imagedecoder.canvas.CanvasImageDecoderAdapter;
import helix.platform.adapters.window.dom.DomWindowAdapter;

/** A program on helix-platform alone, constructing only what it uses, as a game built on the platform would. */
class Main {
	static var window:DomWindowAdapter;
	static var events:DomEventsAdapter;
	static var graphics:WebGl2GraphicsAdapter;
	static var pipeline:Int;
	static var buffer:Int;
	static var http:FetchApiHttpAdapter;
	static var audio:WebAudioAdapter;
	static var sounds:WebAudioDecoderAdapter;
	static var images:CanvasImageDecoderAdapter;
	static var texture = -1;

	static function main():Void {
		var canvas:js.html.CanvasElement = cast js.Browser.document.getElementById("canvas");
		window = new DomWindowAdapter(canvas);
		events = new DomEventsAdapter(canvas);
		graphics = new WebGl2GraphicsAdapter(canvas, false, 1);
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
			blend: Opaque,
			depthTest: Off,
			depthWrite: false,
			cull: None,
			clockwise: false,
			depthOnly: false,
			flip: None
		});
		http = new FetchApiHttpAdapter();
		audio = new WebAudioAdapter();
		sounds = new WebAudioDecoderAdapter();
		download("jump.wav", bytes -> sounds.decode(bytes, samples -> audio.playClip(audio.createClip(samples), false, 1), why -> trace(why)));
		images = new CanvasImageDecoderAdapter();
		download("logo.png",
			bytes -> images.decode(bytes, (pixels, width, height) -> texture = graphics.createTexture(width, height, [pixels]), why -> trace(why)));
		var frame:Float->Void = null;
		frame = _ -> {
			events.poll();
			http.poll();
			sounds.poll();
			audio.poll();
			images.poll();
			graphics.beginFrame(window.framebufferWidth, window.framebufferHeight, 0xff0a0e18);
			graphics.draw(pipeline, [buffer], 0, 0, 3, 0, 1, [], [], []);
			graphics.endFrame();
			graphics.present();
			js.Browser.window.requestAnimationFrame(frame);
		};
		js.Browser.window.requestAnimationFrame(frame);
	}

	/** Downloads a whole file, then hands it to `loaded`. */
	static function download(url:String, loaded:Bytes->Void):Void {
		var parts = new BytesBuffer();
		http.get(url, false, new Map(), (status, headers) -> {}, part -> parts.add(part), () -> loaded(parts.getBytes()), why -> trace(why));
	}
}
