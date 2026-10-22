package helix.asset;

/** The game's saves, apart from the asset cache (SaveService), installed by their first use, so a program that saves nothing opens no store
	for them. The program's one, a static class: each member forwards to instance, written by helix.macro.Facade from SaveService's public
	members with their doc comments. */
@:build(helix.macro.Facade.build(helix.asset.SaveService, ["poll", "shutdown"], helix.asset.SaveService.install))
class Saves {
	/** The saves forwarded to: installed by their first use (an optional part, helix.host.Part) until the program's end, null before and after. Kept across a hot reload (@:hot): set once by the runner, nothing would set it again. */
	@:hot @:allow(helix) static var instance(default, null):SaveService;
}
