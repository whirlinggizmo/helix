package helix.host;

/** An optional part of the program: a service installed the first time a program uses it (its static class installs it, helix.macro.Facade),
	so a program that never uses it carries none of its code (docs/CONVENTIONS.md, "An optional part is installed by its first use"). The
	Runner walks its parts' hooks and never names one. Each hook may be null. */
typedef Part = {
	/** Each frame, before the app's: the part's work in progress advanced (loads, preparation spread over frames). */
	var ?poll:Void->Void;

	/** Each frame, after the app's: what waits for the frame to be drawn (a screenshot). */
	var ?frameEnded:Void->Void;

	/** Whether the part is loading or preparing anything (Host.busy). */
	var ?busy:Void->Bool;

	/** At the program's end, before the shared services close: the part closed and its static class unbound. */
	var ?shutdown:Void->Void;
}
