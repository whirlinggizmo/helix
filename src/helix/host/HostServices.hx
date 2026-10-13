package helix.host;

import helix.assets.IFetch;
import helix.assets.IStorage;
import helix.audio.IAudio;
import helix.graphics.IGraphics;
import helix.input.IInput;

/** Composition boundary: lifecycle hooks belong to adapters, not game contracts. */
typedef HostServices = {
	var graphics:IGraphics;
	var input:IInput;
	var audio:IAudio;
	var fetch:IFetch;
	var storage:IStorage;
	var packaged:IStorage;
	var base:Null<String>;
	var pollInput:Void->Void;

	/** After the app's frame: frame edges, text, the wheel and lifted touches end. */
	var endInputFrame:Void->Void;

	var focusInput:Bool->Void;
	var unlockAudio:Void->Void;
	var suspendAudio:Void->Void;
	var shutdownInput:Void->Void;
	var info:Void->Dynamic;
}
