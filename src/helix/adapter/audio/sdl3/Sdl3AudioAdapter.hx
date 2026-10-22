package helix.adapter.audio.sdl3;

import helix.adapter.audio.sdl3.internal.AudioBridge;
import helix.adapter.shared.IPcmFiles;
import helix.adapter.shared.NativeAudio;
import helix.audio.IAudio;

/** IAudio natively over an SDL3 audio stream into the default playback device, mixed by the shared mixer; SDL converts to the device's format and rate. */
class Sdl3AudioAdapter extends NativeAudio implements IAudio {
	/** Opens the audio device (available says whether it did); streams read through files. */
	public function new(files:IPcmFiles) {
		super(files);
		AudioBridge.setup();
	}

	function closeOutput():Void
		AudioBridge.shutdown();
}
