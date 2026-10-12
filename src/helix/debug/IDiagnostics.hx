package helix.debug;

/** Experiment options/probes/capture. Not the window, audio or input contract. */
interface IDiagnostics {
 public function option(name:String,fallback:String):String;
 public function publish(value:Dynamic):Void;
 public function expose(inspect:Void->Dynamic):Void;
 public function capture():Void;
 /** Previous host callback including service polling; excludes presentation/wait. */
 public function frameCpu():Float;
 public function info():Dynamic;
}
