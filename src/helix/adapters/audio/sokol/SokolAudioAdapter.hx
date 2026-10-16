package helix.adapters.audio.sokol;

import helix.adapters.audio.sokol.internal.AudioBridge;
import helix.adapters.shared.IPcmFiles;
import helix.adapters.shared.NativeAudio;
import helix.audio.IAudio;

/** IAudio natively over sokol_audio (ALSA, WASAPI, AudioToolbox), mixed by the shared mixer. */
class SokolAudioAdapter extends NativeAudio implements IAudio {
	/** Opens the audio device (isAvailable says whether it did); streams read through files. */
	public function new(files:IPcmFiles) {
		super(files);
		AudioBridge.setup();
	}

	function closeOutput():Void
		AudioBridge.shutdown();
}
