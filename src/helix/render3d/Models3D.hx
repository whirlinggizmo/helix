package helix.render3d;

/** Model files (glTF 2.0), loaded once and shared by path (ModelCache3D). The program's one, a static class: each
	member forwards to instance, written by helix.macro.Facade from ModelCache3D's public members with their doc comments. */
@:build(helix.macro.Facade.build(helix.render3d.ModelCache3D, ["shutdown"]))
class Models3D {
	/** The models forwarded to, for what takes a ModelCache3D (a Loader, an outfit): the runner's from its init to its cleanup, null outside them. Kept across a hot reload (@:hot): set once by the runner, nothing would set it again. */
	@:hot public static var instance(default, null):ModelCache3D;
}
