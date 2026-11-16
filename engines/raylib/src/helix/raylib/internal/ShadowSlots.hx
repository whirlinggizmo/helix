package helix.raylib.internal;

/** Binds a shadow map to a program's shadow sampler (`<helix/raylib/shaders/shadows.glsl>`'s `helixShadowMap`), as a texture of the
	program's own (`Program.setTexture`), so its draws bind a texture of the sampler's kind: an empty one until a light casts shadows
	(`Shadows`), then the frame's shadow map.

	Linked by the lit shaders' loads and the compiled shaders', so a program loading neither links none of it. */
@:noCompletion
class ShadowSlots {
	// The empty shadow map's texture id, and the graphics it was made on.
	static var empty = 0;
	static var emptyGraphics:Null<helix.platform.IGraphics>;

	/** Returns the slot of a program's shadow sampler, -1 for a program without one.

		@param p  The program. */
	public static function slotOf(p:Program):Int {
		for (s in p.shader.samplers)
			if (s.kind == Shadow)
				return s.slot;
		return -1;
	}

	/** Binds a texture to a program's shadow sampler, and to its twins'; nothing for a program without one.

		@param p  The program.
		@param id  The texture's id (`Textures.fromHandle`), or 0 for the empty shadow map. */
	public static function bind(p:Program, id:Int):Void {
		var slot = slotOf(p);
		if (slot < 0)
			return;
		if (id == 0) {
			if (empty == 0 || emptyGraphics != Runtime.graphics) {
				empty = Textures.fromHandle(Runtime.graphics.createShadowMap(1, 1));
				emptyGraphics = Runtime.graphics;
			}
			id = empty;
		}
		// Set when unset: the Shadowmaps extra's resolver, set first, finds the textures as Textures.handle does.
		if (Program.resolve == null)
			Program.resolve = Textures.handle;
		p.setTexture(slot, id);
	}
}
