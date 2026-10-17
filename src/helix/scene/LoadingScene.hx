package helix.scene;

/** A scene shown while another's loads are pending (Scenes.setLoadingScene): the stack hands it the loader before it enters, and it draws
	the loader's progress and failures. Loading is the built-in one; another extends this and draws its own. */
class LoadingScene extends Scene {
	var loader:Null<Loader>;

	/** Not showing a loader yet. */
	public function new()
		super();

	/** The loader it shows, or null (its own getLoader stays empty: a loading scene loads nothing first). */
	public function getShownLoader():Null<Loader>
		return loader;

	/** The loader to show: set by the stack as the wait begins. */
	public function setLoader(value:Null<Loader>):Void
		loader = value;
}
