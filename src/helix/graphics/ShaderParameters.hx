package helix.graphics;

import haxe.io.Bytes;
import helix.render2d.Texture2D;

/** An app's shader's own parameters and textures, set by name and kept across the shader's reloads (a name the reloaded shader lacks is kept
	and ignored), written into its uniform blocks at their std140 offsets when something draws with it. ScreenEffect and Material have one. */
class ShaderParameters {
	var shader:Shader;
	var values = new Map<String, Array<Float>>();
	var textures = new Map<String, Texture2D>();

	/** The parameters of shader. */
	public function new(shader:Shader)
		this.shader = shader;

	/** Sets parameter name (a float, or a vector's or matrix's first components, an array's elements' in turn) to values; the rest keep theirs.
		False when the shader has no such parameter or the values don't fit it. */
	public function setValues(name:String, values:Array<Float>):Bool {
		var p = shader.getParameter(name);
		if (p == null || values.length > components(p.type) * p.elementCount)
			return false;
		this.values[name] = values.copy();
		return true;
	}

	/** Sets a float parameter. False, changing nothing, when the shader has no such parameter. */
	public function setFloat(name:String, value:Float):Bool
		return setValues(name, [value]);

	/** Sets a vector parameter to a color 0xRRGGBBAA, each channel 0..1 as it is (not decoded from sRGB). False, changing nothing,
		when the shader has no such parameter or it has fewer than 4 components. */
	public function setColor(name:String, color:Int):Bool
		return setValues(name, [
			(color >>> 24) / 255,
			((color >>> 16) & 255) / 255,
			((color >>> 8) & 255) / 255,
			(color & 255) / 255
		]);

	/** The values a parameter was set to, or null for one never set (its value is then 0). */
	public function getValues(name:String):Null<Array<Float>>
		return values.exists(name) ? values[name].copy() : null;

	/** Binds texture to the shader's own texture name (sampled as the texture's sampling says). False when the shader has no such texture of its
		own. */
	public function setTexture(name:String, texture:Texture2D):Bool {
		if (shader.getTextureSlot(name) < 0 || StringTools.startsWith(name, "helix_"))
			return false;
		textures[name] = texture;
		return true;
	}

	/** The texture bound to name, or null. */
	public function getTexture(name:String):Null<Texture2D>
		return textures[name];

	static function components(type:String):Int
		return switch type {
			case "vec2": 2;
			case "vec3": 3;
			case "vec4": 4;
			case "mat4": 16;
			case _: 1;
		}

	/** Writes the values set into blocks (the shader's uniform blocks' bytes by slot, null for one it lacks). */
	public function write(blocks:Array<Null<Bytes>>):Void
		for (name => list in values) {
			var p = shader.getParameter(name);
			if (p == null || p.slot >= blocks.length || blocks[p.slot] == null)
				continue;
			// std140: an array's elements, and a matrix's columns, are 16 bytes apart; anything else is packed.
			var spread = p.elementCount > 1 || p.type == "mat4",
				per = p.type == "mat4" ? 4 : components(p.type);
			for (i in 0...list.length) {
				var at = p.offset + (spread ? Std.int(i / per) * 16 + (i % per) * 4 : i * 4);
				if (at + 4 <= blocks[p.slot].length)
					blocks[p.slot].setFloat(at, list[i]);
			}
		}

	/** The textures set, by the shader's slot. */
	public function getTextureSlots():Map<Int, Texture2D> {
		var out = new Map<Int, Texture2D>();
		for (name => texture in textures) {
			var slot = shader.getTextureSlot(name);
			if (slot >= 0)
				out[slot] = texture;
		}
		return out;
	}
}
