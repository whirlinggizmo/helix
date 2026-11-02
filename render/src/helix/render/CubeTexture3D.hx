package helix.render;

import helix.platform.Sampling;
import helix.services.shaders.ShaderSharedTexture;

/** Represents a cube of six square images on the GPU, sampled by direction: a skybox a program's shader draws, or a reflection it
	reads (`samplerCube`).

	`Renderer.createCubeTexture` makes one; a program's shader reads it through `sharedTexture`
	(`values.shareTexture(shader.getSampler("skybox"), cube.sharedTexture)`). The program frees it with `dispose`. An environment that
	lights materials is an `EnvironmentMap3D`, baked from a picture of all around. */
class CubeTexture3D {
	/** Gets each face's width and height, in texels. */
	public final size:Int;

	/** Gets or sets how its draws sample it: `Sampling.LINEAR` until set, its mipmaps blended when it has them. A change applies to the
		draws after it. */
	public var sampling(default, set):Sampling = Sampling.LINEAR;

	/** Gets the cube as helix-services' shared texture, for a program's own shader's `samplerCube`: its handle and its `sampling`, kept
		current by helix-render; 0, no texture, once disposed. */
	public final sharedTexture:ShaderSharedTexture;

	/** Gets the platform's handle, for what only `IGraphics` does with it; 0 once disposed. */
	public var handle(default, null):Int;

	@:allow(helix.render)
	function new(handle:Int, size:Int) {
		this.handle = handle;
		this.size = size;
		sharedTexture = new ShaderSharedTexture(handle, Sampling.LINEAR);
	}

	function set_sampling(value:Sampling):Sampling {
		sampling = value;
		sharedTexture.sampling = value;
		return value;
	}

	/** Frees the cube on the GPU, after the frame being recorded when it holds a draw with it. A second call does nothing. */
	public function dispose():Void {
		if (handle == 0)
			return;
		var old = handle, r = renderer;
		handle = 0;
		sharedTexture.texture = 0;
		if (r != null) {
			r.forget(this);
			r.release(() -> r.graphics.disposeTexture(old));
		}
	}

	// The renderer that made it.
	@:allow(helix.render)
	var renderer:Null<Renderer> = null;
}
