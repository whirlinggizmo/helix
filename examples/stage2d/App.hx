import helix.app.BaseApp;
import helix.debug.FpsOverlay;
import helix.host.Services;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Node2D;
import helix.render2d.Stage2D;
import helix.render2d.Text2D;

/** A 2D world on a Stage2D seen through a zooming camera, and a HUD stage over it in logical pixels: a polygon rock turning in outline, a ring,
	a box turning about its center, a rounded one turning with it and a rounded outline, a sprite of a loaded texture, a group (a hub with two
	moons) turning as one, and a particle emitter circling and trailing (drawn by the GPU at its place in the stage's order); then immediate
	text over both. Both stages draw into one batch, each through its own camera. Escape quits where quitting means anything. */
class App extends BaseApp {
	var services:Services;
	var world = new Stage2D();
	var hud = new Stage2D();
	var batch:Batch2D;
	var worldCamera = new Camera2D();
	var hudCamera = new Camera2D();
	var fps = new FpsOverlay();
	var rock:Node2D;
	var box:Node2D;
	var card:Node2D;
	var sprite:Node2D;
	var orbit:Node2D;
	var sparks:Node2D;
	var time = 0.;

	public function new(services:Services) {
		super();
		this.services = services;
	}

	override public function init():Void {
		services.window.setTitle("HeliX stage2d");
		services.window.requestSize(800, 450);
		batch = new Batch2D(services.graphics);

		rock = Node2D.polygon([0, -40, 28, -30, 40, -4, 30, 26, 6, 40, -24, 30, -40, 6, -30, -24]);
		rock.setOutline(2);
		world.add(rock);
		var ring = Node2D.circle(30, 0x66bfffff);
		ring.setOutline(3);
		ring.setPosition(-120, 0);
		world.add(ring);
		box = Node2D.rectangle(50, 30, 0xbe2137ff);
		box.setPivot(.5, .5);
		box.setPosition(120, 0);
		world.add(box);
		// Rounded, filled and outlined.
		card = Node2D.rectangle(50, 30, 0x2fa36bff);
		card.setCornerRadius(10);
		card.setPivot(.5, .5);
		card.setPosition(120, 75);
		world.add(card);
		var frame = Node2D.rectangle(60, 40, 0xe8a33cff);
		frame.setCornerRadius(12);
		frame.setOutline(3);
		frame.setPivot(.5, .5);
		frame.setPosition(-120, 75);
		world.add(frame);
		sprite = Node2D.sprite(null);
		sprite.setSize(64, 64);
		sprite.setPosition(0, 110);
		world.add(sprite);
		services.textures.load("textures/tiles.png", false, result -> switch result {
			case Ready(texture):
				sprite.setTexture(texture);
			case Failed(message):
				trace(message);
			case Cancelled:
		});
		// A group: its children turn with it.
		orbit = Node2D.group();
		orbit.setPosition(0, -110);
		orbit.add(Node2D.circle(10, 0xffcb00ff));
		for (side in [-1, 1]) {
			var moon = Node2D.circle(5, 0xc8c8c8ff);
			moon.setPosition(side * 30, 0);
			orbit.add(moon);
		}
		var spoke = Node2D.line(-30, 0, 30, 0, 0x808080ff);
		orbit.getChild(0).add(spoke);
		world.add(orbit);

		// An emitter: every way, 10 to 40 a second, shrinking from gold to a clear orange.
		var emitter = new helix.particles.Emitter(null, 512, true);
		emitter.setRate(120);
		emitter.setLife(.4, .9);
		emitter.setVelocity(25, 0, 0, Math.PI, .6);
		emitter.setSize(4, 0);
		emitter.setColor(0xffcb00ff, 0xff3c0000);
		sparks = Node2D.emitter(emitter);
		world.add(sparks);
		services.textures.load("textures/particle.png", true, result -> switch result {
			case Ready(texture):
				emitter.setTexture(texture);
			case Failed(message):
				trace(message);
			case Cancelled:
		});

		var title = Node2D.text("HeliX stage2d", 20, 0xf5f5f5ff);
		title.setPosition(12, 32);
		hud.add(title);
	}

	override public function frame(dt:Float):Void {
		if (services.canQuit() && services.input.isFramePressed(Key.Escape))
			services.quit();
		time += dt;
		fps.update(dt, services.getFrameCpu());
		rock.setRotation(time * .6);
		box.setRotation(-time * .8);
		card.setRotation(-time * .8);
		sprite.setRotation(-time * .3);
		orbit.setRotation(time * 1.5);
		sparks.setPosition(Math.cos(time * 1.5) * 160, Math.sin(time * 1.5) * 80);
		world.setTime(time);
		var width = services.window.getFramebufferWidth(),
			height = services.window.getFramebufferHeight(),
			ratio = services.window.getPixelRatio();
		worldCamera.setViewport(width, height);
		worldCamera.setPosition(0, 0);
		worldCamera.setZoom(ratio * (1.25 + .25 * Math.sin(time * .5)));
		hudCamera.setViewport(width, height);
		hudCamera.pixels(ratio);

		services.graphics.beginFrame(width, height, 0x0c0e16ff);
		batch.begin(worldCamera);
		world.draw(batch, worldCamera);
		hud.draw(batch, hudCamera);
		Text2D.draw(batch,
			'immediate text, over the stages: ${world.getDrawnNodeCount()} world nodes drawn, ${services.graphics.getMsaaSamples()} of ${services.graphics.getMaxMsaaSamples()} MSAA samples a pixel',
			12, 60, 14, 0xc8c8c8ff);
		fps.draw(batch, 12, 10);
		batch.end();
		services.graphics.endFrame();
	}

	override public function cleanup():Void
		batch.destroy();
}
