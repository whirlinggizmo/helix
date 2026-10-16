package helix.adapters.graphics.sokol;

import helix.adapters.graphics.sokol.internal.GraphicsBridge;
import helix.adapters.shared.NativeGraphics;
import helix.graphics.IGraphics;
import helix.graphics.ShaderSource;

/** IGraphics on sokol_gfx for native hxcpp builds, drawing GL 4.1 in the host's context: programs from a ShaderSource's GLSL 410. */
class SokolGraphicsAdapter extends NativeGraphics implements IGraphics {
	/** Sets up sokol_gfx; the window and its GL context must already exist. */
	public function new() {
		GraphicsBridge.setup();
	}

	public function createShader(source:ShaderSource):Int {
		// Typed first: an anonymous structure's fields reach C++ as variants.
		var vertex:String = source.glsl410.vertex,
			fragment:String = source.glsl410.fragment,
			lines:String = NativeGraphics.layout(source);
		var handle = GraphicsBridge.shader(cpp.ConstCharStar.fromString(vertex), cpp.ConstCharStar.fromString(fragment), cpp.ConstCharStar.fromString(lines));
		if (handle == 0)
			throw "The shader didn't build (see the log)";
		return handle;
	}

	public function shutdown():Void
		GraphicsBridge.shutdown();
}
