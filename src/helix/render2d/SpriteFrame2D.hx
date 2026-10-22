package helix.render2d;

/** One frame of a SpriteSheet2D: where it is in the sheet's texture and how it is drawn. A trimmed frame (its transparent edges cut off when packed)
	keeps its place in the whole picture: its texels are drawn offsetX, offsetY in from the top-left of a sourceWidth x sourceHeight box. A rotated
	frame was packed turned a quarter turn clockwise; it is drawn upright. */
class SpriteFrame2D {
	/** Its name in the sheet's file (a file name as packed: "run_01.png"), or its number in a grid. */
	public final name:String;

	/** Its texels' left in the texture, in texels. */
	public final x:Int;

	/** Its texels' top in the texture, in texels. */
	public final y:Int;

	/** Its texels' width as drawn (upright): in the texture, a rotated frame's height. */
	public final width:Int;

	/** Its texels' height as drawn (upright): in the texture, a rotated frame's width. */
	public final height:Int;

	/** Whether it was packed turned a quarter turn clockwise (TexturePacker's rotation). */
	public final rotated:Bool;

	/** How far its texels are from the left of the whole picture: what trimming cut off its left (0 untrimmed). */
	public final offsetX:Int;

	/** How far its texels are from the top of the whole picture: what trimming cut off its top (0 untrimmed). */
	public final offsetY:Int;

	/** The whole picture's width before trimming, in texels: the size it draws at. */
	public final sourceWidth:Int;

	/** The whole picture's height before trimming, in texels. */
	public final sourceHeight:Int;

	/** Its pivot as a fraction of the whole picture (0 its left, 1 its right), when its file gives one (TexturePacker's pivot), else NaN. */
	public final pivotX:Float;

	/** Its pivot as a fraction of the whole picture (0 its top, 1 its bottom), when its file gives one, else NaN. */
	public final pivotY:Float;

	/** How long it shows when its animation plays, in seconds. */
	public final duration:Float;

	/** A frame named name, its texels at x, y in the texture, width x height drawn upright (packed turned when rotated), offsetX, offsetY in from
		the top-left of a sourceWidth x sourceHeight picture, its pivot pivotX, pivotY (NaN for none), shown for duration seconds. */
	public function new(name:String, x:Int, y:Int, width:Int, height:Int, rotated:Bool, offsetX:Int, offsetY:Int, sourceWidth:Int, sourceHeight:Int,
			pivotX:Float, pivotY:Float, duration:Float) {
		this.name = name;
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
		this.rotated = rotated;
		this.offsetX = offsetX;
		this.offsetY = offsetY;
		this.sourceWidth = sourceWidth;
		this.sourceHeight = sourceHeight;
		this.pivotX = pivotX;
		this.pivotY = pivotY;
		this.duration = duration;
	}

	/** Whether its file gives it a pivot. */
	public var hasPivot(get, never):Bool;

	function get_hasPivot():Bool
		return !Math.isNaN(pivotX) && !Math.isNaN(pivotY);
}
