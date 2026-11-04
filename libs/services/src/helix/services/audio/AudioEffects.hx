package helix.services.audio;

import haxe.exceptions.NotImplementedException;
import helix.platform.AudioEffect;
import helix.platform.IAudioEffects;
import helix.platform.IPollable;

/** Provides effects on what groups play, such as a low pass on the music while the game is paused, and reads what a group plays, for a
	level meter or a visualizer.

	A group's effects apply to every voice in it and in the groups under it. A voice in `music`, under `master`, is heard through
	music's effects and then master's. Each group's effects run in the order they were added. A program constructs it only when it uses
	effects, so one that doesn't carries none of it. Voices already playing when it is constructed are moved into their groups' effects.

	The program calls `poll` once a frame, which steps the fades and delivers what the analysers kept.

	```haxe
	var effects = new AudioEffects(audio, new WebAudioEffectsAdapter(output));
	var muffle = effects.add(music, LowPass(22050, 0.71));
	muffle.fadeTo(LowPass(800, 0.71), 0.3); // paused
	var meter = effects.addAnalyser(audio.master, 1024);
	var level = meter.getLevel();
	``` */
class AudioEffects implements IPollable {
	/** Creates the effects over the platform's, for an audio's groups.

		@param audio  The audio whose groups get effects.
		@param effects  The platform's effects, over the same output as `audio`. */
	public function new(audio:Audio, effects:IAudioEffects) {
		throw new NotImplementedException();
	}

	/** Adds an effect at the end of a group's effects.

		@param group  The group.
		@param effect  The effect and its settings.
		@return  The effect.
		@throws String  When a setting is outside its range. */
	public function add(group:Group, effect:AudioEffect):Effect {
		throw new NotImplementedException();
	}

	/** Adds an analyser at the end of a group's effects, which reads what the group plays there.

		@param group  The group.
		@param frameCount  How many of the latest frames it keeps, a power of two from 32 to 32768. 1024 is about a frame's worth at 60 Hz.
		@return  The analyser.
		@throws String  When the frame count isn't a power of two from 32 to 32768. */
	public function addAnalyser(group:Group, frameCount:Int):Analyser {
		throw new NotImplementedException();
	}

	/** Steps the effects' fades and delivers what the analysers kept. The program calls it once a frame. */
	public function poll():Void {
		throw new NotImplementedException();
	}

	/** Removes every effect and analyser. Every voice is heard without effects again. */
	public function dispose():Void {
		throw new NotImplementedException();
	}
}
