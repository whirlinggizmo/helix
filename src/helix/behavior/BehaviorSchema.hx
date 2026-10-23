package helix.behavior;

import helix.behavior.BehaviorProp;

/** What a behavior class takes from a scene file or an inspector: its name (the class's, or what `@:behavior("Name")` gave it), its
	phase and its props, each a `@:prop` field with its type, its default and its range. Generated on each subclass by the build macro
	(helix.macro.Behaviors, its `schema()`), and kept by BehaviorRegistry by name. */
typedef BehaviorSchema = {
	/** The name a file or the registry knows the class by. */
	final name:String;

	/** Its props, a superclass's first, each in the order declared. */
	final props:Array<BehaviorProp>;

	/** When in a frame it runs: `@:phase` on the class, its superclass's without one, Simulate when none says. */
	final phase:Phase;
}
