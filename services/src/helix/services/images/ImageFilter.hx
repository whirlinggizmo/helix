package helix.services.images;

/** Specifies how `Image.resize` makes the pixels between the source's pixels. */
enum abstract ImageFilter(Int) {
	/** Takes the nearest pixel: hard edges, for pixel art. */
	var Nearest;

	/** Blends the nearest four pixels, weighted by distance and by alpha. */
	var Bilinear;

	/** Blends the nearest sixteen pixels on a Catmull-Rom curve, weighted by alpha: sharper than `Bilinear`, for photographs. */
	var Bicubic;
}
