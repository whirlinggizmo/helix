package helix.shaders;

import helix.graphics.Graphics;
import helix.graphics.ScreenEffect;

/** What the shader library's screen effects share (Bloom, Fxaa, Blur, Vignette, ColorLut, Crt, ChromaticAberration, Pixelate, Tonemap): a
	ScreenEffect whose shader is the library's, built on the program's GPU (Graphics) the first time one is made and shared by every effect of
	its kind, and whose fields write its parameters, each held to its range. PostProcess chains them as any effect (PostProcess.add). */
class LibraryScreenEffect extends ScreenEffect {
	function new(name:String, text:String) {
		super(ShaderLibrary.get(Graphics.instance, name, text));
	}

	// value held to min..max (NaN is min), written as the float parameter name: what the field keeps.
	function writeFloat(name:String, value:Float, min:Float, max:Float):Float {
		value = value > min ? (value < max ? value : max) : min;
		parameters.setFloat(name, value);
		return value;
	}
}
