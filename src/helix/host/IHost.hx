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
 /** Whether the window (the page, on the web) has the keyboard. */
 public function isFocused():Bool;
 /** Whether quit() means anything: not in a browser page. */
 public function canQuit():Bool;
 public function run(app:IApp):Void;
 /** Seconds on a monotonic clock. */
 public function getTime():Float;
 /** The drawable area in framebuffer pixels (IWindow's sizes are logical pixels). */
 public function getFramebufferWidth():Int;
 public function getFramebufferHeight():Int;
 /** Framebuffer pixels per logical pixel. */
 public function getPixelRatio():Float;
 public function quit():Void;
}
