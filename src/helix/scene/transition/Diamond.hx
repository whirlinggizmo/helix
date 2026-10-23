package helix.scene.transition;

/** A diamond-shaped hole closing on a point and opening from it (Closing). */
class Diamond extends Closing {
	/** A diamond over seconds (half a second unless given) in color (black unless given, 0xAARRGGBB), on the middle of the visible area
		until setPoint. */
	public function new(seconds = .5, color = 0xff000000)
		super(seconds, color);

	override function reachOf(left:Float, top:Float, right:Float, bottom:Float):Float
		return Math.max(left, right) + Math.max(top, bottom);

	override function rim(cx:Float, cy:Float, size:Float):Array<Float>
		return [cx + size, cy, cx, cy - size, cx - size, cy, cx, cy + size];
}
