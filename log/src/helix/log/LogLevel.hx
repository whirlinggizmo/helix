package helix.log;

/** Specifies how much a log message matters.

	`Log.level` and a tag's own level let through what's at or above them. A level reads as its name when traced or interpolated. */
enum abstract LogLevel(Int) to Int {
	/** Detail for finding a fault, written in debug builds and gone from a release build. */
	var Debug;

	/** What happened, worth knowing. */
	var Info;

	/** Something went wrong and the program carried on. */
	var Warning;

	/** Something failed that the program may not recover from. */
	var Error;

	/** As a level to let through: nothing. */
	var Off;

	/** Returns the level's name.

		@return  "Debug", "Info", "Warning", "Error" or "Off". */
	public function toString():String
		return switch (cast this : LogLevel) {
			case Debug: "Debug";
			case Info: "Info";
			case Warning: "Warning";
			case Error: "Error";
			case Off: "Off";
		}
}
