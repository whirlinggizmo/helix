package helix.platform;

/** Specifies where the device's tilt is (`Event.TiltState`, after `ITilt.requestAccess`). */
enum TiltStatus {
	/** Not read: it was never asked for, or it was turned off. */
	Off;

	/** Waiting for the player's next tap, where a page asks for permission. */
	WaitingForTap;

	/** Read: `Tilt` events arrive. */
	On;

	/** The player refused permission. */
	Refused;

	/** The device gives no readings: there is no sensor, or none answered, or none is read on this target. */
	Unavailable;

	/** The page isn't secure (not HTTPS), so the browser gives no readings. */
	NeedsHttps;
}
