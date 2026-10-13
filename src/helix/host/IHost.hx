package helix.host;
import helix.audio.IAudio;
import helix.audio.AudioResources;
import helix.assets.IAssets;
import helix.assets.IFetch;
import helix.assets.IStorage;
import helix.input.IInput;
import helix.debug.IDiagnostics;
import helix.graphics.IGraphics;
import helix.app.IApp;
/** Composition and window lifecycle. Services have independent contracts. */
interface IHost {
 public var graphics(default,null):IGraphics;
 public var input(default,null):IInput;
 public var audio(default,null):IAudio;
 public var audioResources(default,null):AudioResources;
 public var fetch(default,null):IFetch;
 public var storage(default,null):IStorage;
 public var assets(default,null):IAssets;
 public var diagnostics(default,null):IDiagnostics;
 public var window(default,null):IWindow;
 public var focused(default,null):Bool;
 public var canQuit(default,null):Bool;
 public function run(app:IApp):Void;
 public function now():Float;
 public function width():Int;
 public function height():Int;
 public function pixelRatio():Float;
 public function quit():Void;
}
