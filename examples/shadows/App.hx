import helix.debug.FpsOverlay;
import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.Input;
import helix.input.Key;
import helix.render2d.Drawing2D;
import helix.render2d.Stage;
import helix.render3d.Camera3D;
import helix.render3d.DirectionalLight3D;
import helix.render3d.Environment3D;
import helix.render3d.Material3D;
import helix.render3d.Mesh3D;
import helix.render3d.Model3D;
import helix.render3d.ModelFile3D;
import helix.render3d.Models3D;
import helix.render3d.Node3D;
import helix.render3d.SpotLight3D;
import helix.render3d.View3D;
import helix.time.Time;
import helix.host.ScreenShape;
import helix.render3d.Orbit3D;

/** Lights casting shadows. The sun casts (DirectionalLight3D.shadowCasting): each frame, before the frame's own pass, the View3D showing the level
	draws everything that casts into a depth map as the sun sees it, and the lit shading darkens what is behind something. The level is a floor, a wall, some
	generated shapes and a car, so the shadows fall across each other and across themselves. A spot circling overhead casts through its own
	cone: two lights casting at once, a layer of the map each. The ball on the left casts nothing (Model3D.shadowCasting), so it floats; the one
	on the right receives nothing (Model3D.shadowReceiving), so the wall's shadow passes over it; the spot's marker casts nothing either.

	1 / 2: the sun's / the spot's shadows on and off; UP / DOWN: the sun's shadow distance (less covers less with the same map, so the shadows
	sharpen); [ / ]: depth bias (too little stripes lit surfaces, "acne"; too much lifts a shadow off its caster); M: map size (512 to 4096);
	S / T: how much light a shadow blocks / what it leaves of the surface's color; O: orbit the camera or hold it; Escape: quit, where quitting
	means anything. */
class App extends helix.App {
	static var SIZES = [512, 1024, 2048, 4096];
	// What a shadow keeps of the surface's color: nothing (physical), then two stylized tints.
	static var TINTS = [0xff000000, 0xff1e3c64, 0xff64321e];

	var level = new Node3D();
	var view:View3D;
	var camera = new Camera3D();
	var text = new Drawing2D();
	var fps = new FpsOverlay();
	var sun = new DirectionalLight3D();
	var spot = new SpotLight3D();
	var marker:Model3D;
	// The camera, circling.
	var orbit = new Orbit3D(11, 5, .18, 1.2);
	var distance = 30.;
	var bias = 1.;
	var strength = 1.;
	var size = 1;
	var tint = 0;

	// A model of mesh at x, y, z in one color (0xAARRGGBB), in the level.
	function place(mesh:Mesh3D, x:Float, y:Float, z:Float, color:Int, roughness:Float):Model3D {
		var material = new Material3D();
		material.baseColor = color;
		material.roughness = roughness;
		var node = new Model3D(mesh, material);
		node.setPosition(x, y, z);
		level.addChild(node);
		return node;
	}

	override public function init():Void {
		Window.title = "HeliX shadows";
		Window.requestSize(1000, 600);
		// Framed for 16:9: the whole level on a phone held upright too.
		camera.minAspect = 16 / 9;
		Stage.color = 0xff7896c8;
		// The place's light, on the level's root: a soft blue ambient under the lights.
		level.environment = new Environment3D();
		level.environment.setAmbient(0xff8caae1, .25);
		sun.color = 0xfffff4e0;
		sun.intensity = 3.2;
		sun.shadowCasting = true;
		sun.shadowDistance = distance;
		sun.shadowMapSize = SIZES[size];
		sun.lookAt(-.75, -.85, -.35);
		level.addChild(sun);
		// A second caster, circling: both share the map, so both use the same size.
		spot.color = 0xff96d2ff;
		spot.intensity = 260;
		spot.range = 24;
		spot.setCone(.3, .44);
		spot.shadowCasting = true;
		spot.shadowMapSize = SIZES[size];
		spot.shadowDistance = 24;
		level.addChild(spot);
		var glow = new Material3D();
		glow.baseColor = 0xff96d2ff;
		glow.lit = false;
		marker = new Model3D(Mesh3D.sphere(.16, 8, 16), glow);
		marker.shadowCasting = false;
		level.addChild(marker);

		place(Mesh3D.plane(40, 40), 0, 0, 0, 0xffb0b4b8, .9);
		// A wall to throw a long shadow across the floor.
		place(Mesh3D.cube(.5, 3, 7), -4.5, 1.5, 0, 0xffc4bbb1, .85);
		place(Mesh3D.torus(.7, .22, 48, 24), 2.6, 1.1, -1.6, 0xfff3c27c, .4);
		place(Mesh3D.capsule(.4, 1.6, 16, 32), 1.2, .8, 1.8, 0xff9ee0b2, .5);
		place(Mesh3D.cube(1, 1, 1), 3.8, .5, 1.4, 0xff95bded, .6);
		// One that casts nothing, and one that nothing shadows.
		place(Mesh3D.sphere(.6, 24, 48), -2, .6, 2.4, 0xfff8ed95, .35).shadowCasting = false;
		place(Mesh3D.sphere(.6, 24, 48), -2.6, .6, -1.2, 0xfff395bc, .35).shadowReceiving = false;
		Models3D.load("models/car-kit/sedan-sports.glb", file -> placeCar(file));
		view = new View3D(level, camera);
		Stage.addChild(view);
		Stage.addChild(text);
		Stage.addChild(fps);
	}

