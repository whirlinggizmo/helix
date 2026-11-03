import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Extras.*;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Runtime;

// helix-raylib's GIF images, printed as ref.c prints raylib 5.5's, for tools/raylib_parity.py. Where raylib gives an image of no frames or
// no data, or a texture of id 0 (a file it can't read), helix-raylib's load fails: its failure is printed as 0 frames, or none.
@:access(helix.raylib.internal.Runtime)
class ImageBits {
	static function pump(done:Void->Bool) {
		for (_ in 0...10000) {
			if (done())
				return;
			Runtime.pollAll();
			var now = Runtime.waiting;
			Runtime.waiting = [];
			for (f in now)
				f();
		}
		throw "never answered";
	}

	// An animation's frame count, then its frames as one image, one above the next, as ref.c prints them.
	static function anim(name:String, im:Null<Image>, frames:Int) {
		Parity.line('$name frames ${im == null ? 0 : frames}');
		if (im != null)
			Parity.image(name, new Image(im.data, im.width, im.height * frames, im.mipmaps, im.format));
	}

	// The answer of a load: the image, or null for a failure, and the frame count it set.
	static function answer(load:(frames:Array<Int>, loaded:Image->Void, failed:String->Void) -> Void):{image:Null<Image>, frames:Int} {
		var frames = [-1], image:Null<Image> = null, done = false;
		load(frames, i -> {
			image = i;
			done = true;
		}, _ -> done = true);
		pump(() -> done);
		return {image: image, frames: frames[0]};
	}

	static function bytes(fileName:String):haxe.io.Bytes {
		var data:haxe.io.Bytes = null;
		Runtime.assets.load(fileName, d -> data = d, e -> throw e);
		pump(() -> data != null);
		return data;
	}

	// An image LoadImageAsync or LoadImageFromMemoryAsync gives, as ref.c prints raylib's: its failure as none.
	static function still(name:String, load:(loaded:Image->Void, failed:String->Void)->Void) {
		var image:Null<Image> = null, done = false;
		load(i -> {
			image = i;
			done = true;
		}, _ -> done = true);
		pump(() -> done);
		if (image == null)
			Parity.line('$name none');
		else
			Parity.image(name, image);
	}

	// A texture LoadTextureAsync gives, as ref.c prints raylib's: its failure as none, else its pixels read back.
	static function texture(name:String, load:(loaded:Texture2D->Void, failed:String->Void)->Void) {
		var t:Null<Texture2D> = null, done = false;
		load(loaded -> {
			t = loaded;
			done = true;
		}, _ -> done = true);
		pump(() -> done);
		if (t == null || t.id == 0) {
			Parity.line('$name none');
			return;
		}
		Parity.line('$name texture ${t.width} ${t.height} ${t.mipmaps} ${t.format}');
		var im:Null<Image> = null;
		LoadImageFromTextureAsync(t, i -> im = i, e -> throw e);
		pump(() -> im != null);
		Parity.image(name, im);
		UnloadTexture(t);
	}

	// A font LoadFontAsync gives, as ref.c prints raylib's.
	static function font(name:String, load:(loaded:Font->Void, failed:String->Void)->Void) {
		var f:Null<Font> = null, done = false;
		load(loaded -> {
			f = loaded;
			done = true;
		}, _ -> done = true);
		pump(() -> done);
		if (f == null)
			f = GetFontDefault();
		Parity.line('$name font ${f.baseSize} ${f.glyphCount} ${f.glyphPadding} default ${f.texture.id == GetFontDefault().texture.id ? 1 : 0} texture ${f.texture.width} ${f.texture.height}');
		for (i in 0...f.glyphCount) {
			var g = f.glyphs[i], r = f.recs[i];
			Parity.line('$name glyph $i ${g.value} ${g.offsetX} ${g.offsetY} ${g.advanceX} rec ${r.x} ${r.y} ${r.width} ${r.height}');
			Parity.image('$name glyph $i', g.image);
		}
	}

	// A name or type made as the program runs, so the reader is chosen then.
	static function made(text:String):String
		return text.split("|").join("");

