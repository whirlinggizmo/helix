package helix.platform;

/** Represents the error a graphics adapter throws when the GPU API it draws through is missing, such as WebGL2 in a browser without it.

	A caller can tell it apart from a failure in the program's own code and report the platform as unsupported. */
class GraphicsUnavailableException extends haxe.Exception {}
