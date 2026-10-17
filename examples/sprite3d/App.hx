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
import helix.render2d.Texture2D;
import helix.render2d.Textures;
import helix.render3d.Batch3D;
import helix.render3d.Camera3D;
import helix.render3d.DirectionalLight;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.Model;
import helix.render3d.Sprite3D;
import helix.render3d.Stage3D;
import helix.time.Time;

/** Textured sprites on a 3D stage, under a circling camera, over a grid (Batch3D) and a lit pedestal:
	- the logo, facing the camera as it circles, bobbing over the pedestal (blended by its alpha)
	- trees, cut from the tile sheet, upright: they turn to the camera about y only, and stand on their bottom edge (pivot 0.5, 1)
	- a flag on a sign post, as its node is turned (Free), and a coin flat on the ground (Ground)
	- the coin's glow, added over everything (Add), and masked flames that cut out where their texels fade
	Sprites are unlit and instanced: alike ones (a texture, an alpha mode) are one draw, and the readout counts them.
	O stops the camera; Escape quits where quitting means anything. */
class App extends BaseApp {
	var stage:Stage3D;
	var batch3D:Batch3D;
	var batch:Batch2D;
	var camera = new Camera3D();
	var hud = new Camera2D();
	var fps = new FpsOverlay();
	var logo:Sprite3D;
	var sign:Sprite3D;
	// The camera, circling.
	var orbit = new Orbit(8, 3.5, 0, 1, 0, .3);
	var trees:Array<Sprite3D> = [];
	var tileSprites:Array<Sprite3D> = [];
	var flames:Array<Sprite3D> = [];

	// A sprite of the tile sheet's cell x, y, width x height texels, placed at x, z on the ground.
	function tile(cell:Array<Int>, x:Float, z:Float, width:Float, height:Float):Sprite3D {
		var sprite = new Sprite3D(null);
		sprite.setRegion(cell[0], cell[1], cell[2], cell[3]);
		sprite.setSpriteSize(width, height);
		sprite.setPosition(x, 0, z);
		tileSprites.push(sprite);
		stage.add(sprite);
		return sprite;
	}

	override public function init():Void {
		Window.title = "HeliX sprite3d";
		Window.requestSize(1000, 600);
		// Framed for 16:9: the pedestal and the trees around it on a phone held upright too.
		camera.minAspect = 16 / 9;
		var gpu = Graphics.instance;
		batch = new Batch2D(gpu);
		batch3D = new Batch3D(gpu);
		stage = new Stage3D(gpu);
		stage.setAmbient(0xffffffff, .3);
		var sun = new DirectionalLight();
		sun.intensity = 2.5;
		sun.lookAt(-.5, -1, -.3);
		stage.add(sun);
		var stone = new Material();
		stone.baseColor = 0x8a8f99ff;
		stone.roughness = .8;
		var pedestal = new Model(Mesh.cylinder(.6, 1), stone);
		pedestal.setPosition(0, .5, 0);
		stage.add(pedestal);

		logo = new Sprite3D(null);
		logo.setSpriteSize(1.6, 1.6);
		stage.add(logo);
		// Trees: upright, standing on their bottom edge.
		for (i in 0...6) {
			var a = i / 6 * Math.PI * 2 + .3;
			var tree = tile([2, 22, 16, 32], Math.cos(a) * 4, Math.sin(a) * 4, 1.2, 2.4);
			tree.facing = Upright;
			tree.setPivot(.5, 1);
			tree.setAlphaMode(Mask, .5);
			trees.push(tree);
		}
		// A flag on a post, turned as its node is: a sign.
		sign = tile([22, 22, 16, 32], 2, -1.5, 1, 2);
		sign.facing = Free;
		sign.setPivot(.5, 1);
		sign.setAlphaMode(Mask);
		// A coin lying on the ground, and its glow added over it.
		var coin = tile([42, 22, 16, 16], -2, 1.5, .8, .8);
		coin.facing = Ground;
		coin.setPosition(-2, .02, 1.5);
		coin.setAlphaMode(Mask);
		Textures.load("sprites/logo/wg-logo-white-alpha.png", true, texture -> useLogo(texture));
		Textures.load("textures/tiles.png", false, texture -> useTiles(texture));
		Textures.load("textures/flame.png", true, texture -> light(texture));
	}

	// The logo's texture in: the billboard draws it, tinted blue.
	function useLogo(texture:Texture2D):Void {
		logo.texture = texture;
		logo.tint = 0x66bfffff;
	}

	// The tile sheet in: every tile sprite draws its cell of it.
	function useTiles(texture:Texture2D):Void
		for (sprite in tileSprites)
			sprite.texture = texture;

	// The flame sheet in: masked flames, cut out where their soft edges fade, a row of them behind the pedestal, and the coin's glow.
	function light(texture:Texture2D):Void {
		for (i in 0...5) {
			var flame = new Sprite3D(texture, 0xffa040ff);
			flame.setRegion(0, 0, 64, 64);
			flame.setSpriteSize(.9, .9);
			flame.setPivot(.5, 1);
			flame.facing = Upright;
			flame.setAlphaMode(Mask, .4);
			flame.setPosition(i * .8 - 1.6, 0, -2.5);
			flames.push(flame);
			stage.add(flame);
		}
		// The coin's glow: a soft puff of the same sheet, gold, added over everything.
		var glow = new Sprite3D(texture, 0xffd25aff);
		glow.setRegion(0, 0, 64, 64);
		glow.setSpriteSize(1.4, 1.4);
		glow.setPosition(-2, .5, 1.5);
		glow.setAlphaMode(Add);
		stage.add(glow);
	}

	override public function frame(dt:Float):Void {
		var input = Input.instance;
		if (Host.canQuit() && input.isFramePressed(Key.Escape))
			Host.quit();
		if (input.isFramePressed(Key.O))
			orbit.running = !orbit.running;
		// The game's clock: paused, the motion stops.
		var time = Time.clock.time;
		orbit.update(dt);
		fps.update(dt, Time.frameCpu);
		logo.setPosition(0, 2.1 + Math.sin(time * 2) * .2, 0);
		sign.setRotation(0, Math.sin(time) * .8, 0);
		var width = Window.framebufferWidth, height = Window.framebufferHeight;
		camera.setViewport(width, height);
		orbit.apply(camera);
		// The text in the design for the window's shape, wrapped to what's visible of it.
		ScreenShape.update();
		var presentation = Screen.instance;
		presentation.apply(hud);
		var vx = presentation.visibleX,
			vy = presentation.visibleY,
			vw = presentation.visibleWidth;

		Graphics.beginFrame(width, height, 0x1c1e26ff);
		batch3D.begin(camera);
		batch3D.grid(16, 1, 0x3c3f48ff);
		batch3D.end();
		stage.draw(camera);
		batch.begin(hud);
		var y = vy + 36;
		y += batch.drawTextWrapped("HeliX sprite3d: sprites facing the camera, upright, flat and free; masked, blended and added", vx + 12, y, 18, vw - 24,
			0xf5f5f5ff)
			+ 4;
		batch.drawTextWrapped('${stage.drawnNodeCount} models and sprites in ${stage.drawCallCount} draws   O: the camera', vx + 12, y, 16, vw - 24,
			0xc8c8c8ff);
		fps.draw(batch, vx + 12, vy + 10);
		batch.end();
		Graphics.endFrame();
	}

	override public function cleanup():Void {
		stage.destroy();
		batch3D.destroy();
		batch.destroy();
	}
}
