package helix.platform;

/** Specifies the device's tilt status (`Event.TiltState`, after `ITilt.requestAccess`). */
enum TiltStatus {
	/** Not read: it was never asked for, or it was turned off. */
	Off;

	/** Waiting for the next tap, where a page asks for permission. */
	WaitingForTap;

	/** Asked for, and listening. The first reading turns the tilt On. After a second and a half without a reading, the status is
		Unavailable. */
	Starting;

	/** Read: `Tilt` events arrive. */
	On;

	/** Permission was refused. */
	Refused;

	/** The device gives no readings: there is no sensor, or none answered, or none is read on this target. */
	Unavailable;

	/** The page isn't secure (not HTTPS), so the browser gives no readings. */
	NeedsHttps;
}
