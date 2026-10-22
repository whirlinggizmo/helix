package helix.adapter.graphics.sdl3gpu;

import helix.adapter.graphics.sdl3gpu.internal.GraphicsBridge;
import helix.adapter.shared.NativeGraphics;
import helix.graphics.IGraphics;
import helix.graphics.ShaderSource;
import haxe.io.Bytes;

/** IGraphics on SDL_GPU for native hxcpp builds under the SDL3 host: Vulkan, Direct3D 12 or Metal, whichever SDL picks for the system
	(SDL_GPU_DRIVER chooses another); programs from a ShaderSource's SDL_GPU dialects (built with -D helix_sdl3_gpu). */
class Sdl3GpuGraphicsAdapter extends NativeGraphics implements IGraphics {
	/** Makes the GPU device and claims the host's window, which must already exist. Throws when SDL can't. */
	public function new() {
		if (GraphicsBridge.setup() != 1)
			throw "SDL_GPU can't run here (see the log)";
	}

	/** The backend SDL chose: "vulkan", "direct3d12" or "metal". */
	public var driver(get, never):String;

	function get_driver():String
		return (GraphicsBridge.driver() : String);

	public function createShader(source:ShaderSource):Int {
		var dialects = source.sdlGpu;
		if (dialects == null)
			throw "The program has no SDL_GPU dialects (built without -D helix_sdl3_gpu?)";
		var format = GraphicsBridge.shaderFormat();
		var vertex = format == 0 ? haxe.crypto.Base64.decode(dialects.spirv.vertex) : text(format == 1 ? dialects.msl.vertex : dialects.hlsl.vertex),
			fragment = format == 0 ? haxe.crypto.Base64.decode(dialects.spirv.fragment) : text(format == 1 ? dialects.msl.fragment : dialects.hlsl.fragment),
			lines:String = NativeGraphics.layout(source);
		// Text keeps its NUL past the bytes given.
		var vertexBytes = format == 0 ? vertex.length : vertex.length - 1,
			fragmentBytes = format == 0 ? fragment.length : fragment.length - 1;
		var handle = GraphicsBridge.shader(cpp.Pointer.arrayElem(vertex.getData(), 0).raw, vertexBytes, cpp.Pointer.arrayElem(fragment.getData(), 0).raw,
			fragmentBytes, cpp.ConstCharStar.fromString(lines));
		if (handle == 0)
			throw "The shader didn't build (see the log)";
		return handle;
	}

	/** A stage's text as UTF-8 bytes ending in a NUL. */
	static function text(source:String):Bytes {
		var utf8 = Bytes.ofString(source),
			bytes = Bytes.alloc(utf8.length + 1);
		bytes.blit(0, utf8, 0, utf8.length);
		bytes.set(utf8.length, 0);
		return bytes;
	}

	public function shutdown():Void
		GraphicsBridge.shutdown();
}
