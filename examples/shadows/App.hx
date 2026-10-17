import helix.app.BaseApp;
import helix.debug.FpsOverlay;
import helix.graphics.Graphics;
import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.Input;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Text2D;
import helix.render3d.Camera3D;
import helix.render3d.DirectionalLight;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.Model;
import helix.render3d.Models;
import helix.render3d.SpotLight;
import helix.render3d.Stage3D;
import helix.time.Time;

/** Lights casting shadows. The sun casts (DirectionalLight.setShadowCasting): each frame, before the frame's own pass, drawShadows draws everything that
	casts into a depth map as the sun sees it, and the lit shading darkens what is behind something. The stage is a floor, a wall, some
	generated shapes and a car, so the shadows fall across each other and across themselves. A spot circling overhead casts through its own
	cone: two lights casting at once, a layer of the map each. The ball on the left casts nothing (Model.setShadowCasting), so it floats; the one
	on the right receives nothing (Model.setShadowReceiving), so the wall's shadow passes over it; the spot's marker casts nothing either.

	1 / 2: the sun's / the spot's shadows on and off; UP / DOWN: the sun's shadow distance (less covers less with the same map, so the shadows
	sharpen); [ / ]: depth bias (too little stripes lit surfaces, "acne"; too much lifts a shadow off its caster); M: map size (512 to 4096);
	S / T: how much light a shadow blocks / what it leaves of the surface's color; O: orbit the camera or hold it; Escape: quit, where quitting
	means anything. */
class App extends BaseApp {
	static var SIZES = [512, 1024, 2048, 4096];
	// What a shadow keeps of the surface's color: nothing (physical), then two stylized tints.
	static var TINTS = [0x000000ff, 0x1e3c64ff, 0x64321eff];

	var stage:Stage3D;
	var batch:Batch2D;
	var camera = new Camera3D();
	var hud = new Camera2D();
	var fps = new FpsOverlay();
	var sun = new DirectionalLight();
	var spot = new SpotLight();
	var marker:Model;
	var orbit = true;
	var distance = 30.;
	var bias = 1.;
	var strength = 1.;
	var size = 1;
	var tint = 0;
	var angle = 0.;

	// A model of mesh at x, y, z in one color (0xRRGGBBAA), on the stage.
	function place(mesh:Mesh, x:Float, y:Float, z:Float, color:Int, roughness:Float):Model {
		var material = new Material();
		material.setBaseColor(color);
		material.setRoughness(roughness);
		var node = new Model(mesh, material);
		node.setPosition(x, y, z);
		stage.add(node);
		return node;
	}

	override public function init():Void {
		Window.setTitle("HeliX shadows");
		Window.requestSize(1000, 600);
		// Framed for 16:9: the whole stage on a phone held upright too.
		camera.setMinAspect(16 / 9);
		var gpu = Graphics.instance;
		batch = new Batch2D(gpu);
		stage = new Stage3D(gpu);
		stage.setAmbient(0x8caae1ff, .25);
		sun.setColor(0xfff4e0ff);
		sun.setIntensity(3.2);
		sun.setShadowCasting(true);
		sun.setShadowDistance(distance);
		sun.setShadowMapSize(SIZES[size]);
		sun.lookAt(-.75, -.85, -.35);
		stage.add(sun);
		// A second caster, circling: both share the map, so both use the same size.
		spot.setColor(0x96d2ffff);
		spot.setIntensity(260);
		spot.setRange(24);
		spot.setCone(.3, .44);
		spot.setShadowCasting(true);
		spot.setShadowMapSize(SIZES[size]);
		spot.setShadowDistance(24);
		stage.add(spot);
		var glow = new Material();
		glow.setBaseColor(0x96d2ffff);
		glow.setLit(false);
		marker = new Model(Mesh.sphere(.16, 8, 16), glow);
		marker.setShadowCasting(false);
		stage.add(marker);

		place(Mesh.plane(40, 40), 0, 0, 0, 0xb0b4b8ff, .9);
		// A wall to throw a long shadow across the floor.
		place(Mesh.cube(.5, 3, 7), -4.5, 1.5, 0, 0xc4bbb1ff, .85);
		place(Mesh.torus(.7, .22, 48, 24), 2.6, 1.1, -1.6, 0xf3c27cff, .4);
		place(Mesh.capsule(.4, 1.6, 16, 32), 1.2, .8, 1.8, 0x9ee0b2ff, .5);
		place(Mesh.cube(1, 1, 1), 3.8, .5, 1.4, 0x95bdedff, .6);
		// One that casts nothing, and one that nothing shadows.
		place(Mesh.sphere(.6, 24, 48), -2, .6, 2.4, 0xf8ed95ff, .35).setShadowCasting(false);
		place(Mesh.sphere(.6, 24, 48), -2.6, .6, -1.2, 0xf395bcff, .35).setShadowReceiving(false);
		Models.load("models/car-kit/sedan-sports.glb", result -> switch result {
			case Ready(file):
				var car = file.instantiate("car");
				car.setScale(1.5, 1.5, 1.5);
				car.setRotation(0, .6, 0);
				stage.add(car);
			case Failed(message):
				trace(message);
			case Cancelled:
		});
	}

