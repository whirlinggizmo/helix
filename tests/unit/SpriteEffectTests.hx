import Render2DTests.CountingGraphics;
import haxe.io.Bytes;
import helix.graphics.Graphics;
import helix.graphics.Pipelines;
import helix.graphics.Shader;
import helix.graphics.SpriteEffect;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Sprite2D;
import helix.render2d.Renderer2D;
import helix.texture.Texture2D;
import helix.render3d.Camera3D;
import helix.render3d.Sprite3D;
import helix.render3d.Renderer3D;
import helix.shader.PaletteSwap;
import helix.shader.ShaderLibrary;
import helix.shader.SpriteDissolve;
import helix.shader.SpriteFlash;
import helix.shader.SpriteOutline;

/** Sprite effects (the sprite kind of shader, helix.graphics.SpriteEffect): the library's sprite shaders read as the sprite kind, over the
	effect2d program's vertices; a batch splits where the effect changes, as it does where the texture does, one effect shared by sprites drawn
	one after another staying one draw, and draws without one as it did; an effect's vertices carry their sprite's region (a nine-slice's whole
	one); the framework's block holds the texture's size and the batch's time; and each library class's fields write their parameters where the
	shader's reflection puts them, a flash fading over the batch's time; and a Renderer3D's sprites draw through an effect's sprite3D variant, split
	by effect as by texture, at the stage's time. */
