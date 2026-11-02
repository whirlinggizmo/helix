import helix.ray.*;
import helix.ray.Raylib.*;
import helix.ray.internal.Frame;
import helix.ray.internal.Runtime;

// helix-ray's animated images, printed as ref.c prints raylib 5.5's, for tools/ray_parity.py. Where raylib gives an image of no
// frames (a file it can't read), LoadImageAnimAsync fails: its failure is printed as 0 frames.
@:access(helix.ray.internal.Runtime)
class ImageAnimBits {
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
		Runtime.assets = new helix.services.assets.Assets({sources: [FileSystem(files)]});
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
		Parity.save();
	}
}
