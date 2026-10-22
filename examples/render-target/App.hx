import helix.debug.FpsOverlay;
import helix.graphics.PostProcess;
import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.Input;
import helix.input.Key;
import helix.render2d.Camera2D;
import helix.render2d.Drawing2D;
import helix.font.Font;
import helix.font.Fonts;
import helix.render2d.Node2D;
import helix.render2d.Stage;
import helix.render2d.View2D;
import helix.render3d.Camera3D;
import helix.render3d.DirectionalLight3D;
import helix.render3d.Environment3D;
import helix.render3d.Material3D;
import helix.render3d.Mesh3D;
import helix.render3d.Model3D;
import helix.render3d.ModelFile3D;
import helix.render3d.Models3D;
import helix.render3d.Node3D;
import helix.render3d.View3D;
import helix.shader.Pixelate;
import helix.time.Time;
import helix.host.ScreenShape;

/** Views drawn into textures (View.postProcess; docs/DISPLAY_MODEL.md): a view with a chain draws what it shows into a texture before the
	frame (cleared to its color), runs the chain and draws the result where the view is, in the 2D's order.
	- "pixel view": a View3D of the level pixelated by its chain (helix.shader.Pixelate, cells of 4 units: 160x100 of them), a
	  low-resolution pixel-art look
	- "minimap": a second View3D of the same level, from an orthographic camera above it, 256x256, on a darker background (an empty chain
	  draws it into a texture cleared to its color)
	- "label": text in two fonts, a Drawing2D in a 256x128 View2D whose empty chain draws it into a texture (View.texture), used as
	  the base color texture of the spinning globe's material, and shown on its own
	Every texture is drawn before the frame, the label's first (it's added to the stage first), so the 3D views show this frame's label. The
	toy car drives a circle. Escape quits where quitting means anything. */
class App extends helix.App {
	static inline var PIXEL_W = 160;
	static inline var PIXEL_H = 100;
	static inline var PIXEL_SCALE = 4;
	static inline var MINIMAP = 256;
	static inline var LABEL_W = 256;
	static inline var LABEL_H = 128;
	static inline var BACKGROUND = 0xff181a22;

	var level = new Node3D();
	var camera = new Camera3D();
	var top = new Camera3D();
	var labelCamera = new Camera2D();
	var labelText = new Drawing2D();
	var labelView:View2D;
	var pixelate:Pixelate;
	var pixelView:View3D;
	var minimap:View3D;
	var panels = new Drawing2D();
	var fps = new FpsOverlay();
	var font:Null<Font>;
	var car:Null<Node3D>;
	var globe:Model3D;
	var wrap:Material3D;

	override public function init():Void {
		Window.title = "HeliX render targets";
		Window.requestSize(1000, 560);
		Stage.color = BACKGROUND;

		level.environment = new Environment3D();
		level.environment.setAmbient(0xffffffff, .25);
		var sun = new DirectionalLight3D();
		sun.intensity = 3;
		sun.lookAt(-.5, -1, -.4);
		level.addChild(sun);
		camera.setView(0, 6, 10, 0, .8, 0);
		// Looking straight down, -z up the map.
		top.setView(0, 12, 0, 0, 0, 0, 0, 0, -1);
		top.projection = Orthographic;
		top.orthographicHeight = 9;
		top.near = .1;
		top.far = 50;

		// The ground: a flattened sphere.
		var ground = new Material3D();
		ground.baseColor = 0xff8a9689;
		var floor = new Model3D(Mesh3D.sphere(.5, 32, 64), ground);
		floor.setPosition(0, -.05, 0);
		floor.setScale(8, .1, 8);
		level.addChild(floor);
		// The globe wears the label: its view's texture, drawn into each frame, used as any texture.
		wrap = new Material3D();
		wrap.lit = false;
		globe = new Model3D(Mesh3D.sphere(.5, 32, 64), wrap);
		globe.setPosition(-2.2, 1.2, 0);
		globe.setScale(1.6, 1.6, 1.6);
		level.addChild(globe);

		// The label: a drawing in its own 256 x 128 units, shown by a view whose chain draws it into a texture.
		var label = new Node2D();
		label.addChild(labelText);
		labelView = new View2D(label, labelCamera, LABEL_W, LABEL_H);
		labelView.postProcess = new PostProcess();
		labelView.color = 0xff1e3c8c;
		// The panels' frames and captions, under the views.
		Stage.addChild(panels);
		Stage.addChild(labelView);
		pixelView = new View3D(level, camera, PIXEL_W * PIXEL_SCALE, PIXEL_H * PIXEL_SCALE);
		pixelView.postProcess = new PostProcess();
		pixelView.color = BACKGROUND;
		pixelate = new Pixelate(PIXEL_SCALE);
		pixelView.postProcess.add(pixelate);
		Stage.addChild(pixelView);
		minimap = new View3D(level, top, MINIMAP, MINIMAP);
		minimap.postProcess = new PostProcess();
		minimap.color = 0xff0c0e12;
		Stage.addChild(minimap);
		Stage.addChild(fps);

		Models3D.load("models/car-kit/sedan-sports.glb", file -> place(file));
		// The built-in font until it has loaded.
		Fonts.load("fonts/Komika/KOMIKAH_.ttf", loaded -> font = loaded);
	}

