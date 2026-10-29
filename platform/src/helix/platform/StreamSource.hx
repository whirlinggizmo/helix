package helix.platform;

/** Specifies what an audio stream plays (`IAudio.openStream`). */
enum StreamSource {
	/** A file the platform reads directly. Natively it is a path, and in a page it is a URL, such as a Blob's. */
	Local(location:String);

	/** A URL, which only an output that plays URLs itself opens (`IAudio.playsUrls`). */
	Remote(url:String);

	/** A file still downloading, played as it arrives. Only a native output plays it. */
	Downloading(source:GrowingSource);
}
