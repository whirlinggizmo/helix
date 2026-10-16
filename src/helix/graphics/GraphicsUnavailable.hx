package helix.graphics;

/** Thrown by a graphics adapter that can't get the GPU API it draws through (no WebGL2 in this browser, say), whichever API that is, so a
	host can tell the program's code failing from the platform lacking what it needs. */
class GraphicsUnavailable extends haxe.Exception {}
