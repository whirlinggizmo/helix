package helix.scene;

/** A scene shown while another's loads are pending (Scenes.loadingScene): the stack hands it the loader before it enters, and it draws
	the loader's progress and failures. Loading is the built-in one; another extends this and draws its own. */
class LoadingScene extends Scene {
	/** Not showing a loader yet. */
	public function new()
		super();

	/** The loader it shows, or null (its own loader stays empty: a loading scene loads nothing first): set by the stack as the wait
		begins. */
	public var shownLoader:Null<Loader>;

	/** Whether to stay shown once the loads are done (a "loaded, press to go" screen): the stack keeps it until this is false. False unless
		overridden. */
	public var holding(get, never):Bool;

	function get_holding():Bool
		return false;
}
