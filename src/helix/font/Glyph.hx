package helix.font;

/** Where a glyph's texels are, and where it goes: x and y from the pen on the baseline (y grows down), its size, and how far the pen moves after it, in font pixels. */
typedef Glyph = {
	final u0:Float;
	final v0:Float;
	final u1:Float;
	final v1:Float;
	final x:Float;
	final y:Float;
	final width:Float;
	final height:Float;
	final advance:Float;
}
