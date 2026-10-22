package helix.scene;

/** Scene files (.scene3d), parsed once and shared by path (SceneFileCache3D). The program's one, a static class: each member forwards to
	instance, written by helix.macro.Facade from SceneFileCache3D's public members with their doc comments. */
@:build(helix.macro.Facade.build(helix.scene.SceneFileCache3D, ["shutdown"]))
class SceneFiles3D {
	/** The scene files forwarded to: the runner's from its init to its cleanup, null outside them. Kept across a hot reload (@:hot): set once by the runner, nothing would set it again. */
	@:hot public static var instance(default, null):SceneFileCache3D;
}
