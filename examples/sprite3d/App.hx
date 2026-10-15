import helix.app.BaseApp;
import helix.debug.FpsOverlay;
import helix.host.Services;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Text2D;
import helix.render2d.Texture2D;
import helix.render3d.Batch3D;
import helix.render3d.Camera3D;
import helix.render3d.Light;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.Node;
import helix.render3d.Stage3D;

/** Textured sprites on a 3D stage, under a circling camera, over a grid (Batch3D) and a lit pedestal:
	- the logo, facing the camera as it circles, bobbing over the pedestal (blended by its alpha)
	- trees, cut from the tile sheet, upright: they turn to the camera about y only, and stand on their bottom edge (pivot 0.5, 1)
	- a flag on a sign post, as its node is turned (Free), and a coin flat on the ground (Ground)
	- the coin's glow, added over everything (Add), and masked flames that cut out where their texels fade
	Sprites are unlit and instanced: alike ones (a texture, an alpha mode) are one draw, and the readout counts them.
	O stops the camera; Escape quits where quitting means anything. */
class App extends BaseApp {
	var services:Services;
	var stage:Stage3D;
	var batch3D:Batch3D;
	var batch:Batch2D;
	var camera = new Camera3D();
	var hud = new Camera2D();
	var fps = new FpsOverlay();
	var logo:Node;
	var sign:Node;
	var orbit = true;
	var angle = 0.;
	var time = 0.;
	var trees:Array<Node> = [];
	var tileSprites:Array<Node> = [];
	var flames:Array<Node> = [];

	public function new(services:Services) {
		super();
		this.services = services;
	}

	// A sprite of the tile sheet's cell x, y, width x height texels, placed at x, z on the ground.
	function tile(cell:Array<Int>, x:Float, z:Float, width:Float, height:Float):Node {
		var sprite = Node.sprite(null);
		sprite.setRegion(cell[0], cell[1], cell[2], cell[3]);
		sprite.setSpriteSize(width, height);
		sprite.setPosition(x, 0, z);
		tileSprites.push(sprite);
		stage.add(sprite);
		return sprite;
	}

	override public function init():Void {
		services.window.setTitle("HeliX sprite3d");
		services.window.requestSize(1000, 600);
		var gpu = services.graphics;
		batch = new Batch2D(gpu);
		batch3D = new Batch3D(gpu);
		stage = new Stage3D(gpu);
		stage.setAmbient(0xffffffff, .3);
		var sunLight = new Light(Directional);
		sunLight.setIntensity(2.5);
		var sun = Node.light(sunLight);
		sun.lookAt(-.5, -1, -.3);
		stage.add(sun);
		var stone = new Material();
		stone.setBaseColor(0x8a8f99ff);
		stone.setRoughness(.8);
		var pedestal = Node.model(Mesh.cylinder(.6, 1), stone);
		pedestal.setPosition(0, .5, 0);
		stage.add(pedestal);

		logo = Node.sprite(null);
		logo.setSpriteSize(1.6, 1.6);
		stage.add(logo);
		// Trees: upright, standing on their bottom edge.
		for (i in 0...6) {
			var a = i / 6 * Math.PI * 2 + .3;
			var tree = tile([2, 22, 16, 32], Math.cos(a) * 4, Math.sin(a) * 4, 1.2, 2.4);
			tree.setFacing(Upright);
			tree.setPivot(.5, 1);
			tree.setAlphaMode(Mask, .5);
			trees.push(tree);
		}
		// A flag on a post, turned as its node is: a sign.
		sign = tile([22, 22, 16, 32], 2, -1.5, 1, 2);
		sign.setFacing(Free);
		sign.setPivot(.5, 1);
		sign.setAlphaMode(Mask);
		// A coin lying on the ground, and its glow added over it.
		var coin = tile([42, 22, 16, 16], -2, 1.5, .8, .8);
		coin.setFacing(Ground);
		coin.setPosition(-2, .02, 1.5);
		coin.setAlphaMode(Mask);
		services.textures.load("sprites/logo/wg-logo-white-alpha.png", true, result -> switch result {
			case Ready(texture):
				logo.setTexture(texture);
				logo.setTint(0x66bfffff);
			case Failed(message):
				trace(message);
			case Cancelled:
		});
		services.textures.load("textures/tiles.png", false, result -> switch result {
			case Ready(texture):
				for (sprite in tileSprites)
					sprite.setTexture(texture);
			case Failed(message):
				trace(message);
			case Cancelled:
		});
		// Masked flames, cut out where their soft edges fade: a row of them behind the pedestal.
		services.textures.load("textures/flame.png", true, result -> switch result {
			case Ready(texture):
				for (i in 0...5) {
					var flame = Node.sprite(texture, 0xffa040ff);
					flame.setRegion(0, 0, 64, 64);
					flame.setSpriteSize(.9, .9);
					flame.setPivot(.5, 1);
					flame.setFacing(Upright);
					flame.setAlphaMode(Mask, .4);
					flame.setPosition(i * .8 - 1.6, 0, -2.5);
					flames.push(flame);
					stage.add(flame);
				}
				// The coin's glow: a soft puff of the same sheet, gold, added over everything.
				var glow = Node.sprite(texture, 0xffd25aff);
				glow.setRegion(0, 0, 64, 64);
				glow.setSpriteSize(1.4, 1.4);
				glow.setPosition(-2, .5, 1.5);
				glow.setAlphaMode(Add);
				stage.add(glow);
			case Failed(message):
				trace(message);
			case Cancelled:
		});
	}

	override public function frame(dt:Float):Void {
		var input = services.input;
		if (services.canQuit() && input.isFramePressed(Key.Escape))
			services.quit();
		if (input.isFramePressed(Key.O))
			orbit = !orbit;
		time += dt;
		if (orbit)
			angle += dt * .3;
		fps.update(dt, services.getFrameCpu());
		logo.setPosition(0, 2.1 + Math.sin(time * 2) * .2, 0);
		sign.setRotation(0, Math.sin(time) * .8, 0);
		var width = services.window.getFramebufferWidth(),
			height = services.window.getFramebufferHeight();
		camera.setViewport(width, height);
		camera.setView(Math.sin(angle) * 8, 3.5, Math.cos(angle) * 8, 0, 1, 0);
		hud.setViewport(width, height);
		hud.pixels(services.window.getPixelRatio());

		services.graphics.beginFrame(width, height, 0x1c1e26ff);
		batch3D.begin(camera);
		batch3D.grid(16, 1, 0x3c3f48ff);
		batch3D.end();
		stage.draw(camera);
		batch.begin(hud);
		Text2D.draw(batch, "HeliX sprite3d: sprites facing the camera, upright, flat and free; masked, blended and added", 12, 36, 18, 0xf5f5f5ff);
		Text2D.draw(batch, '${stage.getDrawnNodeCount()} models and sprites in ${stage.getDrawCallCount()} draws   O: the camera', 12, 62, 16, 0xc8c8c8ff);
		fps.draw(batch, 12, 10);
		batch.end();
		services.graphics.endFrame();
	}

	override public function cleanup():Void {
		stage.destroy();
		batch3D.destroy();
		batch.destroy();
	}
}
