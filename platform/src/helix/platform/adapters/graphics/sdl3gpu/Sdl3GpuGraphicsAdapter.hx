package helix.platform.adapters.graphics.sdl3gpu;

import helix.platform.adapters.graphics.sdl3gpu.internal.GraphicsBridge;
import helix.platform.adapters.shared.NativeGraphics;
import helix.platform.IGraphics;
import helix.platform.ShaderSource;
import haxe.io.Bytes;

/** Provides `IGraphics` on SDL_GPU, natively: Vulkan, Direct3D 12 or Metal.

	SDL picks the backend for the system; the environment variable SDL_GPU_DRIVER chooses another. Programs come from a `ShaderSource`'s
	SDL_GPU stages (`ShaderSource.sdlGpu`). */
class Sdl3GpuGraphicsAdapter extends NativeGraphics implements IGraphics {
	/** Creates the GPU device and claims the window, which must already exist.

		@throws String  SDL cannot create the device or claim the window. */
	public function new() {
		if (GraphicsBridge.setup() != 1)
			throw "SDL_GPU can't run here (see the log)";
	}

	public function createShader(source:ShaderSource):Int {
		var dialects = source.sdlGpu;
		if (dialects == null)
			throw "The program has no SDL_GPU dialects (its ShaderSource.sdlGpu is missing)";
		var format = GraphicsBridge.shaderFormat();
		var vertex = format == 0 ? haxe.crypto.Base64.decode(dialects.spirv.vertex) : text(format == 1 ? dialects.msl.vertex : dialects.hlsl.vertex),
			fragment = format == 0 ? haxe.crypto.Base64.decode(dialects.spirv.fragment) : text(format == 1 ? dialects.msl.fragment : dialects.hlsl.fragment),
			lines:String = NativeGraphics.layout(source) + '\nk ${source.attributes.length}';
		// Every attribute slot, a matrix's columns each one (`k <count>`): SDL_GPU feeds each, those no buffer does from a constant.
		// Text keeps its NUL past the bytes given.
		var vertexBytes = format == 0 ? vertex.length : vertex.length - 1,
			fragmentBytes = format == 0 ? fragment.length : fragment.length - 1;
		var handle = GraphicsBridge.shader(cpp.Pointer.arrayElem(vertex.getData(), 0).raw, vertexBytes, cpp.Pointer.arrayElem(fragment.getData(), 0).raw,
			fragmentBytes, cpp.ConstCharStar.fromString(lines));
		if (handle == 0)
			throw "The shader didn't build (see the log)";
		if (source.points == true)
			pointPrograms.set(handle, true);
		return handle;
	}

	/** Returns a stage's text as UTF-8 bytes ending in a NUL. */
	static function text(source:String):Bytes {
		var utf8 = Bytes.ofString(source),
			bytes = Bytes.alloc(utf8.length + 1);
		bytes.blit(0, utf8, 0, utf8.length);
		bytes.set(utf8.length, 0);
		return bytes;
	}

	public function dispose():Void
		GraphicsBridge.dispose();
}
