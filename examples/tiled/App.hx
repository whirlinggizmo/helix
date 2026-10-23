import helix.debug.FpsOverlay;
import helix.host.Host;
import helix.host.Screen;
import helix.host.ScreenShape;
import helix.host.Window;
import helix.input.Input;
import helix.input.Key;
import helix.input.MouseButton;
import helix.render2d.Drawing2D;
import helix.render2d.Stage;
import helix.tiled.TiledInstance2D;
import helix.tiled.TiledMap2D;
import helix.tiled.TiledTerrainSet2D;
import helix.tiled.TiledTileLayer2D;
import helix.time.Time;
import helix.ui.FullscreenButton2D;

/** A map made in Tiled (helix.tiled), read from its own files under assets/maps (island.tmj, its tileset ground.tsj and terrain.png, made
	by assets/gen_island.py and opened in Tiled as they are): an island of grass in water, its shore from a terrain set, coins turning (an
	animated tile), and its objects, a start point and a sign with a property, outlined over the map with their names and classes (an
	object layer is markers a game reads: TiledInstance2D.getObjects). The map is scaled to the visible area. The left button paints
	water and the right grass (TiledTileLayer2D.setTerrain: the cells round the pointer take the tiles that fit, as Tiled's Terrain brush);
	a click on a coin collects it (setTile). The cell under the pointer, its class and terrain are shown. Escape quits where quitting means
	anything. */
class App extends helix.App {
	var map:Null<TiledInstance2D>;
	var land:Null<TiledTileLayer2D>;
	var coins:Null<TiledTileLayer2D>;
	var terrain:Null<TiledTerrainSet2D>;
	var hud = new Drawing2D();
	var fps = new FpsOverlay();
	var fullscreen = new FullscreenButton2D();
	var collected = 0;
	var status = "loading the map";

	override public function init():Void {
		Window.title = "HeliX tiled";
		Window.requestSize(960, 600);
		Stage.color = 0xff14161c;
		Stage.addChild(hud);
		Stage.addChild(fps);
		Stage.addChild(fullscreen);
		TiledMap2D.load("maps/island.tmj", loaded -> show(loaded), message -> status = 'the map didn\'t load: $message');
	}

	// The map in: on the stage under the HUD, its layers found by name, its terrain set by its name in Tiled.
	function show(loaded:TiledMap2D):Void {
		if (loaded.backgroundColor != null)
			Stage.color = loaded.backgroundColor;
		var instance = loaded.instantiate();
		map = instance;
		land = instance.getTileLayer("land");
		coins = instance.getTileLayer("coins");
		terrain = loaded.findTerrainSet("land");
		var sign = instance.findObject("sign");
		status = sign != null ? 'the sign says "${sign.properties.getString("text")}"' : "";
		// Over the map.
		Stage.addChild(hud);
		Stage.addChild(fps);
		Stage.addChild(fullscreen);
	}

	override public function update(dt:Float):Void {
		if (Host.canQuit() && Input.isFramePressed(Key.Escape))
			Host.quit();
		fps.update(dt, Time.frameCpu);
		ScreenShape.update();
		var x = Screen.visibleX,
			y = Screen.visibleY,
			w = Screen.visibleWidth,
			h = Screen.visibleHeight;
		hud.clear();
		var line = 'HeliX tiled: a Tiled map, its terrain painted live   [LMB] water  [RMB] grass  click a coin   coins $collected';
		var instance = map;
		if (instance != null) {
			// The map fitted to the visible area under the text, centered, a whole number of screen pixels a map pixel where it fits.
			var mapWidth = instance.map.columns * instance.map.tileWidth,
				mapHeight = instance.map.rows * instance.map.tileHeight;
			var room = Math.min(w / mapWidth, (h - 70) / mapHeight) * .96;
			var scale = room >= 1 ? Math.floor(room) : room;
			instance.root.setScale(scale, scale);
			instance.root.setPosition(x + (w - mapWidth * scale) / 2, y + 60 + (h - 60 - mapHeight * scale) / 2);
			// The cell under the pointer, in the map's pixels.
			var px = Stage.camera.screenToWorldX(Input.pointerX),
				py = Stage.camera.screenToWorldY(Input.pointerY);
			var mx = instance.root.toLocalX(px, py),
				my = instance.root.toLocalY(px, py);
			// The object layer's markers: a dot for a point, a box for anything with a size, each with its name and class.
			for (object in instance.getObjects()) {
				var ox = instance.root.toWorldX(object.x, object.y),
					oy = instance.root.toWorldY(object.x, object.y);
				if (object.shape == Point)
					hud.circle(ox, oy, 5, 0xffff6060);
				else
					hud.frame(ox, oy, object.width * scale, object.height * scale, 2, 0xffff6060);
				hud.drawText('${object.name} (${object.className})', ox + 8, oy - 18, 14, 0xffffffff);
			}
			var ground = land, here = coins, set = terrain;
			if (ground != null && Input.pointerX >= 0 && !fullscreen.hovered) {
				var column = ground.columnAt(mx), row = ground.rowAt(my);
				if (column >= 0 && row >= 0 && column < ground.columns && row < ground.rows) {
					// A coin collected on a click; paint where there's none.
					if (here != null && here.isFilled(column, row) && Input.pointerFramePressed) {
						here.setTile(column, row, 0);
						collected++;
					} else if (set != null && Input.isMouseDown(MouseButton.Left))
						ground.setTerrain(column, row, set, set.findTerrain("water"));
					else if (set != null && Input.isMouseDown(MouseButton.Right))
						ground.setTerrain(column, row, set, set.findTerrain("grass"));
					var coin = here != null ? here.getTileClass(column, row) : "";
					line += '\ncell $column, $row: ${coin != "" ? coin : "no coin"}';
					hud.frame(instance.root.toWorldX(column * instance.map.tileWidth, row * instance.map.tileHeight),
						instance.root.toWorldY(column * instance.map.tileWidth, row * instance.map.tileHeight), instance.map.tileWidth * scale,
						instance.map.tileHeight * scale, 2, 0xc0ffffff);
				}
			}
		}
		if (status != "")
			line += '   $status';
		hud.drawTextWrapped(line, x + 12, y + 30, 16, w - 60, 0xffe8e8e8);
		fps.setPosition(x + 12, y + 8);
	}
}
