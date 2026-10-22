package helix.render2d;

/** A named run of a SpriteSheet2D's frames, played by a SpriteAnimator2D: an Aseprite tag, or frames whose names differ only by a number. Each frame
	shows for its own duration. */
class SpriteAnimation2D {
	/** Its name: the tag's, or the frames' names without their numbers ("run_01.png" -> "run"). */
	public final name:String;

	/** The sheet's frames it shows, by index, in order. */
	public final frames:Array<Int>;

	/** Which way it plays through them. */
	public final direction:AnimationDirection2D;

	/** An animation named name over the sheet's frames, played in direction. */
	public function new(name:String, frames:Array<Int>, direction:AnimationDirection2D) {
		this.name = name;
		this.frames = frames;
		this.direction = direction;
	}
}
