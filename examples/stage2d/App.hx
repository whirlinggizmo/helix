import helix.debug.FpsOverlay;
import helix.graphics.Graphics;
import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.Input;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Node2D;
import helix.render2d.Particles2D;
import helix.render2d.Shape2D;
import helix.render2d.Sprite2D;
import helix.render2d.Text2D;
import helix.render2d.Stage2D;
import helix.render2d.Textures;
import helix.time.Time;
import helix.host.ScreenShape;

/** A 2D world on a Stage2D seen through a zooming camera, and a HUD stage over it in the design for the window's shape: a polygon rock turning in outline, a ring,
	a box turning about its center, a rounded one turning with it and a rounded outline, a sprite of a loaded texture, a group (a hub with two
	moons) turning as one, and a particle emitter circling and trailing (drawn by the GPU at its place in the stage's order); then immediate
	text over both. Both stages draw into one batch, each through its own camera. Escape quits where quitting means anything. */
class App extends helix.App {
	var world = new Stage2D();
	var hud = new Stage2D();
	var batch:Batch2D;
	var worldCamera = new Camera2D();
	var hudCamera = new Camera2D();
	var fps = new FpsOverlay();
	var rock:Shape2D;
	var box:Shape2D;
	var card:Shape2D;
	var sprite:Sprite2D;
	var orbit:Node2D;
	var sparks:Particles2D;
	var title:Text2D;

	override public function init():Void {
		Window.title = "HeliX stage2d";
		Window.requestSize(800, 450);
		batch = new Batch2D();

		rock = Shape2D.polygon([0, -40, 28, -30, 40, -4, 30, 26, 6, 40, -24, 30, -40, 6, -30, -24]);
		rock.outline = 2;
		world.add(rock);
		var ring = Shape2D.circle(30, 0xff66bfff);
		ring.outline = 3;
		ring.setPosition(-120, 0);
		world.add(ring);
		box = Shape2D.rectangle(50, 30, 0xffbe2137);
		box.setPivot(.5, .5);
		box.setPosition(120, 0);
		world.add(box);
		// Rounded, filled and outlined.
		card = Shape2D.rectangle(50, 30, 0xff2fa36b);
		card.cornerRadius = 10;
		card.setPivot(.5, .5);
		card.setPosition(120, 75);
		world.add(card);
		var frame = Shape2D.rectangle(60, 40, 0xffe8a33c);
		frame.cornerRadius = 12;
		frame.outline = 3;
		frame.setPivot(.5, .5);
		frame.setPosition(-120, 75);
		world.add(frame);
		sprite = new Sprite2D(null);
		sprite.setSize(64, 64);
		sprite.setPosition(0, 110);
		world.add(sprite);
		Textures.load("textures/tiles.png", false, texture -> sprite.texture = texture);
		// A group: its children turn with it.
		orbit = new Node2D();
		orbit.setPosition(0, -110);
		orbit.addChild(Shape2D.circle(10, 0xffffcb00));
		for (side in [-1, 1]) {
			var moon = Shape2D.circle(5, 0xffc8c8c8);
			moon.setPosition(side * 30, 0);
			orbit.addChild(moon);
		}
		var spoke = Shape2D.line(-30, 0, 30, 0, 0xff808080);
		orbit.getChild(0).addChild(spoke);
		world.add(orbit);

		// An emitter: every way, 10 to 40 a second, shrinking from gold to a clear orange.
		var emitter = new helix.particles.Emitter(null, 512, true);
		emitter.rate = 120;
		emitter.setLife(.4, .9);
		emitter.setVelocity(25, 0, 0, Math.PI, .6);
		emitter.setSize(4, 0);
		emitter.setColor(0xffffcb00, 0x00ff3c00);
		sparks = new Particles2D(emitter);
		world.add(sparks);
		Textures.load("textures/particle.png", true, texture -> emitter.texture = texture);

		title = new Text2D("HeliX stage2d", 20, 0xfff5f5f5);
		hud.add(title);
	}

	override public function update(dt:Float):Void {
		if (Host.canQuit() && Input.isFramePressed(Key.Escape))
			Host.quit();
		// The game's clock: paused, the motion stops.
		var time = Time.clock.time;
		fps.update(dt, Time.frameCpu);
		rock.rotation = time * .6;
		box.rotation = -time * .8;
		card.rotation = -time * .8;
		sprite.rotation = -time * .3;
		orbit.rotation = time * 1.5;
		sparks.setPosition(Math.cos(time * 1.5) * 160, Math.sin(time * 1.5) * 80);
		world.time = time;
		var width = Window.framebufferWidth, height = Window.framebufferHeight;
		// The HUD in the design for the window's shape; the world zooms at the design's scale, so it fits a phone held upright too.
		ScreenShape.update();
		var presentation = Screen.instance;
		presentation.apply(hudCamera);
		var vx = presentation.visibleX,
			vy = presentation.visibleY,
			vw = presentation.visibleWidth;
		title.setPosition(vx + 12, vy + 32);
		worldCamera.setViewport(width, height);
		worldCamera.setPosition(0, 0);
		worldCamera.zoom = presentation.scaleX * (1.25 + .25 * Math.sin(time * .5));

		Graphics.beginFrame(width, height, 0xff0c0e16);
		batch.begin(worldCamera);
		world.draw(batch, worldCamera);
		hud.draw(batch, hudCamera);
		batch.drawTextWrapped('immediate text, over the stages: ${world.drawnNodeCount} world nodes drawn, ${Graphics.msaaSamples} of ${Graphics.maxMsaaSamples} MSAA samples a pixel',
			vx
			+ 12, vy
			+ 60, 14, vw
			- 24, 0xffc8c8c8);
		fps.draw(batch, vx + 12, vy + 10);
		batch.end();
		Graphics.endFrame();
	}

	override public function cleanup():Void
		batch.destroy();
}
