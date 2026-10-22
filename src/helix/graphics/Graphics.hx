package helix.graphics;

/** The GPU: textures, buffers, shaders, pipelines, passes and draws. Shutting it down is the runner's, and so is the frame: the runner opens
	and closes it around the stage's drawing (docs/DISPLAY_MODEL.md), so beginFrame and endFrame aren't here; a pass into a texture
	(beginTargetPass) is drawn in init or update, before the frame opens. The program's one, a static class: each member forwards to instance,
	written by helix.macro.Facade from IGraphics's public members with their doc comments. */
@:build(helix.macro.Facade.build(helix.graphics.IGraphics, ["shutdown", "beginFrame", "endFrame"]))
class Graphics {
	/** The GPU forwarded to: the profile's from its init to its cleanup, null outside them. Kept across a hot reload (@:hot): set once by the runner, nothing would set it again. */
	@:hot public static var instance(default, null):IGraphics;
}
