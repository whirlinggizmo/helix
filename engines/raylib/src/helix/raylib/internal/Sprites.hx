package helix.raylib.internal;

/** Gives the frame its sprite shader (`Frame.spriteShader`), so a run of quads of one texture is drawn as instances (`Frame`'s sprite
	runs). The modules that add quads (`RTextures`, `RRlgl`, which the shapes and text draw through) register it as they start, so a
	program drawing no quads links neither the shader nor the sprite path. */
@:noCompletion
class Sprites {
	/** Sets the frame's sprite shader, once. */
	public static function register():Void {
		if (Frame.spriteShader == null)
			Frame.spriteShader = shader;
	}

	static function shader():helix.services.shaders.Shader
		return Defaults.spriteShader();
}
