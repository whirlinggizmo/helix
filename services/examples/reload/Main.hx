import haxe.io.Bytes;
import helix.platform.Blend;
import helix.platform.IEvents;
import helix.platform.IFileSystem;
import helix.platform.IGraphics;
import helix.platform.IPollable;
import helix.platform.ISystem;
import helix.platform.IWindow;
import helix.services.assets.Assets;
import helix.services.shaders.Shader;
import helix.services.shaders.ShaderUniform;
import helix.services.shaders.ShaderValues;
import helix.services.shaders.Shaders;

/** Draws a quad through a shader compiled into the program, and draws with its file's new program each time the file changes.

	`Shader.compile` with `file` compiles `quad.vert` and `quad.frag` into the program and also writes them to the asset
	`shaders/quad.shader`, under the directory each target's build names (`-D helix-asset-directory=web/assets` in `build-web.hxml`,
	`native/assets` in `build-native.hxml`), so the call is the same on both. `Shaders.watch` replaces the shader in place each time
	the assets hear the file changed. The program then disposes its GPU program (with its pipeline) and builds again, when
	`reloadCount` moves; its values and the `time` handle follow on their own.

	In a page's development build with hotreload-hx, one line tells the assets which served files changed; editing `quad.frag` and
	building again then redraws the running page with it. Natively nothing tells the assets, and the shader stays as compiled:

	```haxe
	reloader.assetsChanged = urls -> for (url in urls) assets.notifyUrlChanged(url);
	```

	Its `time` is the frame's number over 60, so a frame always looks alike; the `frames` option (`HELIX_FRAMES=60` natively,
	`?frames=60` in a page) stops after that many frames. */
class Main {
	static var window:IWindow;
	static var events:IEvents;
	static var graphics:IGraphics;
	static var system:ISystem;
	static var polled:Array<IPollable> = [];
	static var assets:Assets;
	static var shaders:Shaders;
	static var shader:Shader;
	static var values:ShaderValues;
	static var time:ShaderUniform;
	static var program = 0;
	static var pipeline = 0;
	static var builtAt = -1;
	static var vertices:Int;
	static var indices:Int;
	static var texture:Int;
	static var frame = 0;
	static var framesLeft = -1;

	static function main():Void {
		#if js
		window = new helix.platform.adapters.window.dom.DomWindowAdapter({canvasId: "canvas"});
		events = new helix.platform.adapters.events.dom.DomEventsAdapter({canvasId: "canvas"});
		graphics = new helix.platform.adapters.graphics.webgl2.WebGl2GraphicsAdapter({canvasId: "canvas"});
		system = new helix.platform.adapters.system.dom.DomSystemAdapter();
		var httpClient = new helix.platform.adapters.http.fetchapi.FetchApiHttpAdapter();
		var cache:IFileSystem = new helix.platform.adapters.filesystem.browser.BrowserFileSystemAdapter({name: system.getCacheDirectory()});
		polled = [httpClient, cache];
		assets = new Assets({sources: [HttpServer("assets/")], httpClient: httpClient, cacheFileSystem: cache});
		setup();
		var frame:Float->Void = null;
		frame = _ -> if (tick()) js.Browser.window.requestAnimationFrame(frame);
		js.Browser.window.requestAnimationFrame(frame);
		#else
		window = new helix.platform.adapters.window.sdl3.Sdl3WindowAdapter({graphics: Gl});
		graphics = new helix.platform.adapters.graphics.sokol.SokolGraphicsAdapter();
		events = new helix.platform.adapters.events.sdl3.Sdl3EventsAdapter();
		system = new helix.platform.adapters.system.sdl3.Sdl3SystemAdapter();
		var shipped:IFileSystem = new helix.platform.adapters.filesystem.native.NativeFileSystemAdapter({
			directory: system.getProgramDirectory() + "/assets",
			readOnly: true
		});
		polled = [shipped];
		assets = new Assets({sources: [FileSystem(shipped)]});
		setup();
		while (tick()) {}
		#end
	}

	/** Makes the quad, the shader and its values; the program and pipeline are made at the first frame, and again after each change. */
	static function setup():Void {
		var corners = [-.6, -.6, 0, 1, .6, -.6, 1, 1, .6, .6, 1, 0, -.6, .6, 0, 0];
		var bytes = Bytes.alloc(corners.length * 4);
		for (i in 0...corners.length)
			bytes.setFloat(i * 4, corners[i]);
		vertices = graphics.createStaticBuffer(bytes, bytes.length, false);
		var indexBytes = Bytes.alloc(24);
		for (i => index in [0, 1, 2, 0, 2, 3])
			indexBytes.setInt32(i * 4, index);
		indices = graphics.createStaticBuffer(indexBytes, 24, true);
		var white = Bytes.alloc(4);
		white.fill(0, 4, 0xff);
		texture = graphics.createTexture(1, 1, [white]);
		shader = Shader.compile("quad.vert", "quad.frag", {file: "shaders/quad.shader"});
		shaders = new Shaders(assets);
		shaders.watch(shader);
		values = new ShaderValues(shader);
		values.writeVector(shader.getUniform("offsetScale"), 0, 0, 1, 1);
		values.writeColor(shader.getUniform("tint"), 0xff80c0ff);
		values.writeTexture(shader.getSampler("image"), texture);
		time = shader.getUniform("time");
		var frames = system.getOption("frames");
		if (frames != null)
			framesLeft = Std.parseInt(frames);
	}

	/** Builds the shader's program and pipeline on the GPU, freeing the ones before, when the shader has been replaced since. */
	static function build():Void {
		if (builtAt == shader.reloadCount)
			return;
		builtAt = shader.reloadCount;
		if (program != 0)
			graphics.disposeShader(program); // and the pipeline made with it
		program = graphics.createShader(shader.source);
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
		for (p in polled)
			p.poll();
		for (event in events.events)
			switch event {
				case CloseRequested | GraphicsLost:
					return false;
				case _:
			}
		graphics.beginFrame(window.framebufferWidth, window.framebufferHeight, 0xff0a0e18);
		// The frame's start: a file that changed since replaces the shader now, never mid-frame.
		shaders.prepareFrame();
		build();
		values.writeFloat(time, frame++ / 60);
		graphics.draw(pipeline, [vertices], indices, 0, 6, 0, 1, values.textures, values.samplings, values.uniforms);
		graphics.endFrame();
		graphics.present();
		return framesLeft < 0 || --framesLeft > 0;
	}
}
