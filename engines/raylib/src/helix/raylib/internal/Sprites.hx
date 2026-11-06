package helix.raylib.internal;

/** Gives the frame its sprite runs (`Frame.makeSprites`), so a run of quads of one texture is drawn as instances. The modules that add
	quads (`RTextures`, `RRlgl`, which the shapes and text draw through) register it as they start, so a program drawing no quads links
	neither the sprite shader nor the sprite path. */
@:noCompletion
class Sprites {
	/** Sets what makes the frame's sprite runs, once. */
	public static function register():Void {
		if (Frame.makeSprites == null)
			Frame.makeSprites = make;
	}

	static function make(renderer:helix.render.Renderer):helix.render.SpriteRuns2D
		return new helix.render.SpriteRuns2D(renderer);
}
