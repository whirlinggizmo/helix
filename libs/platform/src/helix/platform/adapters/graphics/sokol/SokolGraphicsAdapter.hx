package helix.platform.adapters.graphics.sokol;

import helix.platform.adapters.graphics.sokol.internal.GraphicsBridge;
import helix.platform.adapters.shared.NativeGraphics;
import helix.platform.IGraphics;
import helix.platform.ShaderSource;

/** Provides `IGraphics` on sokol_gfx, natively, drawing with GL 4.1 in the window's context.

	Programs come from a `ShaderSource`'s GLSL 410, each uniform block a uniform of its struct type there, whose members the adapter sets
	by their types from the reflection (sokol_gfx's own uniform layout can't hold a struct's padding). */
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
		// GL 410 holds each block as a uniform of its struct type: the uniform's name in each stage (`n <block> <vertex> <fragment>`, - for
		// a stage without it), which its members' names start with.
		for (b in source.uniformBlocks) {
			var names = [
				for (text in [vertex, fragment]) {
					var declared = new EReg('^uniform ${b.glslName} (\\w+);', "m");
					declared.match(text) ? declared.matched(1) : "-";
				}
			];
			lines += '\nn ${b.glslName} ${names[0]} ${names[1]}';
		}
		return program(GraphicsBridge.shader(cpp.ConstCharStar.fromString(vertex), cpp.ConstCharStar.fromString(fragment),
			cpp.ConstCharStar.fromString(lines)), source);
	}

	public function dispose():Void
		GraphicsBridge.dispose();
}
