package helix.debug;

/** Experiment options/probes/capture. Not the window, audio or input contract. */
interface IDiagnostics {
 public function option(name:String,fallback:String):String;
 public function publish(value:Dynamic):Void;
 public function expose(inspect:Void->Dynamic):Void;
 public function capture(name:String=""):Void;
 /** Previous host callback including service polling; excludes presentation/wait. */
 public function frameCpu():Float;
 /** Actual callback interval in milliseconds, independently of filtered simulation dt. */
 public function frameInterval():Float;
 /** Audit-only backend counters; null on hosts audited externally. */
 public function frameAudit():Dynamic;
 /** Profiling-only memory phase; native temporarily disables GC between begin/end. */
 public function memoryPhase(begin:Bool):Dynamic;
 public function info():Dynamic;
}
