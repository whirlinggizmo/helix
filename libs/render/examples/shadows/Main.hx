import helix.geometry.Camera3D;
import helix.geometry.Mesh3D;
import helix.math.Matrix3D;
import helix.platform.IEvents;
import helix.platform.IGraphics;
import helix.platform.ISystem;
import helix.platform.IWindow;
import helix.render.Batch3D;
import helix.render.DirectionalLight3D;
import helix.render.GpuMesh3D;
import helix.render.Material3D;
import helix.render.Renderer;
import helix.render.SpotLight3D;

/** Shows helix-render's shadows: a turning box and a still pillar over a plane, under a sun casting through two cascades and a spot
	light casting its own, softer and tinted blue, beside them.

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
	static var ground:GpuMesh3D;
	static var box:GpuMesh3D;
	static var pillar:GpuMesh3D;
	static final camera = new Camera3D();
	static final floor = new Material3D();
	static final crate = new Material3D();
	static final stone = new Material3D();
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
		window.title = "helix-render: shadows";
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

	/** Makes the renderer, its batch, the meshes, the materials and the lights. */
	static function setup():Void {
		var frames = system.getOption("quit_after_frame");
		if (frames != null)
			framesLeft = Std.parseInt(frames);
		renderer = new Renderer(graphics);
		batch = new Batch3D(renderer);
		ground = renderer.createMesh(Mesh3D.fromPlane(14, 10, 1, 1));
		box = renderer.createMesh(Mesh3D.fromBox(1.2, 1.2, 1.2));
		pillar = renderer.createMesh(Mesh3D.fromBox(.5, 2.4, .5));
		floor.shading = Lambert;
		floor.baseColor = 0xffc8c8c0;
		crate.baseColor = 0xffc07030;
		crate.roughness = .6;
		stone.baseColor = 0xff8090a0;
		stone.roughness = .8;
		var sun = new DirectionalLight3D();
		sun.direction.set(1, -2, -.4);
		sun.intensity = 2.5;
		sun.castsShadow = true;
		sun.shadow.distance = 20;
		sun.shadow.cascadeCount = 2;
		var spot = new SpotLight3D();
		spot.position.set(4, 4, 3);
		spot.direction.set(-4, -4, -3);
		spot.setCone(.35, .5);
		spot.intensity = 80;
		spot.castsShadow = true;
		spot.shadow.radius = 2;
		spot.shadow.color = 0xff203060;
		batch.lights.push(sun);
		batch.lights.push(spot);
		batch.environment.setAmbient(0xff8090a0, .6);
		camera.transform.position.set(0, 5, 8);
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
		renderer.beginFrame(window.framebufferWidth, window.framebufferHeight, 0xff101418);
		batch.begin(camera);
		batch.drawMesh(ground, floor, Matrix3D.fromTranslation(0, 0, 0, place));
		batch.drawMesh(box, crate, Matrix3D.fromRotation(0, 1, 0, t * .5, place).appendTranslation(0, 1.2, 0, place));
		batch.drawMesh(pillar, stone, Matrix3D.fromTranslation(-2.2, 1.2, 1, place));
		batch.end();
		renderer.endFrame();
		if (framesLeft == 1)
			Screenshot.save(graphics, system);
		graphics.present();
		return framesLeft < 0 || --framesLeft > 0;
	}

	/** Frees what was made: the renderer frees the meshes still held. */
	static function dispose():Void {
		renderer.dispose();
		graphics.dispose();
		events.dispose();
		if (window.canClose())
			window.close();
	}
}
