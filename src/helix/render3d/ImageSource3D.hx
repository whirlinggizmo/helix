package helix.render3d;

/** Where a model's image file is. */
enum ImageSource3D {
	/** In a buffer view. */
	InView(view:Int);

	/** Inline: a data: URI's bytes. */
	Inline(bytes:haxe.io.Bytes);

	/** A file of its own: a uri relative to the model. */
	File(uri:String);
}