	// The car's file in: a copy of it in the level the views show.
	function place(file:ModelFile3D):Void {
		car = file.instantiate("car");
		car.setScale(.9, .9, .9);
		level.addChild(car);
	}

	// A view placed at x, y, w x h, with a 2 unit frame and a caption above it, in the presentation's units.
	function panel(view:helix.render2d.View, x:Float, y:Float, w:Float, h:Float, caption:String):Void {
		panels.rect(x - 2, y - 2, w + 4, h + 4, 0xff5a606e);
		panels.drawText(caption, x, y - 22, 16, 0xffc8c8c8);
		view.setPosition(x, y);
		view.width = w;
		view.height = h;
	}

	override public function update(dt:Float):Void {
		if (Host.canQuit() && Input.isFramePressed(Key.Escape))
			Host.quit();
		// The game's clock: paused, the motion stops.
		var time = Time.clock.time;
		fps.update(dt, Time.frameCpu);
		if (car != null) {
			// Drives in a circle.
			car.setPosition(Math.cos(time * .6) * 2.5, 0, Math.sin(time * .6) * 2.5);
			car.setRotation(0, -time * .6, 0);
		}
		globe.setRotation(0, time * .8, 0);

		// The label, in its own units, scaled as the stage's units are (framebuffer pixels per unit).
		var scale = Stage.camera.zoom;
		labelCamera.zoom = scale;
		labelCamera.setPosition(LABEL_W / 2, LABEL_H / 2);
		labelText.clear();
		labelText.drawText("HeliX", 20, 14, 64, 0xfff5f5f5, Left, font);
		labelText.drawText('t = ${Math.round(time * 10) / 10}', 24, 92, 16, 0xffffcb00);
		// Its texture, once it has drawn (made again when the view's size changes).
		wrap.texture = labelView.texture;

		// The screen, in the design for the window's shape.
		var shape = ScreenShape.update();
		var vx = Screen.visibleX,
			vy = Screen.visibleY,
			vw = Screen.visibleWidth;
		panels.clear();
		var top = vy
			+ 36
			+ panels.drawTextWrapped("HeliX render targets: views drawn into textures (View.postProcess)", vx + 12, vy + 36, 16, vw - 24, 0xfff5f5f5)
			+ 36;
		// The pixel view on the left and the other two in a column beside it; upright, all three in a column, the pixel view as wide as fits.
		var x = vx + 24, pixelWidth = Math.min(PIXEL_W * PIXEL_SCALE, vw - 48), pixelHeight = pixelWidth * PIXEL_H / PIXEL_W;
		panel(pixelView, x, top, pixelWidth, pixelHeight, "pixel view (160x100, nearest)");
		// 160 cells across, however wide it's shown, in framebuffer pixels.
		pixelate.cellSize = Std.int(Math.max(1, Math.round(pixelWidth * scale / PIXEL_W)));
		var column = shape == "portrait" ? x : x + pixelWidth + 36,
			below = shape == "portrait" ? top + pixelHeight + 48 : top;
		panel(minimap, column, below, MINIMAP, MINIMAP, "minimap (orthographic, from above)");
		panel(labelView, column, below + MINIMAP + 52, LABEL_W, LABEL_H, "label (text drawn into a texture)");
		fps.setPosition(vx + 12, vy + 10);
	}

	override public function cleanup():Void {
		var views:Array<helix.render2d.View> = [pixelView, minimap, labelView];
		for (view in views)
			view.destroy();
		for (view in views)
			view.postProcess.destroy();
	}
}
