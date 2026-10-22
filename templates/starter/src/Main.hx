import helix.AppOptions;

/** The entry point, the same in the browser and natively: helix.App runs Game on the backend the build names (-D helix-backend). The
	options' identity names what HeliX keeps for the game (its cache: a directory natively, a database in the browser); the assets are the
	directory beside the page or the program ("assets", the default). */
class Main {
	public static function main():Void {
		var options = new AppOptions();
		options.product = "{name}";
		new Game(options);
	}
}
