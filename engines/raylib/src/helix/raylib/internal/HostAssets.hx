package helix.raylib.internal;

/** The program's assets, whose refusal of a path outside every root names the asset hosts, as a raylib program knows them. */
@:noCompletion
class HostAssets extends helix.services.assets.Assets {
	override function outside(path:String):String
		return 'Invalid file path: $path is outside every asset host (${[for (host in Runtime.assetHosts()) Runtime.hostRoot(host)].join(", ")})';
}
