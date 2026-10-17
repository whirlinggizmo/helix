import helix.app.BaseApp;
import helix.debug.FpsOverlay;
import helix.host.Services;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Font2D;
import helix.render2d.Fonts;
import helix.render2d.Text2D;
import helix.render2d.Texture2D;
import helix.render3d.Camera3D;
import helix.render3d.Light;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.Models;
import helix.render3d.Node;
import helix.render3d.Stage3D;

/** Drawing into textures (Texture2D.renderTarget, IGraphics.beginTargetPass):
	- "pixel view": the stage drawn into a 160x100 texture and shown 4x larger with nearest sampling, a low-resolution pixel-art look
	- "minimap": the same stage from an orthographic camera above it, in a 256x256 texture
	- "label": text in two fonts drawn into a 256x128 texture, used as the base color texture of the spinning globe's material, and shown on its own
	Each frame draws the label first, so the views that use it show this frame's label; the target passes all come before the screen's. The toy
	car drives a circle. Escape quits where quitting means anything. */
class App extends BaseApp {
	static inline var PIXEL_W = 160;
	static inline var PIXEL_H = 100;
	static inline var PIXEL_SCALE = 4;
	static inline var MINIMAP = 256;
	static inline var LABEL_W = 256;
	static inline var LABEL_H = 128;
	static inline var BACKGROUND = 0x181a22ff;

	var stage:Stage3D;
	var batch:Batch2D;
	var camera = new Camera3D();
	var top = new Camera3D();
	var screen = new Camera2D();
	var targetCamera = new Camera2D();
	var fps = new FpsOverlay();
	var pixelView:Texture2D;
	var minimap:Texture2D;
	var label:Texture2D;
	var font:Null<Font2D>;
	var car:Null<Node>;
	var globe:Node;

	override public function init():Void {
		Services.window.setTitle("HeliX render targets");
		Services.window.requestSize(1000, 560);
		var gpu = Services.graphics;
		batch = new Batch2D(gpu);
		pixelView = Texture2D.renderTarget(gpu, PIXEL_W, PIXEL_H, false);
		minimap = Texture2D.renderTarget(gpu, MINIMAP, MINIMAP);
		label = Texture2D.renderTarget(gpu, LABEL_W, LABEL_H);

		stage = new Stage3D(gpu);
		stage.setAmbient(0xffffffff, .25);
		var sunLight = new Light(Directional);
		sunLight.setIntensity(3);
		var sun = Node.light(sunLight);
		sun.lookAt(-.5, -1, -.4);
		stage.add(sun);
		camera.setView(0, 6, 10, 0, .8, 0);
		// Looking straight down, -z up the map.
		top.setView(0, 12, 0, 0, 0, 0, 0, 0, -1);
		top.setOrthographic(9, .1, 50);

		// The ground: a flattened sphere.
		var ground = new Material();
		ground.setBaseColor(0x8a9689ff);
		var floor = Node.model(Mesh.sphere(.5, 32, 64), ground);
		floor.setPosition(0, -.05, 0);
		floor.setScale(8, .1, 8);
		stage.add(floor);
		// The globe wears the label: drawn into each frame, used as any texture.
		var wrap = new Material();
		wrap.setLit(false);
		wrap.setTexture(label);
		globe = Node.model(Mesh.sphere(.5, 32, 64), wrap);
		globe.setPosition(-2.2, 1.2, 0);
		globe.setScale(1.6, 1.6, 1.6);
		stage.add(globe);

		new Models(Services.assets, Services.textures).load("models/car-kit/sedan-sports.glb", result -> switch result {
			case Ready(file):
				car = file.instantiate("car");
				car.setScale(.9, .9, .9);
				stage.add(car);
			case Failed(message):
				trace(message);
			case Cancelled:
		});
		// The built-in font until it has loaded.
		new Fonts(Services.assets, gpu).load("fonts/Komika/KOMIKAH_.ttf", result -> switch result {
			case Ready(loaded):
				font = loaded;
			case Failed(message):
				trace(message);
			case Cancelled:
		});
	}

