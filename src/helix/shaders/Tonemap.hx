package helix.shaders;

import helix.graphics.Graphics;
import helix.graphics.ScreenEffect;

/** An HDR chain's tone mapping, a screen effect of the library: the frame's light (a stage's after its exposure, drawn into a half-float scene
	as sRGB values running past 1) brought into the screen's 0..1 by mode, as Stage3D does drawing straight to the screen, and written as the
	screen's sRGB. It wants HDR itself (ScreenEffect.hdr). PostProcess adds one after the last effect wanting HDR, with its stage's mode, to a
	chain that has none; one added by hand runs where it's added, with its own mode, and only in an HDR chain. Built on the program's GPU
	(Graphics) the first time one is made. */
class Tonemap extends ScreenEffect {
	/** A tone mapping by Khronos PBR Neutral. */
	public function new() {
		super(Graphics.instance, ShaderLibrary.get(Graphics.instance, "tonemap", TonemapPacked.text()));
		hdr = true;
		mode = helix.render3d.Tonemap.Neutral;
	}

	/** How the light comes into 0..1 (helix.render3d.Tonemap's modes, as Stage3D.tonemap): Khronos PBR Neutral to start. */
	public var mode(default, set):helix.render3d.Tonemap;

	function set_mode(value:helix.render3d.Tonemap):helix.render3d.Tonemap {
		mode = value;
		parameters.setFloat("mode", (value : Int));
		return value;
	}
}
