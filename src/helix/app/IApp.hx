package helix.app;
/** What a host drives. Hosts call through the object each time, so after a hot reload its new methods are what run. */
interface IApp {
 public function init():Void;
 public function frame(dt:Float):Void;
 public function cleanup():Void;
}
