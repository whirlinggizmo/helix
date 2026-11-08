package helix.services.input;

/** Specifies where a virtual stick's base goes. */
enum VirtualStickBase {
	/** Where the finger lands. It stays there while held. */
	Floating;

	/** Where the finger lands. It's pulled along when the finger moves past the radius. */
	Following;

	/** At the stick's fixed base position. A finger landing anywhere in the stick's touch zone pushes the stick from the base toward the
		finger. */
	Fixed;
}
