package helix.asset;

/** The writable cache: files by key (StorageService). The program's one, a static class: each
	member forwards to instance, written by helix.macro.Facade from StorageService's public members with their doc comments. */
@:build(helix.macro.Facade.build(helix.asset.StorageService, ["poll", "shutdown"]))
class Storage {
	/** The cache forwarded to: the runner's from its init to its cleanup, null outside them. Kept across a hot reload (@:hot): set once by the runner, nothing would set it again. */
	@:hot @:allow(helix) static var instance(default, null):StorageService;
}
