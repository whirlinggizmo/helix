/** Where things sit, in world units of one cell. Portrait stacks the panels above the field; landscape puts them beside it. */
class Layout {
	public var portrait(default, null) = true;
	public var worldWidth(default, null) = 0.;
	public var worldHeight(default, null) = 0.;
	public var fieldX(default, null) = 0.;
	public var fieldY(default, null) = 0.;
	public var holdBox(default, null):Array<Float>;
	public var nextBox(default, null):Array<Float>;
	public var pauseBox(default, null):Array<Float>;
	public var scoreX(default, null) = 0.;
	public var scoreY(default, null) = 0.;

	public function new() {
		update(1, 2);
	}

	public function update(width:Int, height:Int):Void {
		portrait = height > width * 1.2;
		if (portrait) {
			worldWidth = 12;
			worldHeight = 26;
			fieldX = 1;
			fieldY = 5.5;
			holdBox = [1, .5, 3, 3.2];
			nextBox = [8, .5, 3, 3.2];
			pauseBox = [5, 3.3, 2, 1.6];
			scoreX = 6;
			scoreY = .6;
		} else {
			worldWidth = 26;
			worldHeight = 22;
			fieldX = 8;
			fieldY = 1;
			holdBox = [2.5, 1, 4, 3.6];
			nextBox = [19.5, 1, 4, 9];
			pauseBox = [19.5, 18, 4, 3];
			scoreX = 4.5;
			scoreY = 6.5;
		}
	}

	public static function inside(box:Array<Float>, x:Float, y:Float):Bool
		return x >= box[0] && x < box[0] + box[2] && y >= box[1] && y < box[1] + box[3];
}
