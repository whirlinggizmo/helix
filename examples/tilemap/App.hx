import helix.app.BaseApp;
import helix.debug.FpsOverlay;
import helix.graphics.Sampling;
import helix.host.Services;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Node2D;
import helix.render2d.Stage2D;
import helix.render2d.Text2D;
import helix.render2d.Texture2D;

/** A scrolling tile map: one sprite sheet (textures/tiles.png), one Node2D sprite a cell cut out by its source region, on a Stage2D seen
	through a Camera2D in world units (a cell is 1 x 1, y down).
	- ground first, then props over it, in the order they were added
	- trees and flags are 16x32 in the sheet, drawn 1 x 2, and stand on their cell: their pivot is their bottom edge (0.5, 1)
	- drag or the arrow keys scroll; the wheel zooms (the world units seen top to bottom)
	- coins light up under the pointer, and a click (a press and a release on the same coin) collects them
	Only the cells in view are drawn (the stage culls), shown in the corner. Escape quits where quitting means anything. */
class App extends BaseApp {
	static inline var WORLD_W = 24;
	static inline var WORLD_H = 16;

	// Cells of the sheet in texels, x, y, width, height: each has a gutter repeating its edge, so sampling never reaches a neighbour.
	static var GRASS = [2, 2, 16, 16];
	static var SAND = [22, 2, 16, 16];
	static var WATER = [42, 2, 16, 16];
	static var STONE = [62, 2, 16, 16];
	static var TREE = [2, 22, 16, 32];
	static var FLAG = [22, 22, 16, 32];
	static var COIN = [42, 22, 16, 16];
	static var ROCK = [62, 22, 16, 16];

	var stage = new Stage2D();
	var batch:Batch2D;
	var camera = new Camera2D();
	var hud = new Camera2D();
	var fps = new FpsOverlay();
	var texture:Null<Texture2D>;
	var sprites:Array<Node2D> = [];
	var coins:Array<Node2D> = [];
	var collected = 0;
	var pressed:Null<Node2D>;
	var centerX = WORLD_W / 2;
	var centerY = WORLD_H / 2;
	var seen = 12.;
	var lastX = -1.;
	var lastY = -1.;

	// A sprite of one cell, placed at x, y in world units by its pivot, size width x height.
	function add(cell:Array<Int>, x:Float, y:Float, width:Float, height:Float, pivotX:Float, pivotY:Float):Node2D {
		var sprite = Node2D.sprite(texture);
		sprite.setRegion(cell[0], cell[1], cell[2], cell[3]);
		sprite.setSize(width, height);
		sprite.setPivot(pivotX, pivotY);
		sprite.setPosition(x, y);
		stage.add(sprite);
		sprites.push(sprite);
		return sprite;
	}

	// A small hand-made map: water along the bottom, a sand shore, stone paths.
	static function tileAt(x:Int, y:Int):Array<Int>
		return y >= WORLD_H - 2 ? WATER : y >= WORLD_H - 3 ? SAND : x == 8 || y == 6 ? STONE : GRASS;

	override public function init():Void {
		Services.window.setTitle("HeliX tilemap");
		Services.window.requestSize(960, 600);
		batch = new Batch2D(Services.graphics);
		// Tiles at whole units with their top-left as pivot: neighbours share their edges exactly, so no seam shows between them.
		for (y in 0...WORLD_H)
			for (x in 0...WORLD_W)
				add(tileAt(x, y), x, y, 1, 1, 0, 0);
		// Props stand on their cell: their pivot is their bottom middle, at the cell's bottom.
		for (i in 0...7)
			add(TREE, 2.5 + i * 3, 4 + i % 3, 1, 2, .5, 1);
		add(FLAG, 8.5, 7, 1, 2, .5, 1);
		for (i in 0...6)
			add(ROCK, 4.5 + i * 3.5, 12 - (i % 2) * 2, 1, 1, .5, 1);
		for (i in 0...8)
			coins.push(add(COIN, 3.5 + i * 2.5, 9 - i % 3, .8, .8, .5, 1));
		Services.textures.load("textures/tiles.png", false, result -> switch result {
			case Ready(loaded):
				// Pixel art: crisp texels when zoomed in.
				loaded.setSampling(Sampling.NEAREST);
				texture = loaded;
				for (sprite in sprites)
					sprite.setTexture(loaded);
			case Failed(message):
				trace(message);
			case Cancelled:
		});
	}

