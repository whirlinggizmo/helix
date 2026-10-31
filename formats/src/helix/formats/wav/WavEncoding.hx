package helix.formats.wav;

/** Specifies how a WAV file's samples are stored. */
enum abstract WavEncoding(Int) {
	/** Integers: 8 bits unsigned, centered on 128; 16, 24, 32 or more bits signed. */
	var Pcm = 1;

	/** IEEE floating point, 32 or 64 bits, from -1 to 1. */
	var FloatingPoint = 3;

	/** G.711 A-law, a byte a sample. */
	var ALaw = 6;

	/** G.711 mu-law, a byte a sample. */
	var MuLaw = 7;
}
