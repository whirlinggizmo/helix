import helix.app.BaseApp;
import helix.debug.FpsOverlay;
import helix.graphics.Graphics;
import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.Input;
import helix.input.Key;
import helix.particles.Emitter;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Particles2D;
import helix.render2d.Stage2D;
import helix.render2d.Texture2D;
import helix.render2d.Textures;
import helix.render3d.Batch3D;
import helix.render3d.Camera3D;
import helix.render3d.Node3D;
import helix.render3d.Particles3D;
import helix.render3d.Stage3D;
import helix.time.Time;

/** Particle emitters (helix.particles.Emitter), drawn by the GPU from each particle's birth record and age. On a 3D stage: a fountain
	(blended drops under gravity), sparks (added, from a point circling the fountain: they trail behind it, are thrown along by it, slowed by
	drag, and stretched along their motion), and a campfire: flames (added puffs from a flipbook, colored by a curve) under smoke (blended,
	with size and color curves: a dark puff that spreads, lightens and fades as it rises). The steady ones are prewarmed, so they're already
	going. Click or tap for a burst of 2D confetti there, on a 2D stage over the 3D one: squares cut from the particle texture's middle (so their
	spin shows), each tinted by a color it picked from the palette. The camera turns slowly around the stage.

	Click or tap: confetti; Space: pause the steady emitters (the particles alive finish their lives); O: the camera; Escape: quit, where
	quitting means anything. */
class App extends BaseApp {
	static inline var ORBIT = 14;

	var stage:Stage3D;
	var flat = new Stage2D();
	var grid:Batch3D;
	var batch:Batch2D;
	var camera = new Camera3D();
	var hud = new Camera2D();
	var fps = new FpsOverlay();
	var fountain:Emitter;
	var sparks:Emitter;
	var smoke:Emitter;
	var flame:Emitter;
	var confetti:Emitter;
	var sparksNode:Node3D;
	var confettiNode:Particles2D;
	var paused = false;
	// The camera, circling.
	var orbit = new Orbit(ORBIT, 6, 0, 3, 0, .15);

	function place(emitter:Emitter, x:Float, y:Float, z:Float):Node3D {
		var node = new Particles3D(emitter);
		node.setPosition(x, y, z);
		stage.add(node);
		return node;
	}

	override public function init():Void {
		Window.title = "HeliX particles";
		Window.requestSize(1000, 600);
		var gpu = Graphics.instance;
		batch = new Batch2D(gpu);
		grid = new Batch3D(gpu);
		stage = new Stage3D(gpu);
		// Framed for 16:9: the fountain and the fire both in view on a phone held upright too.
		camera.minAspect = 16 / 9;

		fountain = new Emitter(null, 4096);
		fountain.rate = 1200;
		fountain.setLife(1.4, 1.9);
		fountain.setSpawnBox(.15, 0, .15);
		fountain.setVelocity(0, 9, 0, .22, .15);
		fountain.setGravity(0, -9.8, 0);
		fountain.setSize(.22, .12, .4);
		fountain.setColor(0x96d2ffe6, 0x3c78ff00);
		fountain.setAlphaMode(Blend);
		place(fountain, 0, .2, 0);
		fountain.prewarm(2);

		sparks = new Emitter(null, 2048);
		sparks.rate = 600;
		sparks.setLife(.5, 1.2);
		sparks.setVelocity(0, 4, 0, 1.2, .6);
		sparks.setGravity(0, -6, 0);
		sparks.drag = 1.5;
		sparks.inheritVelocity = .4;
		sparks.stretch = .04;
		sparks.setSize(.08, .02, .5);
		sparks.setColor(0xffdc78ff, 0xff3c0a00);
		sparksNode = place(sparks, 3.5, 1.5, 0);

		smoke = new Emitter(null, 512);
		smoke.rate = 30;
		smoke.setLife(3, 4.5);
		smoke.setSpawnSphere(.3);
		smoke.setVelocity(0, 1.4, 0, .35, .3);
		smoke.setGravity(.35, 0, 0);
		smoke.setSpin(-.8, .8);
		smoke.clearSizeKeys();
		smoke.addSizeKey(0, .3);
		smoke.addSizeKey(.15, 1.4);
		smoke.addSizeKey(1, 3.6);
		smoke.clearColorKeys();
		smoke.addColorKey(0, 0x28242200);
		smoke.addColorKey(.1, 0x322e2cbe);
		smoke.addColorKey(.5, 0x82828c78);
		smoke.addColorKey(1, 0xaaaab400);
		smoke.setAlphaMode(Blend);
		place(smoke, -5, 1.5, -2);
		smoke.prewarm(5);

		flame = new Emitter(null, 1024);
		flame.setFrames(4, 4);
		flame.rate = 40;
		flame.setLife(.7, 1.1);
		flame.setSpawnSphere(.3);
		flame.setVelocity(0, 1.8, 0, .2, .3);
		flame.drag = .8;
		flame.setSpin(-1.5, 1.5);
		flame.clearSizeKeys();
		flame.addSizeKey(0, .6);
		flame.addSizeKey(.3, 1.1);
		flame.addSizeKey(1, .4);
		flame.clearColorKeys();
		flame.addColorKey(0, 0xffebbe00);
		flame.addColorKey(.08, 0xffebbe6e);
		flame.addColorKey(.25, 0xff962864);
		flame.addColorKey(.65, 0xc8320f3c);
		flame.addColorKey(1, 0x500f0500);
		place(flame, -5, .3, -2);
		flame.prewarm(1);

		// The confetti, flat: on the 2D stage, in the presentation's units.
		confetti = new Emitter(null, 4096, true);
		confetti.setRegion(24, 24, 16, 16);
		confetti.setLife(1.2, 2.2);
		confetti.setVelocity(0, -420, 0, 1.3, .7);
		confetti.setGravity(0, 700, 0);
		confetti.drag = .8;
		confetti.setSize(12, 6, .5);
		confetti.setSpin(-8, 8);
		confetti.setColor(0xffffffff, 0xffffff00);
		for (c in [0xe62937ff, 0xffcb00ff, 0x00e430ff, 0x66bfffff, 0x873cbeff])
			confetti.addPaletteColor(c);
		confetti.setAlphaMode(Blend);
		confettiNode = new Particles2D(confetti);
		flat.add(confettiNode);

		Textures.load("textures/particle.png", true, texture -> dot(texture));
		Textures.load("textures/flame.png", true, texture -> flame.texture = texture);
	}