	// The coin under world point x, y, the topmost (the last added) first, inside its disc; null for none.
	function coinAt(x:Float, y:Float):Null<Node2D> {
		var i = coins.length;
		while (i-- > 0) {
			var coin = coins[i], r = coin.getWidth() / 2;
			var dx = x - coin.getX(), dy = y - (coin.getY() - r);
			if (coin.isVisible() && dx * dx + dy * dy <= r * r)
				return coin;
		}
		return null;
	}

	override public function frame(dt:Float):Void {
		var input = Services.input;
		if (Services.canQuit() && input.isFramePressed(Key.Escape))
			Services.quit();
		fps.update(dt, Services.getFrameCpu());
		var width = Services.window.getFramebufferWidth(),
			height = Services.window.getFramebufferHeight();
		var unitsPerPixel = seen / height;

		// Scroll: drag, or the arrow keys.
		var px = input.getPointerX(), py = input.getPointerY();
		if (input.isPointerDown() && lastX >= 0 && px >= 0) {
			centerX -= (px - lastX) * unitsPerPixel;
			centerY -= (py - lastY) * unitsPerPixel;
		}
		lastX = px;
		lastY = py;
		var speed = seen * .6 * dt;
		if (input.isDown(Key.Left))
			centerX -= speed;
		if (input.isDown(Key.Right))
			centerX += speed;
		if (input.isDown(Key.Up))
			centerY -= speed;
		if (input.isDown(Key.Down))
			centerY += speed;
		// Zoom: fewer world units seen is closer.
		seen = Math.max(4, Math.min(32, seen - input.getWheelY() * 1.5));
		centerX = Math.max(0, Math.min(WORLD_W, centerX));
		centerY = Math.max(0, Math.min(WORLD_H, centerY));
		camera.setViewport(width, height);
		camera.setZoom(height / seen);
		camera.setPosition(centerX, centerY);
		// The HUD in the design for the window's shape, along the top of what's visible of it; the world keeps its own camera.
		ScreenShape.update();
		var presentation = Services.presentation;
		presentation.apply(hud);
		var vx = presentation.getVisibleX(),
			vy = presentation.getVisibleY(),
			vw = presentation.getVisibleWidth();

		// Coins: hover lights them up, a click collects them.
		var hovered = px >= 0 ? coinAt(camera.screenToWorldX(px), camera.screenToWorldY(py)) : null;
		if (input.isPointerFramePressed())
			pressed = hovered;
		if (input.isPointerFrameReleased()) {
			if (pressed != null && pressed == hovered) {
				hovered.setVisible(false);
				collected++;
				hovered = null;
			}
			pressed = null;
		}
		for (coin in coins)
			coin.setColor(coin == hovered ? 0xffe68cff : 0xffffffff);

		Services.graphics.beginFrame(width, height, 0x181c26ff);
		batch.begin(camera);
		stage.draw(batch, camera);
		batch.setCamera(hud);
		// The text wrapped to what's visible, the band behind it as tall as it wraps to.
		var title = "HeliX tilemap: a 2D camera over sprite tiles",
			status = 'coins: $collected of 8   zoom: ${Math.round(seen * 10) / 10} units   center: ${Math.round(centerX * 10) / 10}, ${Math.round(centerY * 10) / 10}${texture == null ? "   (loading)" : ""}',
			help = 'drag or arrows to scroll, wheel to zoom, click the coins   (${stage.getDrawnNodeCount()} of ${sprites.length} drawn)';
		inline function tall(text:String, size:Float):Float
			return Text2D.measureWrapped(batch.getFont(), text, size, vw - 40);
		batch.rect(vx, vy, vw, 20 + tall(title, 20) + 1 + tall(status, 15) + 3 + tall(help, 15) + 1, 0x121418be);
		var y = vy + 20;
		y += Text2D.drawWrapped(batch, title, vx + 20, y, 20, vw - 40, 0xebeef5ff) + 1;
		y += Text2D.drawWrapped(batch, status, vx + 20, y, 15, vw - 40, 0x8c929eff) + 3;
		Text2D.drawWrapped(batch, help, vx + 20, y, 15, vw - 40, 0x8c929eff);
		fps.draw(batch, vx + vw - 150, vy + 4);
		batch.end();
		Services.graphics.endFrame();
	}

	override public function cleanup():Void
		batch.destroy();
}