	// A texture with a 2 unit frame and a caption above it, in the presentation's units.
	function panel(texture:Texture2D, x:Float, y:Float, w:Float, h:Float, caption:String):Void {
		batch.rect(x - 2, y - 2, w + 4, h + 4, 0x5a606eff);
		batch.image(texture, x, y, w, h);
		Text2D.draw(batch, caption, x, y - 22, 16, 0xc8c8c8ff);
	}

	override public function frame(dt:Float):Void {
		if (Services.canQuit() && Services.input.isFramePressed(Key.Escape))
			Services.quit();
		// The game's clock: paused, the motion stops.
		var time = Services.clock.getTime();
		fps.update(dt, Services.getFrameCpu());
		if (car != null) {
			// Drives in a circle.
			car.setPosition(Math.cos(time * .6) * 2.5, 0, Math.sin(time * .6) * 2.5);
			car.setRotation(0, -time * .6, 0);
		}
		globe.setRotation(0, time * .8, 0);
		var gpu = Services.graphics,
			width = Services.window.getFramebufferWidth(),
			height = Services.window.getFramebufferHeight();

		// 1. The label, first, so the views below use this frame's text.
		gpu.beginTargetPass(label.getHandle(), 0x1e3c8cff);
		targetCamera.setViewport(LABEL_W, LABEL_H);
		targetCamera.pixels(1);
		batch.begin(targetCamera);
		Text2D.draw(batch, "HeliX", 20, 14, 64, 0xf5f5f5ff, Left, font);
		Text2D.draw(batch, 't = ${Math.round(time * 10) / 10}', 24, 92, 16, 0xffcb00ff);
		batch.end();
		gpu.endTargetPass();

		// 2. A low-resolution view of the stage.
		gpu.beginTargetPass(pixelView.getHandle(), BACKGROUND);
		camera.setViewport(PIXEL_W, PIXEL_H);
		stage.draw(camera);
		gpu.endTargetPass();

		// 3. The minimap, from above.
		gpu.beginTargetPass(minimap.getHandle(), 0x0c0e12ff);
		top.setViewport(MINIMAP, MINIMAP);
		stage.draw(top);
		gpu.endTargetPass();

		// The screen, in the design for the window's shape.
		var shape = ScreenShape.update(), presentation = Services.presentation;
		presentation.apply(screen);
		var vx = presentation.getVisibleX(),
			vy = presentation.getVisibleY(),
			vw = presentation.getVisibleWidth();
		gpu.beginFrame(width, height, BACKGROUND);
		batch.begin(screen);
		var top = vy
			+ 36
			+ Text2D.drawWrapped(batch, "HeliX render targets: Texture2D.renderTarget + IGraphics.beginTargetPass", vx + 12, vy + 36, 16, vw - 24, 0xf5f5f5ff)
			+ 36;
		// The pixel view on the left and the other two in a column beside it; upright, all three in a column, the pixel view as wide as fits.
		var x = vx + 24, pixelWidth = Math.min(PIXEL_W * PIXEL_SCALE, vw - 48), pixelHeight = pixelWidth * PIXEL_H / PIXEL_W;
		panel(pixelView, x, top, pixelWidth, pixelHeight, "pixel view (160x100, nearest)");
		var column = shape == "portrait" ? x : x + pixelWidth + 36,
			below = shape == "portrait" ? top + pixelHeight + 48 : top;
		panel(minimap, column, below, MINIMAP, MINIMAP, "minimap (orthographic, from above)");
		panel(label, column, below + MINIMAP + 52, LABEL_W, LABEL_H, "label (text drawn into a texture)");
		fps.draw(batch, vx + 12, vy + 10);
		batch.end();
		gpu.endFrame();
	}

	override public function cleanup():Void {
		for (texture in [pixelView, minimap, label])
			texture.destroy(Services.graphics);
		stage.destroy();
		batch.destroy();
	}
}
