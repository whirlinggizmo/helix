package helix.asset;

/** How the cache treats a downloaded copy no manifest lists (IAssets.cacheMode); a listed one follows its manifest in every mode, and
	ensure's forceFetch downloads past the cache in every mode.

	- Revalidate, the default: a copy fresh by the host's Cache-Control (max-age not passed, or immutable) is used with no request; any other
	  is asked about first: 304, the copy is used (and fresh again); 200, the new file replaces it; 4xx, the copy is deleted and the load
	  fails; no answer (offline, a timeout) or a 5xx, the copy is used. no-cache and no-store make a copy never fresh, but it's kept, for the
	  next check and for starting offline.
	- Trust: a copy is used without asking, however old: offline-first play, files that never change, or a game that evicts by itself.
	- Off: nothing is kept between runs, and what earlier runs kept is neither used nor deleted (development); this run's downloads are held
	  in memory, so a file loads once a run. */
enum AssetCacheMode {
	Revalidate;
	Trust;
	Off;
}