	// The car's file in: a copy of it among the shapes, turned a little.
	function placeCar(file:ModelFile3D):Void {
		var car = file.instantiate("car");
		car.setScale(1.5, 1.5, 1.5);
		car.setRotation(0, .6, 0);
		level.addChild(car);
	}

	override public function update(dt:Float):Void {
		if (Host.canQuit() && Input.isFramePressed(Key.Escape))
			Host.quit();
		if (Input.isFramePressed(Key.Digit1))
			sun.shadowCasting = !sun.shadowCasting;
		if (Input.isFramePressed(Key.Digit2))
			spot.shadowCasting = !spot.shadowCasting;
		if (Input.isFramePressed(Key.O))
			orbit.running = !orbit.running;
		if (Input.isFramePressed(Key.S)) {
			strength = strength > .9 ? .65 : strength > .5 ? .35 : 1;
			sun.shadowStrength = strength;
		}
		if (Input.isFramePressed(Key.T)) {
			tint = (tint + 1) % TINTS.length;
			sun.shadowColor = TINTS[tint];
		}
		if (Input.isFramePressed(Key.M)) {
			size = (size + 1) % SIZES.length;
			sun.shadowMapSize = SIZES[size];
			spot.shadowMapSize = SIZES[size];
		}
		if (Input.isDown(Key.Up) != Input.isDown(Key.Down)) {
			distance = Math.max(2, Math.min(distance + (Input.isDown(Key.Up) ? 20 : -20) * dt, 200));
			sun.shadowDistance = distance;
		}
		if (Input.isDown(Key.LeftBracket) != Input.isDown(Key.RightBracket)) {
			bias = Math.max(0, Math.min(bias + (Input.isDown(Key.RightBracket) ? 4 : -4) * dt, 16));
			sun.setShadowBias(bias, bias * 4);
		}
		// The game's clock: paused, the motion stops.
		var time = Time.clock.time;
		fps.update(dt, Time.frameCpu);
		// The spot circles overhead, aimed at the middle of the level.
		var sx = 7 * Math.sin(time * .35), sz = 7 * Math.cos(time * .35);
		spot.setPosition(sx, 6.5, sz);
		spot.lookAt(0, 0, 0);
		marker.setPosition(sx, 6.5, sz);
		orbit.update(dt);
		orbit.apply(camera);
		// The text in the design for the window's shape, wrapped to what's visible of it.
		ScreenShape.update();
		var vx = Screen.visibleX,
			vy = Screen.visibleY,
			vw = Screen.visibleWidth;

		text.clear();
		var y = vy + 36;
		var lines = [
			{
				text: "HeliX shadows: lights casting into a depth map",
				size: 20,
				color: 0xfff5f5f5,
				gap: 3
			},
			{
				text: '[1] sun ${sun.shadowCasting ? "on" : "off"}   [2] spot ${spot.shadowCasting ? "on" : "off"}   ' +
				'[M] map ${SIZES[size]}   [S] strength ${strength}   [T] tint',
				size: 16,
				color: 0xffc8c8c8,
				gap: 2
			},
			{
				text: 'UP/DOWN distance ${Math.round(distance)}   [ ] bias ${Math.round(bias * 10) / 10}   [O] camera   ' +
				'${view.shadowCasterCount} casters in ${view.shadowDrawCallCount} draws',
				size: 16,
				color: 0xff9a9a9a,
				gap: 2
			},
			{
				text: "left ball casts nothing; right ball receives nothing",
				size: 16,
				color: 0xff9a9a9a,
				gap: 0
			}
		];
		for (line in lines) {
			y += text.drawTextWrapped(line.text, vx + 12, y, line.size, vw - 24, line.color) + line.gap;
		}
		fps.setPosition(vx + 12, vy + 10);
	}

	override public function cleanup():Void
		view.destroy();
}
