package helix.raylib.extras;

/** Provides what raylib has no call for on models: a model's bounds as posed, which raylib's `GetModelBoundingBox` leaves at the bind
	pose (`GetModelBoundingBoxPosed`), models merged into one (`LoadModelFromModels`), and two animations blended bone by bone
	(`UpdateModelAnimationMasked`, `GetModelBoneMask`). Imported apart: `import helix.raylib.extras.Models.*;`. */
class Models {
	// ---- How UpdateModelAnimationMasked turns each weighted bone ----

	/** The masked bones turn with the mask root's parent. The default. */
	public static inline final BLEND_ROTATION_LOCAL = 0;

	/** The masked bones keep the second animation's facing. */
	public static inline final BLEND_ROTATION_MODEL = 1;


	/** Returns a model's bounds as its last `UpdateModelAnimation` (or `UpdateModelAnimationEx`) posed it: `GetModelBoundingBox`'s box,
		each skinned mesh bounded by its vertices where its bones put them rather than where the skin was bound. A mesh never posed, or
		without bones, counts as it is, and so does a vertex no bone weights. It is exact whatever shader draws the mesh, as it works the positions out from the pose itself,
		allocating nothing; that is each skinned vertex moved by its bones, on the CPU, each call. As `GetModelBoundingBox`, its least and
		most corners are then moved by the model's transform (a turned model's box is not its bounds).

		@param model  The model.
		@return  The box. */
	public static function GetModelBoundingBoxPosed(model:Model):BoundingBox;


	/** Returns a new model with the provided models' meshes merged where possible. The provided models are unchanged. For example, a
		character's head, body, legs and feet models, whose materials differ only in color, are merged into one character model with one
		mesh.

		Meshes whose materials differ only in diffuse color are merged into one mesh. Each material's diffuse color is multiplied into the
		vertex colors, and the merged mesh has one material, the same material with a white diffuse color. Meshes whose materials differ in
		anything else (the shader, a texture, `unlit`, or another map's color or value) stay separate meshes.

		A shader that ignores the vertex color draws a merged mesh without the materials' colors.

		A mesh lacking normals, texture coordinates or colors that another merged mesh has gets normals (0, 0, 1), texture coordinates
		(0, 0) and white colors. Tangents are kept when every merged mesh has them. `texcoords2` is dropped.

		With `skeleton`, the new model has the bones, bind pose and transform of `skeleton`, and an animation that poses `skeleton` poses
		the new model. Each provided model's bones are matched to the bones of `skeleton` by name. A vertex following a bone that `skeleton`
		lacks follows the nearest ancestor of that bone that `skeleton` has. A vertex with no such ancestor stays where it is when the new
		model is posed. A provided model bound in another bind pose is rebound to the bind pose of `skeleton`. A vertex following several
		bones whose bind poses differ by different amounts is rebound approximately. A provided model without bones is placed where its
		transform put it.

		Without `skeleton`, the new model has no bones and the identity transform. Each provided model's transform is multiplied into the
		model's vertices, and a provided model with bones is merged at its bind pose.

		The merged meshes are uploaded. Refused, with the reason logged, for an empty list, for a provided model with bones whose transform
		differs from the transform of `skeleton`, and for a `skeleton` of more than 256 bones.

		@param models  The models.
		@param skeleton  Optional. The model whose bones, bind pose and transform the new model takes. Usually one of the provided models.
		@return  The new model, or null when refused. */
	public static function LoadModelFromModels(models:Array<Model>, ?skeleton:Model):Null<Model>;


	/** Poses a model by two animations, each bone taking the second by its weight in a mask: a bone weighted 1 takes the second by
		`blend`, one weighted 0 the first alone. An attack in the second over a run in the first, with a mask of the upper body
		(`GetModelBoneMask`), poses the upper body by the attack and the legs by the run.

		By default (`BLEND_ROTATION_LOCAL`), the masked bones turn with the mask root's parent as the first animation poses it. With
		`BLEND_ROTATION_MODEL`, the masked bones keep the second animation's facing, and the mask root twists from its parent as much as
		the two animations' facings differ.

		Wraps a frame to its animation's frames before taking its fraction, as `UpdateModelAnimationEx` does.

		Refused for a blend outside 0 to 1. Refused, with the reason logged, for a mask or an animation of another count of bones than
		the model's, and for a rotation space that isn't a `BLEND_ROTATION_` value.

		@param model  The model.
		@param animA  The first animation, posing the bones the mask leaves out.
		@param frameA  Its frame, fractional.
		@param animB  The second animation, posing the bones the mask weights.
		@param frameB  Its frame, fractional.
		@param boneWeights  Each bone's share of the second animation, 0 to 1, by its index in the model's bones.
		@param blend  How much of the second the weighted bones take: 0 the first alone, 1 the second as weighted.
		@param rotationSpace  Optional. How each weighted bone is turned: `BLEND_ROTATION_LOCAL` when omitted, or `BLEND_ROTATION_MODEL`. */
	public static function UpdateModelAnimationMasked(model:Model, animA:ModelAnimation, frameA:Float, animB:ModelAnimation, frameB:Float,
			boneWeights:Array<Float>, blend:Float, rotationSpace:Int = 0):Void;

	/** Returns a mask of a named bone and every bone below it, each weighted 1, and the others 0, by index in the model's bones, as
		`UpdateModelAnimationMasked` takes it. Every bone is 0 when the model has no bone of the name. A mask of another shape (two branches,
		weights between 0 and 1) is an array the program fills itself.

		@param model  The model.
		@param maskRootBoneName  The mask's root: it and every bone below it are weighted 1.
		@param out  The array to fill, its length made the model's count of bones, or null for a new one.
		@return  out, or the new array: a weight a bone. */
	public static function GetModelBoneMask(model:Model, maskRootBoneName:String, ?out:Array<Float>):Array<Float>;

}