@:access(helix)
class SpriteEffectTests {
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
		batching(gpu);
		regions(gpu);
		stage(gpu);
		outline(gpu);
		flash(gpu);
		dissolve(gpu);
		palette(gpu);
		stage3D(gpu);
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}

	// A frame of batch through a 400 x 300 camera, drawn by draw.
	static function frame(gpu:CountingGraphics, batch:Batch2D, draw:Void->Void):Void {
		var camera = new Camera2D();
		camera.setViewport(400, 300);
		gpu.beginFrame(400, 300, 0);
		batch.begin(camera);
		draw();
		batch.end();
	}

	// The library's sprite shaders are the sprite kind, without a surface's variants, over effect2d's vertices; another kind isn't an effect.
	static function packed(gpu:CountingGraphics):Void {
		var texts = PackedShaders.texts();
		for (name in ["sprite_outline", "sprite_flash", "sprite_dissolve", "palette_swap"]) {
			check(texts.exists(name), 'The library\'s $name is packed');
			var shader = Shader.fromText(texts[name](), gpu);
			check(shader.kind == "sprite" && shader.skinned == null && shader.caster == null, '$name is a sprite shader, without a surface\'s variants');
			var source:helix.graphics.ShaderSource = @:privateAccess shader.source;
			check(source.attributes.join(",") == "position,uv,color,region", '$name reads the effect2d program\'s vertices');
			check(source.uniformBlocks.filter(b -> b.slot == 0)[0].size == Effect2DProgram.vertexUniformBytes, '$name: block 0 is the clip scale');
			var variant:helix.graphics.ShaderSource = @:privateAccess shader.sprite3D.source;
			check(variant.attributes.join(",") == "corner,i_position,i_size,i_region,i_right,i_up,i_tint"
				&& variant.uniformBlocks.filter(b -> b.slot == 0)[0].size == Sprite3DProgram.vertexUniformBytes,
				'$name\'s sprite3D variant reads the 3D sprites\' records and uniforms');
			check(shader.sprite3D.handle != shader.handle && shader.sprite3D.textureSlots.join(",") == shader.textureSlots.join(","),
				'$name: the variant a program of its own, its textures the same');
			shader.destroy();
		}
		var surface = ShaderLibrary.get(gpu, "unlit", UnlitPacked.text());
		var refused = false;
		try
			new SpriteEffect(surface)
		catch (e:Dynamic)
			refused = true;
		check(refused, "A surface shader is no sprite effect");
	}

	// Runs split where the effect changes; one effect shared stays one draw; without one, a batch draws as it did.
	static function batching(gpu:CountingGraphics):Void {
		var batch = new Batch2D(gpu),
			texture = Texture2D.fromRgba(4, 4, Bytes.alloc(64), gpu),
			other = Texture2D.fromRgba(4, 4, Bytes.alloc(64), gpu),
			outline = new SpriteOutline(),
			flash = new SpriteFlash();
		var plain = Pipelines.of(gpu).sprite2D(Alpha);
		frame(gpu, batch, () -> {
			batch.sprite(texture, 10, 10, 4, 4);
			batch.sprite(texture, 20, 10, 4, 4);
		});
		check(gpu.draws.length == 1 && gpu.draws[0].pipeline == plain && gpu.draws[0].vertices == 12, "Without an effect, one draw of the sprite program");
		frame(gpu, batch, () -> {
			batch.effect = outline;
			batch.sprite(texture, 10, 10, 4, 4);
			batch.sprite(texture, 20, 10, 4, 4);
			batch.sprite(texture, 30, 10, 4, 4);
			batch.effect = null;
			batch.sprite(texture, 40, 10, 4, 4);
			batch.effect = outline;
			batch.sprite(texture, 50, 10, 4, 4);
			batch.effect = flash;
			batch.sprite(texture, 60, 10, 4, 4);
			batch.sprite(other, 70, 10, 4, 4);
		});
		var through = Pipelines.of(gpu).spriteEffect(outline.shader.handle, Alpha);
		check(gpu.draws.length == 5, 'Split where the effect or the texture changes: ${gpu.draws.length} draws');
		check(gpu.draws[0].pipeline == through && gpu.draws[0].vertices == 18 && gpu.draws[0].first == 0, "Three sprites sharing an effect, one draw");
		check(gpu.draws[1].pipeline == plain && gpu.draws[1].vertices == 6 && gpu.draws[1].first == 0, "Without it again, the sprite program");
		check(gpu.draws[2].pipeline == through && gpu.draws[2].first == 18, "Its vertices follow the effects' others in their own upload");
		check(gpu.draws[3].pipeline == Pipelines.of(gpu).spriteEffect(flash.shader.handle, Alpha)
			&& gpu.draws[4].first == 30
			&& gpu.draws[4].textures[0] == other.handle,
			"Another effect, then another texture: draws of their own");
		check(gpu.draws[0].buffers[0] != gpu.draws[1].buffers[0], "Effects draw from an upload of their own");
		var desc = gpu.describe(through);
		check(desc.buffers[0].stride == Effect2DProgram.stride
			&& desc.flip == ClipScale
			&& desc.depthTest == Off, "Effect2D's vertices, in clip space");
		check(batch.drawCallCount == 5 && batch.vertexCount == 42, "Counted with the others");
		var plainBytes = gpu.uploads[gpu.draws[1].buffers[0]];
		check(plainBytes.length == 6 * Sprite2DProgram.stride, "The sprite program's upload holds only what draws without an effect");
		frame(gpu, batch, () -> {
			batch.sprite(texture, 10, 10, 4, 4);
		});
		check(gpu.draws.length == 1 && gpu.draws[0].pipeline == plain, "An effect ends with the frame: begin starts without one");
	}

	// Each vertex drawn through an effect carries its sprite's region; a nine-slice's slices carry the whole one; the framework's block is the
	// texture's size and the batch's time.
	static function regions(gpu:CountingGraphics):Void {
		var batch = new Batch2D(gpu),
			texture = Texture2D.fromRgba(64, 32, Bytes.alloc(64 * 32 * 4), gpu),
			effect = new SpriteOutline();
		batch.time = 2.5;
		frame(gpu, batch, () -> {
			batch.effect = effect;
			batch.image(texture, 0, 0, 16, 16, 0xffffffff, 16, 8, 16, 16);
			batch.nineSlice(texture, 20, 0, 40, 40, 4, 4, 4, 4, 0xffffffff, 32, 0, 32, 32);
		});
		var bytes = gpu.uploads[gpu.draws[0].buffers[0]],
			stride = Effect2DProgram.stride,
			at = Effect2DProgram.regionOffset;
		check(near(bytes.getFloat(at), 16 / 64)
			&& near(bytes.getFloat(at + 4), 8 / 32)
			&& near(bytes.getFloat(at + 8), 32 / 64)
			&& near(bytes.getFloat(at + 12), 24 / 32),
			"An image's region, in texture coordinates");
		check(near(bytes.getFloat(5 * stride + at + 8), 32 / 64), "Each of its vertices carries it");
		var slices = Std.int(bytes.length / stride) - 6;
		check(slices == 54, 'A nine-slice is nine quads: $slices vertices');
		var whole = true;
		for (i in 6...6 + slices) {
			var p = i * stride + at;
			whole = whole && near(bytes.getFloat(p), .5) && near(bytes.getFloat(p + 4), 0) && near(bytes.getFloat(p + 8), 1) && near(bytes.getFloat(p + 12), 1);
		}
		check(whole, "Every slice of a nine-slice carries its whole region");
		var info = gpu.draws[0].uniforms[1];
		check(near(info.getFloat(0), 64) && near(info.getFloat(4), 32) && near(info.getFloat(8), 2.5), "Block 1: the texture's size and the batch's time");
	}

	// A stage draws its sprites through their effects at its time: sprites sharing one in a row, one draw; the stage leaves none set.
	static function stage(gpu:CountingGraphics):Void {
		var batch = new Batch2D(gpu),
			stage = new Renderer2D(),
			texture = Texture2D.fromRgba(8, 8, Bytes.alloc(256), gpu),
			outline = new SpriteOutline(0xffff0000, 2);
		for (i in 0...3) {
			var sprite = new Sprite2D(texture);
			sprite.setPosition(20 + i * 20, 20);
			if (i < 2)
				sprite.effect = outline;
			stage.add(sprite);
		}
		stage.time = 7;
		var camera = new Camera2D();
		camera.setViewport(400, 300);
		gpu.beginFrame(400, 300, 0);
		batch.begin(camera);
		stage.draw(batch, camera);
		check(batch.effect == null && batch.time == 7, "The stage leaves the batch without an effect, at its time");
		batch.sprite(texture, 100, 100, 8, 8);
		batch.end();
		var through = Pipelines.of(gpu).spriteEffect(outline.shader.handle, Alpha);
		check(gpu.draws.length == 2 && gpu.draws[0].pipeline == through && gpu.draws[0].vertices == 12 && gpu.draws[1].vertices == 12,
			"Two sprites sharing an effect are one draw; the third and what follows the stage, another");
	}

	// The members the classes write, at the reflection's offsets (sprite_outline_params: outline_color 0, width 16).
	static function outline(gpu:CountingGraphics):Void {
		var effect = new SpriteOutline(0x40ff8000, 3);
		var block = drawn(gpu, effect)[2];
		check(near(block.getFloat(0), 1) && near(block.getFloat(4), 128 / 255) && near(block.getFloat(8), 0) && near(block.getFloat(12), 64 / 255),
			"SpriteOutline's color: sRGB values as given");
		check(near(block.getFloat(16), 3), "SpriteOutline's width, texels");
		effect.width = -1;
		check(effect.width == 0 && near(drawn(gpu, effect)[2].getFloat(16), 0), "A width under 0 is 0");
		effect.width = 100;
		check(effect.width == 32, "A width past 32 is 32");
	}

	// A flash triggered fades over the batch's time from its first draw; an amount held stays.
	static function flash(gpu:CountingGraphics):Void {
		var effect = new SpriteFlash();
		check(near(drawn(gpu, effect, 1)[2].getFloat(12), 0), "No flash to start");
		check(effect.trigger(0x80ff0000, .5) && !effect.trigger(0xffffffff, 0), "A trigger needs seconds above 0");
		var block = drawn(gpu, effect, 10);
		check(near(block[2].getFloat(0), 1) && near(block[2].getFloat(4), 0) && near(block[2].getFloat(12), 128 / 255), "All of it at the first draw");
		check(near(drawn(gpu, effect, 10.25)[2].getFloat(12), 128 / 255 * .5), "Half way through, half of it");
		check(near(drawn(gpu, effect, 11)[2].getFloat(12), 0), "Gone once its seconds are past");
		check(effect.amount == 1, "Read during a fade, the amount is its start");
		effect.amount = .25;
		check(near(drawn(gpu, effect, 20)[2].getFloat(12), 128 / 255 * .25) && effect.amount == .25, "An amount held, whatever the time");
		effect.amount = 2;
		check(effect.amount == 1, "Clamped to 1");
	}

	// sprite_dissolve_params: edge_color 0, amount 16, edge_width 20, scale 24; the noise at slot 1, the library's by default.
	static function dissolve(gpu:CountingGraphics):Void {
		var effect = new SpriteDissolve();
		effect.amount = .4;
		effect.edgeWidth = .2;
		effect.scale = 3;
		effect.edgeColor = 0xff00ff00;
		var batch = new Batch2D(gpu),
			texture = Texture2D.fromRgba(4, 4, Bytes.alloc(64), gpu);
		frame(gpu, batch, () -> {
			batch.effect = effect;
			batch.sprite(texture, 10, 10, 4, 4);
		});
		var block = gpu.draws[0].uniforms[2];
		check(near(block.getFloat(4), 1)
			&& near(block.getFloat(16), .4)
			&& near(block.getFloat(20), .2)
			&& near(block.getFloat(24), 3),
			"SpriteDissolve's edge color, amount, edge width and scale");
		check(gpu.draws[0].textures[0] == texture.handle && gpu.draws[0].textures[1] == ShaderLibrary.getNoise(gpu).handle,
			"The sprite's texture at 0, the library's noise at 1");
		effect.amount = 3;
		check(effect.amount == 1, "Amount clamped to 0..1");
	}

	// palette_swap_params: row 0; the palette at slot 1.
	static function palette(gpu:CountingGraphics):Void {
		var colors = Texture2D.fromRgba(4, 3, Bytes.alloc(48), gpu),
			effect = new PaletteSwap(colors, 2);
		var batch = new Batch2D(gpu),
			texture = Texture2D.fromRgba(4, 4, Bytes.alloc(64), gpu);
		frame(gpu, batch, () -> {
			batch.effect = effect;
			batch.sprite(texture, 10, 10, 4, 4);
		});
		check(near(gpu.draws[0].uniforms[2].getFloat(0), 2)
			&& gpu.draws[0].textures[1] == colors.handle, "PaletteSwap's row, and its palette at 1");
		effect.row = -3;
		check(effect.row == 0, "A row under 0 is 0");
	}

	// A Renderer3D's sprites with an effect draw through its sprite3D variant: opaque ones grouped by effect within a texture, blended ones split
	// where it changes in their order back to front; block 0 the sprites' uniforms, block 1 the texture's size and the stage's time.
	static function stage3D(gpu:CountingGraphics):Void {
		var stage = new Renderer3D(gpu),
			camera = new Camera3D(),
			texture = Texture2D.fromRgba(8, 4, Bytes.alloc(128), gpu);
		camera.setViewport(800, 600);
		camera.setView(0, 0, 10, 0, 0, 0);
		var outline = new SpriteOutline(), flash = new SpriteFlash(), sprites = [];
		for (i in 0...4) {
			var sprite = new Sprite3D(texture);
			sprite.setAlphaMode(Opaque);
			sprite.setPosition(i - 2, 0, 0);
			sprite.effect = i % 2 == 0 ? outline : null;
			stage.add(sprite);
			sprites.push(sprite);
		}
		stage.time = 4.5;
		gpu.beginFrame(800, 600, 0);
		gpu.meshPipelines = [];
		gpu.meshDraws = [];
		stage.draw(camera);
		var plain = Pipelines.of(gpu).sprite3D(Opaque),
			through = Pipelines.of(gpu).spriteEffect3D(outline.shader.sprite3D.handle, Opaque);
		var ours = [
			for (i in 0...gpu.meshPipelines.length)
				if (gpu.meshPipelines[i] == plain || gpu.meshPipelines[i] == through) i
		];
		check(ours.length == 2 && gpu.meshDraws[ours[0]].instances == 2 && gpu.meshDraws[ours[1]].instances == 2,
			"Four opaque sprites, two with one effect: two draws of two");
		var drawn = gpu.meshDraws[ours[gpu.meshPipelines[ours[0]] == through ? 0 : 1]];
		check(drawn.uniforms[0].length == Sprite3DProgram.vertexUniformBytes
			&& near(drawn.uniforms[1].getFloat(0), 8)
			&& near(drawn.uniforms[1].getFloat(4), 4)
			&& near(drawn.uniforms[1].getFloat(8), 4.5),
			"The variant's block 0 the sprites' uniforms, block 1 the texture's size and the stage's time");
		check(gpu.describe(through).indexed && gpu.describe(through).depthWrite, "Drawn as the 3D sprites are: indexed, an opaque one writing depth");
		// Blended, back to front: the effect changing twice along the way, three draws.
		for (i in 0...3) {
			sprites[i].setAlphaMode(Blend);
			sprites[i].setPosition(0, 0, -i);
			sprites[i].effect = i == 1 ? flash : outline;
		}
		sprites[3].visible = false;
		gpu.meshPipelines = [];
		gpu.meshDraws = [];
		stage.draw(camera);
		var blended = [
			for (p in gpu.meshPipelines)
				if (p == Pipelines.of(gpu).sprite3D(Alpha)
					|| p == Pipelines.of(gpu).spriteEffect3D(outline.shader.sprite3D.handle, Alpha)
					|| p == Pipelines.of(gpu).spriteEffect3D(flash.shader.sprite3D.handle, Alpha)) p
		];
		check(blended.length == 3 && blended[0] == blended[2] && blended[0] != blended[1], "Blended: split where the effect changes, back to front");
	}

	// The uniform blocks of a sprite drawn through effect at time.
	static function drawn(gpu:CountingGraphics, effect:SpriteEffect, time = 0.):Array<Null<Bytes>> {
		var batch = new Batch2D(gpu),
			texture = Texture2D.fromRgba(4, 4, Bytes.alloc(64), gpu);
		batch.time = time;
		frame(gpu, batch, () -> {
			batch.effect = effect;
			batch.sprite(texture, 10, 10, 4, 4);
		});
		return gpu.draws[0].uniforms;
	}
}