	override public function frame(dt:Float):Void {
		var input = Input.instance;
		if (Host.canQuit() && input.isFramePressed(Key.Escape))
			Host.quit();
		if (input.isFramePressed(Key.Digit1))
			sun.setShadowCasting(!sun.isShadowCasting());
		if (input.isFramePressed(Key.Digit2))
			spot.setShadowCasting(!spot.isShadowCasting());
		if (input.isFramePressed(Key.O))
			orbit = !orbit;
		if (input.isFramePressed(Key.S)) {
			strength = strength > .9 ? .65 : strength > .5 ? .35 : 1;
			sun.setShadowStrength(strength);
		}
		if (input.isFramePressed(Key.T)) {
			tint = (tint + 1) % TINTS.length;
			sun.setShadowColor(TINTS[tint]);
		}
		if (input.isFramePressed(Key.M)) {
			size = (size + 1) % SIZES.length;
			sun.setShadowMapSize(SIZES[size]);
			spot.setShadowMapSize(SIZES[size]);
		}
		if (input.isDown(Key.Up) != input.isDown(Key.Down)) {
			distance = Math.max(2, Math.min(distance + (input.isDown(Key.Up) ? 20 : -20) * dt, 200));
			sun.setShadowDistance(distance);
		}
		if (input.isDown(Key.LeftBracket) != input.isDown(Key.RightBracket)) {
			bias = Math.max(0, Math.min(bias + (input.isDown(Key.RightBracket) ? 4 : -4) * dt, 16));
			sun.setShadowBias(bias, bias * 4);
		}
		// The game's clock: paused, the motion stops.
		var time = Time.clock.getTime();
		fps.update(dt, Time.getFrameCpu());
		// The spot circles overhead, aimed at the middle of the stage.
		var sx = 7 * Math.sin(time * .35), sz = 7 * Math.cos(time * .35);
		spot.setPosition(sx, 6.5, sz);
		spot.lookAt(0, 0, 0);
		marker.setPosition(sx, 6.5, sz);
		if (orbit)
			angle += dt * .18;
		var width = Window.getFramebufferWidth(),
			height = Window.getFramebufferHeight();
		camera.setViewport(width, height);
		camera.setView(11 * Math.sin(angle), 5, 11 * Math.cos(angle), 0, 1.2, 0);
		// The text in the design for the window's shape, wrapped to what's visible of it.
		ScreenShape.update();
		var presentation = Screen.instance;
		presentation.apply(hud);
		var vx = presentation.getVisibleX(),
			vy = presentation.getVisibleY(),
			vw = presentation.getVisibleWidth();

		stage.drawShadows(camera);
		Graphics.beginFrame(width, height, 0x7896c8ff);
		stage.draw(camera);
		batch.begin(hud);
		var y = vy + 36;
		y += Text2D.drawWrapped(batch, "HeliX shadows: lights casting into a depth map", vx + 12, y, 20, vw - 24, 0xf5f5f5ff) + 3;
		y += Text2D.drawWrapped(batch,
			'[1] sun ${sun.isShadowCasting() ? "on" : "off"}   [2] spot ${spot.isShadowCasting() ? "on" : "off"}   '
			+ '[M] map ${SIZES[size]}   [S] strength ${strength}   [T] tint',
			vx
			+ 12, y, 16, vw
			- 24, 0xc8c8c8ff)
			+ 2;
		y += Text2D.drawWrapped(batch,
			'UP/DOWN distance ${Math.round(distance)}   [ ] bias ${Math.round(bias * 10) / 10}   [O] camera   '
			+ '${stage.getShadowCasterCount()} casters in ${stage.getShadowDrawCallCount()} draws',
			vx
			+ 12, y, 16, vw
			- 24, 0x9a9a9aff)
			+ 2;
		Text2D.drawWrapped(batch, "left ball casts nothing; right ball receives nothing", vx + 12, y, 16, vw - 24, 0x9a9a9aff);
		fps.draw(batch, vx + 12, vy + 10);
		batch.end();
		Graphics.endFrame();
	}

	override public function cleanup():Void {
		stage.destroy();
		batch.destroy();
	}
}
