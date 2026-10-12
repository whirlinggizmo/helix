package hybrid;
/** Experiment options/probes/capture. Not the window, audio or input contract. */
interface IDiagnostics {
 public function option(name:String,fallback:String):String;
 public function publish(value:Dynamic):Void;
 public function expose(inspect:Void->Dynamic):Void;
 public function capture():Void;
 public function info():Dynamic;
}
