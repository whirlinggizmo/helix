package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.internal.Animations;
import helix.raylib.internal.Models;
import helix.raylib.internal.Runtime;
#end

/** Holds helix-raylib's blend of two animations bone by bone, which raylib 6.0's `UpdateModelAnimationEx` makes over the whole body. Each
	is written here, and `helix.raylib.extras.Models` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RModelsMasked {
	#if !macro
	/** Poses a model by two animations, each bone mixing in the second by its weight in a mask: a bone weighted 1 mixes in the second by
		`blend`, one weighted 0 the first alone. An attack in the second over a run in the first, with a mask of the upper body
		(`GetModelBoneMask`), poses the upper body by the attack and the legs by the run.

		By default (`BLEND_ROTATION_LOCAL`), the masked bones turn with the mask root's parent as the first animation poses it. With
		`BLEND_ROTATION_MODEL`, the masked bones keep the second animation's facing, and the mask root twists from its parent as much as
		the two animations' facings differ.

		Wraps a frame to its animation's frames before using its fraction, as `UpdateModelAnimationEx` does.

		Refused for a mask or an animation that doesn't match the bones of the blended model.

		@param model  The model.
		@param animA  The first animation, posing the unmasked bones.
		@param frameA  The first animation's frame, fractional.
		@param animB  The second animation, posing the masked bones.
		@param frameB  The second animation's frame, fractional.
		@param boneWeights  The second animation's influence on each bone, in [0, 1], by the bone's index in the model's bones.
		@param blend  The second animation's influence on the masked bones, clamped to [0, 1].
		@param rotationSpace  Optional. `BLEND_ROTATION_LOCAL` or `BLEND_ROTATION_MODEL`, defaults to `BLEND_ROTATION_LOCAL`. */
	static function UpdateModelAnimationMasked(model:Model, animA:ModelAnimation, frameA:Float, animB:ModelAnimation, frameB:Float, boneWeights:Array<Float>,
			blend:Float, rotationSpace:Int = 0):Void {
		if (rotationSpace < 0 || rotationSpace > 1) {
			Runtime.log(4, 'MODEL: UpdateModelAnimationMasked: $rotationSpace is not a BLEND_ROTATION_ value');
			return;
		}
		Models.posable(model);
		if (model.boneMatrices == null)
			return;
		if (Animations.updateBonesMasked(model, animA, frameA, animB, frameB, boneWeights, blend, rotationSpace))
			helix.raylib.internal.Skinning.pose(model);
	}

	/** Returns a mask of a named bone and every bone below it, each weighted 1, and the others 0, by index in the model's bones, as
		`UpdateModelAnimationMasked` accepts it. Every bone is 0 when the model has no bone of the name. A mask of another shape (two
		branches, weights between 0 and 1) is an array the program fills itself.

		@param model  The model.
		@param maskRootBoneName  The mask's root: it and every bone below it are weighted 1.
		@param out  The array to fill, its length made the model's count of bones, or null for a new one.
		@return  out, or the new array: a weight a bone. */
	static function GetModelBoneMask(model:Model, maskRootBoneName:String, ?out:Array<Float>):Array<Float> {
		var count = model.bones == null ? 0 : model.boneCount;
		if (out == null)
			out = [];
		out.resize(count);
		var root = -1;
		for (i in 0...count)
			if (model.bones[i].name == maskRootBoneName) {
				root = i;
				break;
			}
		// Parents come before their children, as the model's bones are put in place.
		for (i in 0...count) {
			var parent = model.bones[i].parent;
			out[i] = i == root || (root >= 0 && parent >= 0 && parent < i && out[parent] == 1) ? 1 : 0;
		}
		return out;
	}
	#end
}
