import helix.ray.*;
import helix.ray.Raylib.*;
import helix.ray.Raymath.*;
import helix.ray.Rlgl.*;
import Parity.*;

// helix-ray's VR stereo config and rlgl's stereo state, printed as ref.c prints raylib 5.5's.
class StereoBits {
	static function matrix(name:String, m:Matrix):Void
		line('$name matrix ${m.m0} ${m.m1} ${m.m2} ${m.m3} ${m.m4} ${m.m5} ${m.m6} ${m.m7} ${m.m8} ${m.m9} ${m.m10} ${m.m11} ${m.m12} ${m.m13} ${m.m14} ${m.m15}');

	static function pair(name:String, label:String, v:Array<Float>):Void
		line('$name $label ${v[0]} ${v[1]}');

	static function config(name:String, c:VrStereoConfig):Void {
		matrix(name, c.projection[0]);
		matrix(name, c.projection[1]);
		matrix(name, c.viewOffset[0]);
		matrix(name, c.viewOffset[1]);
		pair(name, "leftLensCenter", c.leftLensCenter);
		pair(name, "rightLensCenter", c.rightLensCenter);
		pair(name, "leftScreenCenter", c.leftScreenCenter);
		pair(name, "rightScreenCenter", c.rightScreenCenter);
		pair(name, "distortionScale", c.scale);
		pair(name, "distortionScaleIn", c.scaleIn);
	}

	static function stereo(name:String):Void {
		line('$name enabled ${rlIsStereoRenderEnabled() ? 1 : 0}');
		matrix(name, rlGetMatrixProjectionStereo(0));
		matrix(name, rlGetMatrixProjectionStereo(1));
		matrix(name, rlGetMatrixViewOffsetStereo(0));
		matrix(name, rlGetMatrixViewOffsetStereo(1));
	}

	static function main() {
		open();
		var cv1:VrDeviceInfo = {
			hResolution: 2160,
			vResolution: 1200,
			hScreenSize: 0.133793,
			vScreenSize: 0.0669,
			eyeToScreenDistance: 0.041,
			lensSeparationDistance: 0.07,
			interpupillaryDistance: 0.07,
			lensDistortionValues: [1.0, 0.22, 0.24, 0.0],
			chromaAbCorrection: [0.996, -0.004, 1.014, 0.0]
		};
		var dk2:VrDeviceInfo = {
			hResolution: 1280,
			vResolution: 800,
			hScreenSize: 0.14976,
			vScreenSize: 0.09356,
			eyeToScreenDistance: 0.041,
			lensSeparationDistance: 0.0635,
			interpupillaryDistance: 0.064,
			lensDistortionValues: [1.0, 0.22, 0.24, 0.02],
			chromaAbCorrection: [0.996, -0.004, 1.014, 0.0]
		};
		stereo("start");
		var a = LoadVrStereoConfig(cv1);
		config("cv1", a);
		config("dk2", LoadVrStereoConfig(dk2));
		rlSetClipPlanes(0.5, 50);
		config("clipped", LoadVrStereoConfig(cv1));
		rlSetClipPlanes(0.01, 1000);
		BeginVrStereoMode(a);
		stereo("begun");
		EndVrStereoMode();
		stereo("ended");
		rlEnableStereoRender();
		rlSetMatrixProjectionStereo(MatrixTranslate(1, 2, 3), MatrixScale(2, 3, 4));
		rlSetMatrixViewOffsetStereo(MatrixRotateY(0.5), MatrixPerspective(1, 1.5, 0.1, 10));
		stereo("set");
		rlDisableStereoRender();
		stereo("disabled");
		UnloadVrStereoConfig(a);
		save();
	}
}
