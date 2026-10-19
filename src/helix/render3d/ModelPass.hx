package helix.render3d;

/** An extra pass a model is drawn in after the stage's opaque models: the model again in one flat color, from the same records as its parts
	(static or skinned, instanced like it), either pushed out along its normals into a shell whose far side shows past its edges (an outline:
	helix.shaders.Outline), or drawn only where something nearer hides it (a silhouette: helix.shaders.Silhouette). Each kind's constructor
	adds it to its model. A stage draws its opaque models without silhouettes and its opaque sprites, then the silhouettes, then the opaque
	models with them (so a model's own parts never hide it), then every outline, then what's see-through. */
class ModelPass {
	/** The model it draws. */
	public var model(default, null):Model;

	/** Its color, 0xRRGGBBAA: a display color (sRGB, written as it is, as sprites' are), its alpha blending a silhouette over what hides it. */
	public var color:Int;

	/** Whether it draws: true to start. */
	public var enabled:Bool = true;

	// How far it pushes the model out along its normals, in world units (0 or more); and whether it draws only where the model is hidden.
	@:allow(helix.render3d.Stage3D) var push:Float;
	@:allow(helix.render3d.Stage3D) var behind:Bool;

	function new(model:Model, color:Int, push:Float, behind:Bool) {
		this.model = model;
		this.color = color;
		this.push = push;
		this.behind = behind;
		model.passes.push(this);
	}

	/** Takes it off its model, which draws it no more. False when it was taken off before. */
	public function remove():Bool
		return model.passes.remove(this);
}
