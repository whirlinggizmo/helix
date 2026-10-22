package helix.render3d;

/** Environment maps from equirectangular images, prepared a little each frame (EnvironmentCache3D), installed by their first use, so a program with none carries none of it. The program's one, a static class: each
	member forwards to instance, written by helix.macro.Facade from EnvironmentCache3D's public members with their doc comments. */
@:build(helix.macro.Facade.build(helix.render3d.EnvironmentCache3D, ["poll", "reloaded", "shutdown"], helix.render3d.EnvironmentCache3D.install))
class Environments3D {
	/** The environments forwarded to: installed by their first use (an optional part, helix.host.Part) until the program's end, null before and after. Kept across a hot reload (@:hot): set once by the runner, nothing would set it again. */
	@:hot @:allow(helix) static var instance(default, null):EnvironmentCache3D;
}