	static function main() {
		SetTraceLogLevel(LOG_NONE);
		var gr = new StubGraphics();
		Runtime.graphics = gr;
		Runtime.frame = new Frame(gr);
		var files = new DiskFiles(), decoder = new PngDecoder();
		Runtime.polled.push(files);
		Runtime.polled.push(decoder);
		Runtime.assets = new helix.services.assets.Assets([new helix.services.assets.FileSystemSource(files)]);
		Runtime.decoding = new helix.services.images.Images(decoder, Runtime.assets);
		Runtime.polled.push(Runtime.decoding);
		var a = answer((f, l, e) -> LoadImageAnimAsync("still.gif", f, l, e));
		anim("still", a.image, a.frames);
		a = answer((f, l, e) -> LoadImageAnimAsync("anim.gif", f, l, e));
		anim("anim", a.image, a.frames);
		a = answer((f, l, e) -> LoadImageAnimAsync("dispose.gif", f, l, e));
		anim("dispose", a.image, a.frames);
		a = answer((f, l, e) -> LoadImageAnimAsync("transparent.gif", f, l, e));
		anim("transparent", a.image, a.frames);
		a = answer((f, l, e) -> LoadImageAnimAsync("large.gif", f, l, e));
		anim("large", a.image, a.frames);
		a = answer((f, l, e) -> LoadImageAnimAsync("pil.gif", f, l, e));
		anim("pil", a.image, a.frames);
		a = answer((f, l, e) -> LoadImageAnimAsync("empty.gif", f, l, e));
		anim("empty", a.image, a.frames);
		a = answer((f, l, e) -> LoadImageAnimAsync("broken.gif", f, l, e));
		anim("broken", a.image, a.frames);
		a = answer((f, l, e) -> LoadImageAnimAsync("nothere.gif", f, l, e));
		anim("missing", a.image, a.frames);
		a = answer((f, l, e) -> LoadImageAnimAsync("still.png", f, l, e));
		anim("png", a.image, a.frames);
		a = answer((f, l, e) -> LoadImageAnimAsync(made("dispose|.gif"), f, l, e));
		anim("named", a.image, a.frames);
		var data = bytes("transparent.gif");
		a = answer((f, l, e) -> LoadImageAnimFromMemoryAsync(".gif", data, data.length, f, l, e));
		anim("memory", a.image, a.frames);
		data = bytes("anim.gif");
		a = answer((f, l, e) -> LoadImageAnimFromMemoryAsync(".GIF", data, data.length, f, l, e));
		anim("memoryupper", a.image, a.frames);
		data = bytes("still.png");
		a = answer((f, l, e) -> LoadImageAnimFromMemoryAsync(".png", data, data.length, f, l, e));
		anim("memorypng", a.image, a.frames);
		data = bytes("pil.gif");
		a = answer((f, l, e) -> LoadImageAnimFromMemoryAsync(made(".|gif"), data, data.length, f, l, e));
		anim("memorytyped", a.image, a.frames);
		data = bytes("broken.gif");
		a = answer((f, l, e) -> LoadImageAnimFromMemoryAsync(".gif", data, data.length, f, l, e));
		anim("memorybroken", a.image, a.frames);
		still("first still", (l, e) -> LoadImageAsync("still.gif", l, e));
		still("first anim", (l, e) -> LoadImageAsync("anim.gif", l, e));
		still("first dispose", (l, e) -> LoadImageAsync("dispose.gif", l, e));
		still("first transparent", (l, e) -> LoadImageAsync("transparent.gif", l, e));
		still("first large", (l, e) -> LoadImageAsync("large.gif", l, e));
		still("first pil", (l, e) -> LoadImageAsync("pil.gif", l, e));
		still("first empty", (l, e) -> LoadImageAsync("empty.gif", l, e));
		still("first broken", (l, e) -> LoadImageAsync("broken.gif", l, e));
		still("first missing", (l, e) -> LoadImageAsync("nothere.gif", l, e));
		still("first named", (l, e) -> LoadImageAsync(made("large|.gif"), l, e));
		still("first namedpng", (l, e) -> LoadImageAsync(made("still|.png"), l, e));
		data = bytes("transparent.gif");
		still("first memory", (l, e) -> LoadImageFromMemoryAsync(".gif", data, data.length, l, e));
		data = bytes("anim.gif");
		still("first memoryupper", (l, e) -> LoadImageFromMemoryAsync(".GIF", data, data.length, l, e));
		data = bytes("dispose.gif");
		still("first memorytyped", (l, e) -> LoadImageFromMemoryAsync(made(".|gif"), data, data.length, l, e));
		still("first memorymixed", (l, e) -> LoadImageFromMemoryAsync(".Gif", data, data.length, l, e));
		var broken = bytes("broken.gif");
		still("first memorybroken", (l, e) -> LoadImageFromMemoryAsync(".gif", broken, broken.length, l, e));
		data = bytes("still.png");
		still("first memorypng", (l, e) -> LoadImageFromMemoryAsync(made(".|png"), data, data.length, l, e));
		texture("texture anim", (l, e) -> LoadTextureAsync("anim.gif", l, e));
		texture("texture large", (l, e) -> LoadTextureAsync("large.gif", l, e));
		texture("texture named", (l, e) -> LoadTextureAsync(made("pil|.gif"), l, e));
		texture("texture empty", (l, e) -> LoadTextureAsync("empty.gif", l, e));
		texture("texture broken", (l, e) -> LoadTextureAsync("broken.gif", l, e));
		font("font gif", (l, e) -> LoadFontAsync("font.gif", l, e));
		font("font named", (l, e) -> LoadFontAsync(made("font|.gif"), l, e));
		Parity.save();
	}
}
