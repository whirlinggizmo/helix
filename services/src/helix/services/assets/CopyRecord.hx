package helix.services.assets;

/** Represents what a kept copy of a server's file is known by: its label, its byte count, the time until which it is fresh without asking,
	and its HTTP validators.

	The label is the manifest hash the bytes were checked against when they were downloaded (`ManifestCache`), and absent otherwise. */
@:noCompletion
typedef CopyRecord = {
	?label:String,
	size:Int,
	freshUntil:Float,
	?etag:String,
	?lastModified:String
}
