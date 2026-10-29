package helix.platform.adapters.graphics.sokol;

import helix.platform.adapters.graphics.sokol.internal.GraphicsBridge;
import helix.platform.adapters.shared.NativeGraphics;
import helix.platform.IGraphics;
import helix.platform.ShaderSource;

/** Provides `IGraphics` on sokol_gfx, natively, drawing with GL 4.1 in the window's context.

	Programs come from a `ShaderSource`'s GLSL 410. */
class SokolGraphicsAdapter extends NativeGraphics implements IGraphics {
	/** Creates the adapter, setting up sokol_gfx in the window's GL context, which must already exist. */
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

	public function dispose():Void
		GraphicsBridge.dispose();
}
