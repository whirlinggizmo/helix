package helix.math;

/** Provides the distance transform of a grid: for each cell, the squared distance to the nearest cell that is 0, by Felzenszwalb and
	Huttenlocher's method, in time proportional to the cells. Two transforms, one from inside a shape and one from outside it, make a
	signed distance field. */
class DistanceField2D {
	/** Transforms a grid in place: each cell becomes its squared distance, in cells, to the nearest cell that was 0.

		Cells start at 0 where distances are measured from, and large (1e20) everywhere else.
		@param grid  The cells, row by row, `width * height` of them.
		@param width  The cells in a row.
		@param height  The rows. */
	public static function transform(grid:Array<Float>, width:Int, height:Int):Void {
		var n = width > height ? width : height;
		var f = [for (_ in 0...n) 0.],
			d = [for (_ in 0...n) 0.],
			z = [for (_ in 0...n + 1) 0.],
			v = [for (_ in 0...n) 0];
		for (x in 0...width) {
			for (y in 0...height)
				f[y] = grid[y * width + x];
			line(f, d, v, z, height);
			for (y in 0...height)
				grid[y * width + x] = d[y];
		}
		for (y in 0...height) {
			for (x in 0...width)
				f[x] = grid[y * width + x];
			line(f, d, v, z, width);
			for (x in 0...width)
				grid[y * width + x] = d[x];
		}
	}

	// One row or column: the lower envelope of the parabolas rooted at each cell.
	static function line(f:Array<Float>, d:Array<Float>, v:Array<Int>, z:Array<Float>, n:Int):Void {
		var k = 0;
		v[0] = 0;
		z[0] = -1e20;
		z[1] = 1e20;
		for (q in 1...n) {
			var s = ((f[q] + q * q) - (f[v[k]] + v[k] * v[k])) / (2 * q - 2 * v[k]);
			while (s <= z[k]) {
				k--;
				s = ((f[q] + q * q) - (f[v[k]] + v[k] * v[k])) / (2 * q - 2 * v[k]);
			}
			k++;
			v[k] = q;
			z[k] = s;
			z[k + 1] = 1e20;
		}
		k = 0;
		for (q in 0...n) {
			while (z[k + 1] < q)
				k++;
			d[q] = (q - v[k]) * (q - v[k]) + f[v[k]];
		}
	}
}
