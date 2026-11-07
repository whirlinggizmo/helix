package helix.raylib;

/** Represents raylib's `ModelAnimation`: a skeleton's poses, frame by frame.

	`extras.Models.LoadModelAnimationsAsync` makes them at 60 frames a second.

	`Raylib.UpdateModelAnimation` poses a model by one. */
class ModelAnimation {
	/** Gets or sets the number of bones. A model the animation moves has the same number (`Raylib.IsModelAnimationValid`). */
	public var boneCount:Int = 0;

	/** Gets or sets the number of frames. */
	public var frameCount:Int = 0;

	/** Gets or sets the bones, as the model's are. */
	public var bones:Null<Array<BoneInfo>> = null;

	/** Gets or sets each frame's pose: for each bone, its transform in the model, not relative to its parent (the parent's is already in
		it). */
	public var framePoses:Null<Array<Array<Transform>>> = null;

	/** Gets or sets the name, the file's cut to 31 bytes as raylib's holds it, or empty. */
	public var name:String = "";

	/** Creates an animation of no frames. */
	public function new() {}
}
