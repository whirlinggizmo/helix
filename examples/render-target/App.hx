import helix.app.BaseApp;
import helix.debug.FpsOverlay;
import helix.host.IHost;
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

	var host:IHost;
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
	var time = 0.;

	public function new(host:IHost) {
		super();
		this.host = host;
	}

	override public function init():Void {
		host.window.setTitle("HeliX render targets");
		host.window.setSize(1000, 560);
		var gpu = host.graphics;
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

		new Models(host.assets, host.textures).load("models/toy_car.glb", result -> switch result {
			case Ready(file):
				car = file.instantiate("car");
				car.setScale(.6, .6, .6);
				stage.add(car);
			case Failed(message):
				trace(message);
			case Cancelled:
		});
		// The built-in font until it has loaded.
		new Fonts(host.assets, gpu).load("fonts/Komika/KOMIKAH_.ttf", result -> switch result {
			case Ready(loaded):
				font = loaded;
			case Failed(message):
				trace(message);
			case Cancelled:
		});
	}

	// A texture with a 2 pixel frame and a caption above it, in logical pixels.
	function panel(texture:Texture2D, x:Float, y:Float, w:Float, h:Float, caption:String):Void {
		batch.rect(x - 2, y - 2, w + 4, h + 4, 0x5a606eff);
		batch.image(texture, x, y, w, h);
		Text2D.draw(batch, caption, x, y - 22, 16, 0xc8c8c8ff);
	}

	override public function frame(dt:Float):Void {
		if (host.canQuit() && host.input.isFramePressed(Key.Escape))
			host.quit();
		time += dt;
		fps.update(dt, host.diagnostics.getFrameCpu());
		if (car != null) {
			// Drives in a circle.
			car.setPosition(Math.cos(time * .6) * 2.5, 0, Math.sin(time * .6) * 2.5);
			car.setRotation(0, -time * .6, 0);
		}
		globe.setRotation(0, time * .8, 0);
		var gpu = host.graphics,
			width = host.getFramebufferWidth(),
			height = host.getFramebufferHeight();

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

		// The screen.
		screen.setViewport(width, height);
		screen.pixels(host.getPixelRatio());
		gpu.beginFrame(width, height, BACKGROUND);
		batch.begin(screen);
		panel(pixelView, 24, 92, PIXEL_W * PIXEL_SCALE, PIXEL_H * PIXEL_SCALE, "pixel view (160x100, nearest)");
		panel(minimap, 700, 92, MINIMAP, MINIMAP, "minimap (orthographic, from above)");
		panel(label, 700, 400, LABEL_W, LABEL_H, "label (text drawn into a texture)");
		Text2D.draw(batch, "HeliX render targets: Texture2D.renderTarget + IGraphics.beginTargetPass", 12, 36, 16, 0xf5f5f5ff);
		fps.draw(batch, 12, 10);
		batch.end();
		gpu.endFrame();
	}

	override public function cleanup():Void {
		for (texture in [pixelView, minimap, label])
			texture.destroy(host.graphics);
		stage.destroy();
		batch.destroy();
	}
}
