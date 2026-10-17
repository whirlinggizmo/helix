package helix.graphics;

/** The GPU: textures, buffers, shaders, pipelines, passes and draws. Shutting it down is the runner's. The program's one, a static class: each
	member forwards to instance, written by helix.macro.Facade from IGraphics's public members with their doc comments. */
@:build(helix.macro.Facade.build(helix.graphics.IGraphics, ["shutdown"]))
class Graphics {
	/** The GPU forwarded to: the profile's from its init to its cleanup, null outside them. Kept across a hot reload (@:hot): set once by the runner, nothing would set it again. */
	@:hot public static var instance(default, null):IGraphics;
}
