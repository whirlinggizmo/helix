package helix.debug;

/** Run options, probes and captures, for checks and tools. Not the window, audio or input contract. */
interface IDiagnostics {
	/** A run option, or fallback when it isn't given: in a browser the URL query parameter name, natively the environment variable HELIX_ and name in capitals. */
	public function getOption(name:String, fallback:String):String;

	/** Reports a result to the harness: window.result in a browser; natively a JSON line on stdout, also written to the file HELIX_RESULT names. */
	public function publish(value:Dynamic):Void;

	/** Lets the harness read the app's state: window.inspect in a browser; natively written as JSON each frame to the file HELIX_LIVE names. */
	public function expose(inspect:Void->Dynamic):Void;

	/** Asks for a screenshot: a helix-capture event in a browser (nothing for an empty name); natively a PPM at HELIX_CAPTURE, with -name added for a name. */
	public function capture(name:String = ""):Void;

	/** Previous host callback including service polling; excludes presentation/wait. */
	public function getFrameCpu():Float;

	/** Actual callback interval in milliseconds, independently of filtered simulation dt. */
	public function getFrameInterval():Float;

	/** Audit-only backend counters; null on hosts audited externally. */
	public function getFrameAudit():Dynamic;

	/** Profiling-only memory phase; native temporarily disables GC between begin/end. */
	public function memoryPhase(begin:Bool):Dynamic;

	/** Backend facts: the graphics backend, renderer and audio, and in a browser the asset reload count. */
	public function getInfo():Dynamic;
}
