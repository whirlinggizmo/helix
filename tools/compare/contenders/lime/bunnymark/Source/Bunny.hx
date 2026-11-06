package;

/** A bunny, as raylib's bunnymark has it: a position, a speed in pixels a frame, and a tint. */
class Bunny {
	public var x:Float;
	public var y:Float;
	public var speedX:Float;
	public var speedY:Float;
	public var r:Float;
	public var g:Float;
	public var b:Float;

	public function new(x:Float, y:Float, speedX:Float, speedY:Float, r:Float, g:Float, b:Float) {
		this.x = x;
		this.y = y;
		this.speedX = speedX;
		this.speedY = speedY;
		this.r = r;
		this.g = g;
		this.b = b;
	}
}
