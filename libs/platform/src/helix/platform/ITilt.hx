package helix.platform;

/** Defines the device's tilt: `Tilt` and `TiltState` in `IEvents.events` once access is requested.

	Its adapter is constructed over the events adapter, whose `poll` delivers its events and runs the request's callbacks. */
interface ITilt {
	/** Asks for the device's motion sensor, whose readings then arrive as `Tilt` events.

		A page may need permission, which is asked at the next tap. `TiltState` events report each change: WaitingForTap while a tap is
		awaited, Starting until the first reading, then On. A game shows "tap to allow tilt" while the tilt waits for a tap. A reading that arrives after the tilt was reported unavailable turns it on, as a
		phone's sensor may start late.
		@param done  Optional. Called once readings arrive.
		@param failed  Optional. Receives why there will be none: permission was refused, the page isn't secure (not HTTPS), or the browser
			reads no orientation.
		@return  False, calling neither and reporting `Unavailable`, where the tilt can't be read at all. */
	function requestAccess(?done:Void->Void, ?failed:String->Void):Bool;

	/** Stops the readings. A permission granted stays granted, so a later `requestAccess` usually starts without asking
		again. */
	function releaseAccess():Void;

	/** Stops the readings and any request still waiting. */
	function dispose():Void;
}
