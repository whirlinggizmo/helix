package helix.scene.transition;

/** A round hole closing on a point and opening from it (Closing). */
class Iris extends Closing {
	/** An iris over seconds (half a second unless given) in color (black unless given, 0xAARRGGBB), on the middle of the visible area until
		setPoint. */
	public function new(seconds = .5, color = 0xff000000)
		super(seconds, color);

	override function reachOf(left:Float, top:Float, right:Float, bottom:Float):Float {
		var across = Math.max(left, right), down = Math.max(top, bottom);
		return Math.sqrt(across * across + down * down);
	}

	override function rim(cx:Float, cy:Float, size:Float):Array<Float> {
		var points = [], count = 64;
		for (i in 0...count) {
			var a = -i * Math.PI * 2 / count;
			points.push(cx + Math.cos(a) * size);
			points.push(cy + Math.sin(a) * size);
		}
		return points;
	}
}
