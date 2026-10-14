package helix.graphics;

import haxe.io.Bytes;
import helix.render2d.Texture2D;

/** A screen effect: a Shader of kind screen drawn over a whole frame (one triangle over the viewport), with its own parameters and textures set
	by name, kept across the shader's reloads. PostProcess chains them; draw draws one into the open pass. */
class ScreenEffect {
	var gpu:IGraphics;
	var shader:Shader;
	var alpha:Bool;
	var pipeline = 0;
	var version = -1;
	var values = new Map<String, Array<Float>>();
	var textures = new Map<String, Texture2D>();
	var enabled = true;

	/** An effect drawing with shader (kind screen) on gpu, blended over what's there when alpha, else replacing it. Throws for a shader of another
		kind. */
	public function new(gpu:IGraphics, shader:Shader, alpha = false) {
		if (shader.getKind() != "screen")
			throw 'A ${shader.getKind()} shader is not a screen effect';
		this.gpu = gpu;
		this.shader = shader;
		this.alpha = alpha;
	}

	/** Its shader. */
	public function getShader():Shader
		return shader;

	/** Whether PostProcess draws it. */
	public function isEnabled():Bool
		return enabled;

	/** Turns it on or off in a PostProcess chain. */
	public function setEnabled(value:Bool):Void
		enabled = value;

	/** Sets parameter name (a float, or a vector's or matrix's first components) to values; the rest keep theirs. False when the shader has no
		such parameter or the values don't fit it. */
	public function setValues(name:String, values:Array<Float>):Bool {
		var p = shader.getParameter(name);
		if (p == null || values.length > components(p.type) * p.count)
			return false;
		this.values[name] = values.copy();
		return true;
	}

	/** Sets a float parameter. */
	public function setFloat(name:String, value:Float):Bool
		return setValues(name, [value]);

	/** Sets a vec4 parameter to a color 0xRRGGBBAA, each channel 0..1 as it is (not decoded from sRGB). */
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

	/** Binds texture to the shader's texture name (sampled as the texture's sampling says). False when the shader has no such texture. */
	public function setTexture(name:String, texture:Texture2D):Bool {
		if (shader.getTextureSlot(name) < 1)
			return false;
		textures[name] = texture;
		return true;
	}

	static function components(type:String):Int
		return switch type {
			case "vec2": 2;
			case "vec3": 3;
			case "vec4": 4;
			case "mat4": 16;
			case _: 1;
		}

	/** Draws the effect over the open pass's viewport, reading source (the frame it changes), width x height pixels, seconds since it began. Every
		texture the shader samples must be set; one that isn't is drawn as source. */
	public function draw(source:Texture2D, width:Int, height:Int, time:Float):Void {
		if (version != shader.getVersion()) {
			// Made or reloaded: a pipeline for this program.
			if (pipeline != 0)
				gpu.destroyPipeline(pipeline);
			pipeline = gpu.createPipeline(Screen, alpha, shader.getHandle());
			version = shader.getVersion();
		}
		var sizes = shader.getBlockSizes(), blocks:Array<Null<Bytes>> = [];
		for (slot in 0...sizes.length)
			blocks.push(sizes[slot] > 0 ? Bytes.alloc(sizes[slot]) : null);
		// The framework's: block 1 is the frame's size and the time (block 0 the adapter's clip scale).
		if (blocks.length > 1 && blocks[1] != null) {
			blocks[1].setFloat(0, width);
			blocks[1].setFloat(4, height);
			blocks[1].setFloat(8, time);
		}
		for (name => list in values) {
			var p = shader.getParameter(name);
			if (p == null || blocks[p.slot] == null)
				continue;
			// std140: an array's elements, and a matrix's columns, are 16 bytes apart; anything else is packed.
			var spread = p.count > 1 || p.type == "mat4",
				per = p.type == "mat4" ? 4 : components(p.type);
			for (i in 0...list.length) {
				var at = p.offset + (spread ? Std.int(i / per) * 16 + (i % per) * 4 : i * 4);
				if (at + 4 <= blocks[p.slot].length)
					blocks[p.slot].setFloat(at, list[i]);
			}
		}
		var bound = [for (_ in 0...shader.getTextureCount()) source],
			samplings = [for (_ in 0...shader.getTextureCount()) source.getSampling()];
		for (name => texture in textures) {
			var slot = shader.getTextureSlot(name);
			if (slot >= 0 && slot < bound.length) {
				bound[slot] = texture;
				samplings[slot] = texture.getSampling();
			}
		}
		gpu.drawScreen(pipeline, [for (t in bound) t.getHandle()], samplings, blocks);
	}

	/** Frees its pipeline; the shader stays its loader's. */
	public function destroy():Void
		if (pipeline != 0) {
			gpu.destroyPipeline(pipeline);
			pipeline = 0;
		}
}
