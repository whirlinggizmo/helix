package helix.host;

/** What's fixed when the window opens, given to a profile's run before it does: an app starts after, too late to change them. */
class WindowOptions {
	var msaaSamples = 4;

	/** The defaults: 4 multisampling samples a pixel. */
	public function new() {}

	/** The multisampling samples a pixel asked for: 4 unless requested otherwise. */
	public function getMsaaSamples():Int
		return msaaSamples;

	/** Asks for count samples a pixel to smooth edges (multisampling): 1 for none, else 2, 4 or 8. A request: the platform may give fewer (a
		browser chooses its own count, nearly always 4, for anything over 1), and IGraphics.getMsaaSamples answers what it gave (getMaxMsaaSamples, the most
		this GPU has, for a settings menu to offer at the next start). False, changing nothing, for another count. */
	public function requestMsaaSamples(count:Int):Bool {
		if (count != 1 && count != 2 && count != 4 && count != 8)
			return false;
		msaaSamples = count;
		return true;
	}
}
