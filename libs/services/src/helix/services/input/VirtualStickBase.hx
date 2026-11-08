package helix.services.input;

/** Specifies where a virtual stick's base goes. */
enum abstract VirtualStickBase(Int) to Int {
	/** Where the finger lands. It stays there while held. */
	var Floating = 0;

	/** Where the finger lands. It's pulled along when the finger moves past the radius. */
	var Following = 1;

	/** At the stick's fixed base position. A finger landing anywhere in the stick's touch zone pushes the stick from the base toward the
		finger. While no finger holds the stick, an engine draws the stick at the base, the knob at rest (`VirtualGamepad.visible`). */
	var Fixed = 2;
}
