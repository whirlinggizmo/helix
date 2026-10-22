package helix.render2d;

/** A named run of a SpriteSheet's frames, played by a SpriteAnimator: an Aseprite tag, or frames whose names differ only by a number. Each frame
	shows for its own duration. */
class SpriteAnimation {
	/** Its name: the tag's, or the frames' names without their numbers ("run_01.png" -> "run"). */
	public final name:String;

	/** The sheet's frames it shows, by index, in order. */
	public final frames:Array<Int>;

	/** Which way it plays through them. */
	public final direction:AnimationDirection;

	/** An animation named name over the sheet's frames, played in direction. */
	public function new(name:String, frames:Array<Int>, direction:AnimationDirection) {
		this.name = name;
		this.frames = frames;
		this.direction = direction;
	}
}