	// The particle texture in: every emitter but the flame draws it, and a first burst of confetti shows it.
	function dot(texture:Texture2D):Void {
		for (e in [fountain, sparks, smoke, confetti])
			e.texture = texture;
		var presentation = Screen.instance;
		burst(presentation.visibleX + presentation.visibleWidth / 2, presentation.visibleY + presentation.visibleHeight / 3);
	}

	// A burst of confetti at x, y units: no trail from where the last one was.
	function burst(x:Float, y:Float):Void {
		confettiNode.setPosition(x, y);
		confetti.jump(x, y, 0);
		confetti.burst(300);
	}

	override public function frame(dt:Float):Void {
		var input = Input.instance;
		if (Host.canQuit() && input.isFramePressed(Key.Escape))
			Host.quit();
		if (input.isFramePressed(Key.Space)) {
			paused = !paused;
			for (e in [fountain, sparks, smoke, flame])
				e.emitting = !paused;
		}
		if (input.isFramePressed(Key.O))
			orbit.running = !orbit.running;
		// The HUD and the confetti in the design for the window's shape; the pointer comes back in its units.
		ScreenShape.update();
		var presentation = Screen.instance;
		if (input.pointerFramePressed)
			burst(presentation.toUnitsX(input.pointerX), presentation.toUnitsY(input.pointerY));
		// The game's clock: paused, the motion stops.
		var time = Time.clock.time;
		orbit.update(dt);
		stage.time = time;
		flat.time = time;
		// The sparks' source circles the fountain; the sparks stay where they were born.
		sparksNode.setPosition(3.5 * Math.cos(time * 1.3), 1.5 + .8 * Math.sin(time * 2.1), 3.5 * Math.sin(time * 1.3));
		fps.update(dt, Time.frameCpu);
		var width = Window.framebufferWidth, height = Window.framebufferHeight;
		camera.setViewport(width, height);
		orbit.apply(camera);
		presentation.apply(hud);
		var vx = presentation.visibleX,
			vy = presentation.visibleY,
			vw = presentation.visibleWidth;

		Graphics.beginFrame(width, height, 0x0e1018ff);
		grid.begin(camera);
		grid.grid(24, 1, 0x50505aff);
		grid.end();
		stage.draw(camera);
		batch.begin(hud);
		flat.draw(batch, hud);
		var y = vy + 36;
		y += batch.drawTextWrapped("HeliX particles", vx + 12, y, 24, vw - 24, 0xf5f5f5ff) + 4;
		batch.drawTextWrapped('click / tap: confetti   space: ${paused ? "resume" : "pause"}   O: the camera   ${stage.drawCallCount} draws', vx + 12, y, 16,
			vw - 24, 0xc8c8c8ff);
		fps.draw(batch, vx + 12, vy + 10);
		batch.end();
		Graphics.endFrame();
	}

	override public function cleanup():Void {
		stage.destroy();
		grid.destroy();
		batch.destroy();
	}
}
