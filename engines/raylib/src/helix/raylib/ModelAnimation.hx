package helix.raylib;

/** Represents raylib's `ModelAnimation`: a skeleton's poses, frame by frame. `extras.Models.LoadModelAnimationsAsync` makes them, 60 frames a
	second; `Raylib.UpdateModelAnimation` poses a model by one. */
class ModelAnimation {
	/** Gets or sets the number of bones, which a model it moves has too (`Raylib.IsModelAnimationValid`). */
	public var boneCount:Int = 0;

	/** Gets or sets the number of frames. */
	public var frameCount:Int = 0;

	/** Gets or sets the bones, as the model's are. */
	public var bones:Null<Array<BoneInfo>> = null;

	/** Gets or sets each frame's pose: for each bone, its transform in the model, not its parent's (a parent's already in it). */
	public var framePoses:Null<Array<Array<Transform>>> = null;

	/** Gets or sets the name: the file's, cut to 31 bytes as raylib's holds it, or empty. */
	public var name:String = "";

	/** Creates an animation of no frames. */
	public function new() {}
}
