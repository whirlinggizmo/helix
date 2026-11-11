package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.internal.Animations;
import helix.raylib.internal.Models;
#end

/** Holds the rmodels calls raylib 6.0 adds, in its own name and signature. Each is written here, and `helix.raylib.Raylib6` forwards to
	each (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RModels6 {
	#if !macro
	/** Poses a model by two animations mixed by a blend, raylib 6.0's `UpdateModelAnimationEx`.

		Takes each animation at its frame as `UpdateModelAnimation` takes one, then mixes the two by the blend.

		Moves the bones and the vertices on the GPU or the CPU as `UpdateModelAnimation` does.

		Wraps a frame to its animation's frames before taking its fraction, as raylib's does, so a frame past the last holds the frame it
		wrapped to.

		Does nothing for a blend outside 0 to 1.

		@param model  The model.
		@param animA  The first animation.
		@param frameA  Its frame, fractional.
		@param animB  The second animation.
		@param frameB  Its frame, fractional.
		@param blend  How much of the second: 0 the first alone, 1 the second alone. */
	static function UpdateModelAnimationEx(model:Model, animA:ModelAnimation, frameA:Float, animB:ModelAnimation, frameB:Float, blend:Float):Void {
		Models.posable(model);
		if (model.boneMatrices == null)
			return;
		if (animA.frameCount > 0 && animA.framePoses != null && animB.frameCount > 0 && animB.framePoses != null && blend >= 0 && blend <= 1) {
			Animations.updateBonesEx(model, animA, frameA, animB, frameB, blend);
			helix.raylib.internal.Skinning.pose(model);
		}
	}
	#end
}
