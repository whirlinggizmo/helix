package helix.tiled;

/** A frame of an animated tile: which tile of its tileset shows, for how long. */
class TiledFrame2D {
	@:allow(helix.tiled)
	function new(tile:Int, seconds:Float) {
		this.tile = tile;
		this.seconds = seconds;
	}

	/** The tile shown, its id in the tileset. */
	public var tile(default, null):Int;

	/** How long it shows, seconds. */
	public var seconds(default, null):Float;
}
