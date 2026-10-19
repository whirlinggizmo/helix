package helix.shaders;

/** Pixelate, a screen effect of the library: the frame in square cells, each one color, the frame's at the cell's middle. */
class Pixelate extends LibraryScreenEffect {
	/** Cells cellSize pixels a side. */
	public function new(cellSize = 6) {
		super("pixelate", PixelatePacked.text());
		this.cellSize = cellSize;
	}

	/** A cell's side, in the frame's pixels, 1 (the frame as it is) to 256: 6 by default. */
	public var cellSize(default, set):Int;

	function set_cellSize(value:Int):Int {
		cellSize = value > 1 ? (value < 256 ? value : 256) : 1;
		parameters.setFloat("cell_size", cellSize);
		return cellSize;
	}
}
