import helix.geometry.Camera3D;
import helix.geometry.Mesh3D;
import helix.math.Matrix3D;
import helix.platform.IEvents;
import helix.platform.IGraphics;
import helix.platform.ISystem;
import helix.platform.IWindow;
import helix.render.Batch3D;
import helix.render.DrawList3D;
import helix.render.GpuMesh3D;
import helix.render.Material3D;
import helix.render.MeshState3D;
import helix.render.Renderer;

/** Shows helix-render's 3D batch unlit: a ring of cubes as one instanced draw, each copy its own color; a large cube tinted for one draw,
	drawn over the ring with `MeshState3D` turning its depth test off; a wide line strip and thin lines; points of one pixel and large ones;
	a circle in a plane; and a grid recorded once as a `DrawList3D`, replayed each frame.

	The window, its events and the loop are the platform's, written out as a program does them until the layer above the services does.
	Its motion follows the frame's number, a sixtieth of a second a frame, so a frame always looks alike; `-D sdl_gpu`
	(`build-native-gpu.hxml`) draws with SDL_GPU, and the `quit_after_frame` option (`--quit_after_frame=60` natively,
	`?quit_after_frame=60` in a page) quits after that frame. */
class Main {
	static var window:IWindow;
	static var events:IEvents;
	static var graphics:IGraphics;
	static var system:ISystem;
	static var renderer:Renderer;
	static var batch:Batch3D;
	static var cube:GpuMesh3D;
	static final camera = new Camera3D();
	static final grid = new DrawList3D();
	static final white = new Material3D();
	static final over = new MeshState3D();
	static final copies = [for (_ in 0...12) new Matrix3D()];
	static final colors = [for (i in 0...12) helix.math.Color.fromHsv(i * 30, .7, 1)];
	static final place = new Matrix3D();
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
		window.title = "helix-render: unlit 3D";
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

	/** Makes the renderer, its batch, the cube, the materials and the grid. */
	static function setup():Void {
		var frames = system.getOption("quit_after_frame");
		if (frames != null)
			framesLeft = Std.parseInt(frames);
		renderer = new Renderer(graphics);
		batch = new Batch3D(renderer);
		cube = renderer.createMesh(Mesh3D.fromBox(1, 1, 1));
		// Unlit, as stored: colors arrive as given.
		white.shading = Unlit;
		white.colorSpace = Srgb;
		white.toneMapped = false;
		over.depthTest = Off;
		grid.drawGrid(21, 1, 0xff304050);
		grid.drawAxes(new Matrix3D(), 2);
		camera.transform.position.set(0, 6, 10);
		camera.transform.lookAt(0, 0, 0);
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
		for (i in 0...copies.length) {
			var a = i * Math.PI * 2 / copies.length + t * .5;
			Matrix3D.fromScale(.6, .6, .6, copies[i]).appendTranslation(Math.cos(a) * 4, .3, Math.sin(a) * 4, copies[i]);
		}
		renderer.beginFrame(window.framebufferWidth, window.framebufferHeight, 0xff101418);
		batch.begin(camera);
		batch.drawList(grid, Matrix3D.fromTranslation(0, 0, 0, place));
		batch.drawMeshInstanced(cube, white, copies, colors);
		// Drawn over the ring, its depth not tested, tinted half grey.
		batch.drawMesh(cube, white, Matrix3D.fromRotation(0, 1, 0, t, place).appendTranslation(0, 1, 0, place), null, null, 0xff808080, over);
		batch.drawLines([-4, 2, -4, 4, 2, -4, 4, 2, 4, -4, 2, 4], 0xffffc040, null, 6, true);
		batch.drawLine(-5, 0, 5, 5, 0, -5, 0xffffffff);
		batch.drawPoints([-3, 3, 0, 0, 3.5, 0, 3, 3, 0], 0xff40ff80);
		batch.pointSize = 12;
		batch.drawPoints([-3, 4, 0, 3, 4, 0], 0xffff4080);
		batch.resetState();
		batch.fillCircle(0, 0, 1.5, 0x8040c0ff, Matrix3D.fromRotation(1, 0, 0, -Math.PI / 2, place).appendTranslation(0, .01, 0, place));
		batch.end();
		renderer.endFrame();
		if (framesLeft == 1)
			Screenshot.save(graphics, system);
		graphics.present();
		return framesLeft < 0 || --framesLeft > 0;
	}

	/** Frees what was made: the renderer frees the cube still held. */
	static function dispose():Void {
		renderer.dispose();
		graphics.dispose();
		events.dispose();
		if (window.canClose())
			window.close();
	}
}
