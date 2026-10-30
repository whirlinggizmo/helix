package helix.platform.adapters.system.sdl3;

/** Specifies who the program is, for the directories `Sdl3SystemAdapter` gives it. */
@:structInit
class Sdl3SystemAdapterOptions {
	/** Gets the company's name, one directory's name. Defaults to "DefaultCompany". */
	public final company:String = "DefaultCompany";

	/** Gets the product's name, one directory's name. Defaults to the executable's name, without its extension. */
	public final product:String = null;
}
