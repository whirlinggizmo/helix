package helix.platform;

/** Specifies what an audio stream plays (`IAudio.openStream`). */
enum StreamSource {
	/** A file the platform reads directly: natively a path, in a page a URL (a Blob's). */
	Local(location:String);

	/** A URL, which only an output that plays URLs itself opens (`IAudio.playsUrls`). */
	Remote(url:String);

	/** A file still downloading, played as it arrives; natively. */
	Downloading(source:GrowingSource);
}
