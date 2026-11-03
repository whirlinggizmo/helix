package helix.formats.gif;

/** Specifies what becomes of a GIF frame's rectangle before the next frame is drawn, as its graphic control block says. */
enum abstract GifDisposal(Int) {
	/** Not said: the frame stays, as with `Keep`. A file's reserved values (4 to 7) are read as this. */
	var Unspecified = 0;

	/** The frame stays, and the next is drawn over it. */
	var Keep = 1;

	/** The frame's rectangle is cleared, to transparent, as browsers clear it. */
	var Background = 2;

	/** The frame's rectangle is put back as it was before the frame was drawn. */
	var Previous = 3;
}
