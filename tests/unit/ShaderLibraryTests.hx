import Render2DTests.CountingGraphics;
import haxe.io.Bytes;
import helix.graphics.Graphics;
import helix.graphics.Shader;
import helix.render3d.Material;
import helix.shaders.ShaderLibrary;
import helix.shaders.Unlit;

/** The shader library packed into the program (tools/pack_shader.py's generated <Name>Packed classes): each packed shader reads and builds,
	is built once a GPU and shared, freed with the GPU's release, and each library class's fields write their parameters where the shader's
	reflection puts them. */
class ShaderLibraryTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float):Bool
		return Math.abs(a - b) < 1e-6;

	public static function main():Void {
		var gpu = new CountingGraphics();
		@:privateAccess Graphics.bind(gpu);
		packed(gpu);
		unlit(gpu);
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}

	// Every packed shader reads as a .hxshader and builds; the library builds each once a GPU, until the GPU's release.
	static function packed(gpu:CountingGraphics):Void {
		var texts = PackedShaders.texts();
		check(texts.exists("unlit"), "The library's shaders are packed, by their file's stem");
		for (name => text in texts) {
			var shader = Shader.fromText(gpu, text());
			check(shader.kind == "surface" || shader.kind == "screen", '$name packs as a kind the framework has');
			shader.destroy();
		}
		var first = ShaderLibrary.get(gpu, "unlit", UnlitPacked.text());
		check(ShaderLibrary.get(gpu, "unlit", UnlitPacked.text()) == first, "A library shader is built once a GPU, and shared");
		check(ShaderLibrary.get(new CountingGraphics(), "unlit", UnlitPacked.text()) != first, "Another GPU builds its own");
		ShaderLibrary.release(gpu);
		check(ShaderLibrary.get(gpu, "unlit", UnlitPacked.text()) != first, "Released with its GPU, it is built again when next asked for");
	}

	// The material's parameters' bytes as a draw writes them: by slot, null for a slot the shader lacks.
	static function blocks(material:Material):Array<Null<Bytes>> {
		var out = [for (size in material.shader.blockSizes) size > 0 ? Bytes.alloc(size) : null];
		material.shaderParameters.write(out);
		return out;
	}

	static function unlit(gpu:CountingGraphics):Void {
		var material = new Material(), other = new Material();
		var unlit = new Unlit(material), alike = new Unlit(other);
		check(material.shader != null && material.shader.kind == "surface", "Unlit is its material's surface shader");
		check(other.shader == material.shader, "Two materials share the library's one");
		check(unlit.color == 0xffffffff, "White by default: the material as it is");
		var p = material.shader.getParameter("color");
		check(p != null && p.slot == 2 && p.type == "vec4" && p.elementCount == 1, "Its color is its own block's vec4");
		var bytes = blocks(material)[p.slot];
		check(near(bytes.getFloat(p.offset), 1) && near(bytes.getFloat(p.offset + 12), 1), "Written white from the start");
		unlit.color = 0x336699cc;
		bytes = blocks(material)[p.slot];
		check(near(bytes.getFloat(p.offset), 0x33 / 255)
			&& near(bytes.getFloat(p.offset + 4), 0x66 / 255)
			&& near(bytes.getFloat(p.offset + 8), 0x99 / 255)
			&& near(bytes.getFloat(p.offset + 12), 0xcc / 255),
			"The color field writes its member at the reflection's offset, rgba 0 to 1");
		check(near(blocks(other)[p.slot].getFloat(p.offset), 1), "Each material keeps its own color");
		material.setShader(null);
		unlit.color = 0xff0000ff;
		check(material.shaderParameters == null && unlit.color == 0xff0000ff, "With another shader on the material, the field writes nothing there");
	}
}
