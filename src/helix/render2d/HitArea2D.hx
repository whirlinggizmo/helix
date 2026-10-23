package helix.render2d;

/** The shape a node is picked by in place of what it draws (Node2D.hitArea), in the node's own units, moving, turning and scaling with it;
	never drawn. For something clicked but not seen (a hotspot over a painting: a bare Node2D with one), a target easier to tap than its
	image, or one tighter than it. */
class HitArea2D {
	final round:Bool;
	final x:Float;
	final y:Float;
	final width:Float;
	final height:Float;

	function new(round:Bool, x:Float, y:Float, width:Float, height:Float) {
		this.round = round;
		this.x = x;
		this.y = y;
		this.width = width > 0 ? width : 0;
		this.height = height > 0 ? height : 0;
	}

	/** A rectangle width x height, its top-left at x, y (below 0 is 0), as Shape2D.rectangle places one. */
	public static function rectangle(x:Float, y:Float, width:Float, height:Float):HitArea2D
		return new HitArea2D(false, x, y, width, height);

	/** A circle of radius (below 0 is 0) centered on x, y, as Shape2D.circle places one. */
	public static function circle(x:Float, y:Float, radius:Float):HitArea2D
		return new HitArea2D(true, x, y, radius, radius);

	/** Whether its node's own point x, y is inside it, edges included. */
	public function contains(x:Float, y:Float):Bool {
		if (round) {
			var dx = x - this.x, dy = y - this.y;
			return dx * dx + dy * dy <= width * width;
		}
		return x >= this.x && x <= this.x + width && y >= this.y && y <= this.y + height;
	}
}
