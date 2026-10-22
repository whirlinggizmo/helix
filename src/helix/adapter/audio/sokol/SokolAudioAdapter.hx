package helix.adapter.audio.sokol;

import helix.adapter.audio.sokol.internal.AudioBridge;
import helix.adapter.shared.IPcmFiles;
import helix.adapter.shared.NativeAudio;
import helix.audio.IAudio;

/** IAudio natively over sokol_audio (ALSA, WASAPI, AudioToolbox), mixed by the shared mixer. */
@:noCompletion
class SokolAudioAdapter extends NativeAudio implements IAudio {
	/** Opens the audio device (available says whether it did); streams read through files. */
	public function new(files:IPcmFiles) {
		super(files);
		AudioBridge.setup();
	}

	function closeOutput():Void
		AudioBridge.shutdown();
}
