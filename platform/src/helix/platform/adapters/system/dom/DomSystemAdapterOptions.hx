package helix.platform.adapters.system.dom;

/** Specifies who the program is, for the directories `DomSystemAdapter` gives it. */
@:structInit
class DomSystemAdapterOptions {
	/** Gets the company's name, one directory's name. Defaults to "DefaultCompany". */
	public final company:String = "DefaultCompany";

	/** Gets the product's name, one directory's name. Defaults to "Game". */
	public final product:String = null;
}
