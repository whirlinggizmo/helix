package helix.collision;

import haxe.ds.ObjectMap;

/** Which things might touch, before asking which do: items kept by their rectangle in cells of one size, and a rectangle's query giving the
	items in the cells it covers (each once), so a game tests a few pairs with Collide2D instead of every pair. Cells are about the size of
	a common item; a moved item is updated with its new rectangle. */
class SpatialHash2D<T:{}> {
	var cellSize:Float;
	var cells:Map<String, Array<T>> = [];
	var entries = new ObjectMap<T, Array<String>>();
	var stamps = new ObjectMap<T, Int>();
	var stamp = 0;
	var count = 0;

	/** Cells cellSize across and down. Throws for a size of 0 or less. */
	public function new(cellSize:Float) {
		if (!(cellSize > 0))
			throw 'A spatial hash\'s cell size must be over 0, not $cellSize';
		this.cellSize = cellSize;
	}

	/** Its cell size. */
	public function getCellSize():Float
		return cellSize;

	/** How many items it holds. */
	public function getCount():Int
		return count;

	/** Puts item in by its rectangle (an item already in is moved). */
	public function insert(item:T, x:Float, y:Float, width:Float, height:Float):Void {
		if (entries.exists(item))
			take(item);
		else
			count++;
		var keys = [];
		each(x, y, width, height, key -> {
			var list = cells[key];
			if (list == null)
				cells[key] = list = [];
			list.push(item);
			keys.push(key);
		});
		entries.set(item, keys);
	}

	/** Moves item to its new rectangle: insert again. */
	public function update(item:T, x:Float, y:Float, width:Float, height:Float):Void
		insert(item, x, y, width, height);

	/** Takes item out; false when it wasn't in. */
	public function remove(item:T):Bool {
		if (!entries.exists(item))
			return false;
		take(item);
		stamps.remove(item);
		count--;
		return true;
	}

	/** Takes everything out. */
	public function clear():Void {
		cells = [];
		entries = new ObjectMap();
		stamps = new ObjectMap();
		count = 0;
	}

	/** The items in the cells the rectangle covers, each once, into out (emptied first), which it returns: what might overlap it. */
	public function query(x:Float, y:Float, width:Float, height:Float, out:Array<T>):Array<T> {
		out.resize(0);
		stamp++;
		each(x, y, width, height, key -> {
			var list = cells[key];
			if (list == null)
				return;
			for (item in list)
				if (stamps.get(item) != stamp) {
					stamps.set(item, stamp);
					out.push(item);
				}
		});
		return out;
	}

	function take(item:T):Void {
		for (key in entries.get(item)) {
			var list = cells[key];
			list.remove(item);
			if (list.length == 0)
				cells.remove(key);
		}
		entries.remove(item);
	}

	// Every cell key the rectangle covers: a far edge on a cell's boundary stays in the cell before (touching isn't covering).
	function each(x:Float, y:Float, width:Float, height:Float, f:String->Void):Void {
		var c0 = Math.floor(x / cellSize),
			c1 = width > 0 ? Math.ceil((x + width) / cellSize) - 1 : c0;
		var r0 = Math.floor(y / cellSize),
			r1 = height > 0 ? Math.ceil((y + height) / cellSize) - 1 : r0;
		if (c1 < c0)
			c1 = c0;
		if (r1 < r0)
			r1 = r0;
		for (r in r0...r1 + 1)
			for (c in c0...c1 + 1)
				f(c + "," + r);
	}
}
