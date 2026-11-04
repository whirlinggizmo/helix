package helix.platform;

import haxe.io.Bytes;

/** Defines effects on what voices play, and reading what they play, over an `IAudio` output.

	Voices play into chains, and each chain plays into another chain or into the mix, which is a chain too (`mix`), so chains form a
	tree as an engine's buses do. Each chain runs its effects and analysers in the order they were added (`AudioEffect`), then plays into
	the chain above it. A voice plays into the mix until it is sent to another chain (`send`). A program that never constructs
	an `IAudioEffects` carries none of its code: every voice plays straight to the output.

	Chain and effect ids are the adapter's. The effects run where the platform mixes, on its audio thread natively and in the page's audio
	graph in a browser, so nothing here runs a program's code on the audio thread. */
interface IAudioEffects extends IPollable {
	/** Gets the chain everything plays through last, on its way to the output. It can't be disposed. */
	var mix(get, never):Int;

	/** Creates a chain.

		@param output  Optional. The chain it plays into. Defaults to `mix`.
		@return  The chain's id.
		@throws String  For an unknown output chain. */
	function createChain(?output:Int):Int;

	/** Disposes a chain and its effects. Its voices, and the chains that played into it, play into its output chain from then on.

		It does nothing for the mix or an unknown chain.
		@param chain  The chain. */
	function disposeChain(chain:Int):Void;

	/** Sends a voice into a chain, from what it plays next.

		@param voice  The voice, as `IAudio` gave it.
		@param chain  The chain, or `mix` to play straight into the mix.
		@return  False, changing nothing, when the voice isn't playing (unknown, stopped or ended) or the chain is unknown. */
	function send(voice:Int, chain:Int):Bool;

	/** Adds an effect at the end of a chain.

		@param chain  The chain.
		@param effect  The effect and its settings.
		@return  The effect's id.
		@throws String  For an unknown chain, or a setting outside its range. */
	function addEffect(chain:Int, effect:AudioEffect):Int;

	/** Adds an analyser at the end of a chain. It changes nothing, and keeps the latest frames that pass it, for `getSamples` and
		`getSpectrum`. It is removed and bypassed as an effect is.

		@param chain  The chain.
		@param frameCount  How many frames it keeps, a power of two from 32 to 32768.
		@return  The analyser's id, which is an effect's id.
		@throws String  For an unknown chain, or a frame count that isn't a power of two from 32 to 32768. */
	function addAnalyser(chain:Int, frameCount:Int):Int;

	/** Changes an effect's settings.

		The change is ramped over the output's next block, as `IAudio.setVolume` is, so a filter swept once a frame doesn't click.
		@param effect  The effect.
		@param settings  Its new settings, of the same kind as when it was added.
		@return  False, changing nothing, for an unknown effect, an analyser, one of another kind, or a setting outside its range. */
	function setEffect(effect:Int, settings:AudioEffect):Bool;

	/** Turns an effect off or on again, keeping its place and settings. Off, it passes what plays unchanged.

		@param effect  The effect.
		@param bypassed  True to turn it off, false to turn it on.
		@return  False for an unknown effect. */
	function setBypassed(effect:Int, bypassed:Bool):Bool;

	/** Removes an effect from its chain.

		It does nothing for an unknown effect.
		@param effect  The effect. */
	function removeEffect(effect:Int):Void;

	/** Copies the latest frames an analyser kept, as they were heard.

		Natively the frames are copied out on the audio thread and read here, up to one output block late.
		@param effect  The analyser.
		@param into  Receives the frames as 32-bit floats, stereo interleaved, left first, the oldest first. Its length sets how many, up
			to the analyser's frame count.
		@return  The frames copied: 0 for an unknown analyser, and fewer than asked until enough have played. */
	function getSamples(effect:Int, into:Bytes):Int;

	/** Returns how many frames have passed an analyser since it was added, so a reader can tell which of the latest frames are new.

		@param effect  The analyser.
		@return  The frames, counted as `getSamples` sees them; 0 for an unknown analyser. */
	function getFramesPassed(effect:Int):Float;

	/** Measures the latest frames an analyser kept by frequency, as Web Audio's `AnalyserNode.getFloatFrequencyData` does.

		The channels are mixed to one, windowed (Blackman) and transformed. Each band is smoothed against the last measure, 0.8 of the old
		to 0.2 of the new.
		@param effect  The analyser.
		@param into  Receives the bands as 32-bit floats in decibels, from 0 Hz up to half the output's rate. Its length sets how many, up
			to half the analyser's frame count.
		@return  The bands written: 0 for an unknown analyser. */
	function getSpectrum(effect:Int, into:Bytes):Int;

	/** Delivers what the audio thread kept since the last poll. The program calls it once a frame. */
	function poll():Void;

	/** Removes every effect and chain, and sends every voice straight to the output again. */
	function dispose():Void;
}
