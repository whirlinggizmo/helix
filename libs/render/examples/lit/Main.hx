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
import helix.render.HemisphereLight3D;
import helix.render.Material3D;
import helix.render.PointLight3D;
import helix.render.Renderer;
import helix.render.SpotLight3D;

/** Shows helix-render's lit materials and lights: three spheres shaded Lambert, Phong and MetallicRoughness, a fourth metallic and a
	fifth with a clear coat, on a ground, under a sun, a hemisphere light of a blue sky over brown ground, a red point light circling
	them, and a spot light's pool on the ground; a glowing cube lit by nothing but its emissive light.

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
	static var sphere:GpuMesh3D;
	static var ground:GpuMesh3D;
	static var cube:GpuMesh3D;
	static final camera = new Camera3D();
	static final materials:Array<Material3D> = [];
	static final floor = new Material3D();
	static final glowing = new Material3D();
	static final red = new PointLight3D();
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
		window.title = "helix-render: lit 3D";
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

	// A material of a shading and a color.
	static function material(shading:helix.render.Shading3D, color:Int):Material3D {
		var m = new Material3D();
		m.shading = shading;
		m.baseColor = color;
		return m;
	}

	/** Makes the renderer, its batch, the meshes, the materials and the lights. */
	static function setup():Void {
		var frames = system.getOption("quit_after_frame");
		if (frames != null)
			framesLeft = Std.parseInt(frames);
		renderer = new Renderer(graphics);
		batch = new Batch3D(renderer);
		sphere = renderer.createMesh(Mesh3D.fromSphere(.8, 32, 16));
		ground = renderer.createMesh(Mesh3D.fromPlane(14, 8, 1, 1));
		cube = renderer.createMesh(Mesh3D.fromBox(.8, .8, .8));
		materials.push(material(Lambert, 0xffd0d0d0));
		var phong = material(Phong, 0xff3060c0);
		phong.specularColor = 0xff404040;
		phong.shininess = 60;
		materials.push(phong);
		var plastic = material(MetallicRoughness, 0xff40a060);
		plastic.roughness = .35;
		materials.push(plastic);
		var gold = material(MetallicRoughness, 0xffe0b040);
		gold.metallic = 1;
		gold.roughness = .3;
		materials.push(gold);
		var coated = material(MetallicRoughness, 0xffa02020);
		coated.roughness = .7;
		coated.clearcoat = 1;
		coated.clearcoatRoughness = .05;
		materials.push(coated);
		floor.shading = Lambert;
		floor.baseColor = 0xff909090;
		glowing.emissiveColor = 0xffff8020;
		glowing.emissiveStrength = 2;
		var sun = new DirectionalLight3D();
		sun.direction.set(-1, -2, -1);
		sun.intensity = 2;
		var sky = new HemisphereLight3D();
		sky.color = 0xff80a0ff;
		sky.groundColor = 0xff806040;
		sky.intensity = 1;
		red.color = 0xffff3020;
		red.intensity = 6;
		red.range = 6;
		var spot = new SpotLight3D();
		spot.position.set(-3.5, 4, 2.2);
		spot.direction.set(0, -1, 0);
		spot.setCone(.25, .4);
		spot.intensity = 60;
		for (l in [sun, sky, red, spot])
			batch.lights.push(l);
		camera.transform.position.set(0, 4, 9);
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
		red.position.set(Math.cos(t) * 3, 1.5, Math.sin(t) * 3);
		renderer.beginFrame(window.framebufferWidth, window.framebufferHeight, 0xff101418);
		batch.begin(camera);
		batch.drawMesh(ground, floor, Matrix3D.fromTranslation(0, -.8, 0, place));
		for (i in 0...materials.length)
			batch.drawMesh(sphere, materials[i], Matrix3D.fromTranslation((i - 2) * 2, 0, 0, place));
		batch.drawMesh(cube, glowing, Matrix3D.fromRotation(0, 1, 0, t, place).appendTranslation(3.5, -.4, 2.2, place));
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
