import helix.audio.AudioResources;
import helix.audio.AudioClip;
import helix.audio.AudioPlayback;
import helix.audio.AudioResources.AudioLoadResult;

class Sounds {
	public static final names = [
		"start",
		"fire",
		"bang_large",
		"bang_medium",
		"bang_small",
		"extra_life",
		"game_over",
		"thrust-v4"
	];

	public var loaded(default, null) = 0;

	var clips:Array<AudioClip> = [for (_ in 0...8) null];
	var audio:AudioResources;
	var loop:AudioPlayback;
	var thrustVolume = 0.;
	var closed = false;

	public function new(audio:AudioResources, complete:Null<String>->Void) {
		this.audio = audio;
		for (i in 0...names.length) {
			var index = i;
			audio.loadClip("sounds/" + names[i] + ".ogg", result -> {
				switch (result) {
					case Ready(resource):
						if (closed) {
							resource.release();
							return;
						}
						clips[index] = resource;
						loaded++;
						if (loaded == 8) complete(null);
					case Failed(message): if (!closed) {
							cleanup();
							complete(message);
						}
					case Cancelled:
				}
			});
		}
	}

	public function play(game:Game, enabled:Bool, focused:Bool = true):Void {
		if (enabled && focused)
			for (kind in game.sounds)
				audio.play(clips[kind], false, kind == 1 ? 0.5 : 0.75);
		var thrust = enabled && focused && game.state == "playing" && game.thrusting && game.respawnDelay == 0;
		if (thrust) {
			if (loop == null || loop.isFinished()) {
				thrustVolume = 0;
				loop = audio.play(clips[7], true, 0);
			}
			thrustVolume = Math.min(.65, thrustVolume + .13);
			loop.setVolume(thrustVolume);
		} else if (loop != null) {
			thrustVolume = enabled && focused ? thrustVolume * .35 : 0;
			if (thrustVolume < .01) {
				loop.stop();
				loop = null;
				thrustVolume = 0;
			} else
				loop.setVolume(thrustVolume);
		}
	}

	public function cleanup():Void {
		if (closed)
			return;
		closed = true;
		if (loop != null)
			loop.stop();
		loop = null;
		for (clip in clips)
			if (clip != null)
				clip.release();
	}
}
