package helix.host;

import helix.assets.IFetch;
import helix.assets.IStorage;
import helix.audio.IAudio;
import helix.graphics.IGraphics;
import helix.input.IInput;

/** Composition boundary: lifecycle hooks belong to adapters, not game contracts. */
typedef HostServices = {
	/** The drawing service. */
	var graphics:IGraphics;

	/** The keyboard, mouse and touch service. */
	var input:IInput;

	/** The audio service. */
	var audio:IAudio;

	/** Downloads over the network. */
	var fetch:IFetch;

	/** The writable cache that downloaded assets are kept in. */
	var storage:IStorage;

	/** The assets shipped with the build, read when base is null. */
	var packaged:IStorage;

	/** The URL prefix assets are fetched from; null reads them from packaged instead. */
	var base:Null<String>;

	/** Before the app's frame: takes the input events that arrived since the last frame. */
	var pollInput:Void->Void;

	/** After the app's frame: frame edges, text, the wheel and lifted touches end. */
	var endInputFrame:Void->Void;

	/** The window gained (true) or lost (false) the keyboard; losing it releases held input. */
	var focusInput:Bool->Void;

	/** After a key press or click: lets a browser start audio. Nothing natively. */
	var unlockAudio:Void->Void;

	/** The page was hidden or lost focus: pauses browser audio. Nothing natively. */
	var suspendAudio:Void->Void;

	/** At cleanup, after the app's: releases the input service. */
	var shutdownInput:Void->Void;

	/** Backend facts for IDiagnostics.getInfo: graphics backend, renderer and audio. */
	var info:Void->Dynamic;
}
