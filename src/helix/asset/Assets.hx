package helix.asset;

/** Assets: the packaged files or downloads, cached. The program's one, a static class: each
	member forwards to instance, written by helix.macro.Facade from IAssets's public members with their doc comments. */
@:build(helix.macro.Facade.build(helix.asset.IAssets))
class Assets {
	/** The assets forwarded to: the runner's from its init to its cleanup, null outside them. Kept across a hot reload (@:hot): set once by the runner, nothing would set it again. */
	@:hot @:allow(helix) static var instance(default, null):IAssets;
}
