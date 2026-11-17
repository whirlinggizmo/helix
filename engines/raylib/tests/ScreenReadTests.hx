import haxe.io.Bytes;
import helix.platform.*;
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Rlgl.*;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Runtime;
import helix.services.screen.Screen;
import helix.services.time.Time;

/** Checks the screen reads that wait, `LoadImageFromTexture` and `LoadImageFromScreen`, on graphics that paint each target and the screen
	in one color, counting the draws into it. A render texture drawn then read holds its clear and its draws, its frame's screen pass left
	to the frame's end; drawn into again and read, it holds both passes' draws. The screen read part way through a frame holds the frame's
	clear and the draws drawn so far, not those still in rlgl's batch, at the framebuffer's size; the frame goes on in the same target,
	the later draws on top, and is copied to the screen without blending as it ends. Every frame after draws into the target and is
	copied to the screen, its scissors at the framebuffer's scale, so a read between frames holds the frame last shown; a frame drawn
	without a clear or a read is black. Once the framebuffer's size changes, the target is made again at it, and a read before the next
	frame is black. A new window's first read, between frames, is black. Before `InitWindow`, the screen read logs why and gives an empty
	image. Run by helix.py test on Node and natively. */
@:access(helix.raylib.internal.Runtime)
class ScreenReadTests {
	public static var checks = 0;

	public static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function report(_:Int):Void {
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}

	static function main():Void {
		Runtime.exitKey = 0;
		Runtime.system = new FakeSystem();
		Runtime.time = new Time(Runtime.system);
		#if js
		Runtime.requestFrame = f -> haxe.Timer.delay(() -> f(0), 0);
		(ScreenReads.all() : Dynamic).then(report, error -> {
			js.Syntax.code("console.log({0})", Std.string(error));
			js.Syntax.code("process.exit(1)");
		});
		#else
		report(ScreenReads.all());
		#end
	}
}

/** The reads, built as a program's classes are. */
@:build(helix.raylib.internal.Wait.build())
@:access(helix.raylib.internal.Runtime)
class ScreenReads {
	/** Runs every read and checks it.

		@return  The checks made. */
	public static function all():Int {
		var warnings:Array<String> = [];
		SetTraceLogLevel(LOG_WARNING);
		SetTraceLogCallback((level, text) -> if (level == LOG_WARNING) warnings.push(text));
		var early = LoadImageFromScreen();
		ScreenReadTests.check(early.data == null && early.width == 0 && warnings.join(",") == "LoadImageFromScreen: InitWindow first",
			'before InitWindow, an empty image and the reason logged: $warnings');

		var graphics = new PaintingGraphics();
		Runtime.graphics = graphics;
		Runtime.frame = new Frame(graphics);
		var window = new FakeWindow();
		window.logicalWidth = 8;
		window.logicalHeight = 6;
		window.ratio = 2;
		Runtime.window = window;
		Runtime.events = new FakeEvents();
		Runtime.screen = new Screen(window, Runtime.events);
		var red = new Color(200, 0, 0, 255);

		// A render texture drawn, then read, while the frame's screen pass waits for the frame's end.
		var target = LoadRenderTexture(4, 2);
		BeginDrawing();
		ClearBackground(new Color(1, 2, 3, 255));
		DrawRectangle(0, 0, 2, 2, red);
		BeginTextureMode(target);
		ClearBackground(new Color(10, 20, 0, 128));
		DrawRectangle(0, 0, 2, 2, red);
		EndTextureMode();
		graphics.log.resize(0);
		var image = LoadImageFromTexture(target.texture);
		ScreenReadTests.check(graphics.log.join(",") == 'clear ${target.id},draw ${target.id},end,read ${target.id}',
			'the render texture\'s pass drawn, then read; the screen\'s pass not yet: ${graphics.log}');
		ScreenReadTests.check(image.width == 4 && image.height == 2 && image.format == PIXELFORMAT_UNCOMPRESSED_R8G8B8A8,
			'the texture\'s size, RGBA: ${image.width} x ${image.height}, ${image.format}');
		ScreenReadTests.check(pixel(image, 3, 1) == "10 20 1 128", 'its clear and its one draw: ${pixel(image, 3, 1)}');

		// Drawn into again in the same frame: the pass goes on over what the target holds.
		BeginTextureMode(target);
		DrawRectangle(0, 0, 2, 2, red);
		EndTextureMode();
		graphics.log.resize(0);
		image = LoadImageFromTexture(target.texture);
		ScreenReadTests.check(graphics.log.join(",") == 'resume ${target.id},draw ${target.id},end,read ${target.id}',
			'the second pass resumes the target: ${graphics.log}');
		ScreenReadTests.check(pixel(image, 0, 0) == "10 20 2 128", 'both passes\' draws: ${pixel(image, 0, 0)}');
		graphics.log.resize(0);
		EndDrawing();
		ScreenReadTests.check(graphics.log.join(",") == "frame,draw 0,endFrame",
			'the frame\'s end draws the screen\'s pass alone, the render texture passes already drawn: ${graphics.log}');
		ScreenReadTests.check(graphics.painted(0) == "1 2 1", 'the screen: ${graphics.painted(0)}');

		// The screen read part way through a frame: what is drawn so far, the batch still waiting left out.
		BeginDrawing();
		ClearBackground(new Color(30, 40, 0, 255));
		DrawRectangle(0, 0, 2, 2, red);
		rlDrawRenderBatchActive();
		DrawRectangle(2, 2, 2, 2, red);
		graphics.log.resize(0);
		var shot = LoadImageFromScreen();
		var held = graphics.targets[graphics.targets.length - 1];
		ScreenReadTests.check(graphics.log.join(",") == 'target $held 16 x 12,clear $held,draw $held,end,read $held',
			'the screen\'s pass drawn into a target of the framebuffer\'s size, then read: ${graphics.log}');
		ScreenReadTests.check(shot.width == 16 && shot.height == 12 && shot.format == PIXELFORMAT_UNCOMPRESSED_R8G8B8A8,
			'the framebuffer\'s size, RGBA: ${shot.width} x ${shot.height}, ${shot.format}');
		ScreenReadTests.check(pixel(shot, 15, 11) == "30 40 1 255", 'the clear and the draw drawn so far, opaque: ${pixel(shot, 15, 11)}');

		// The frame goes on in the target, then the target is copied to the screen.
		DrawRectangle(4, 4, 2, 2, red);
		graphics.log.resize(0);
		EndDrawing();
		ScreenReadTests.check(graphics.log.join(",") == 'resume $held,draw $held,end,frame,copy $held,endFrame',
			'the frame goes on over the target and is copied to the screen: ${graphics.log}');
		ScreenReadTests.check(graphics.painted(0) == "30 40 2", 'the screen holds the frame, the later draws on top: ${graphics.painted(0)}');
		ScreenReadTests.check(graphics.copyBlend == Blend.OPAQUE, "the copy doesn't blend");

		// The next frame draws into the target too, and is copied to the screen.
		BeginDrawing();
		ClearBackground(new Color(50, 60, 0, 255));
		DrawRectangle(0, 0, 2, 2, red);
		graphics.log.resize(0);
		EndDrawing();
		ScreenReadTests.check(graphics.log.join(",") == 'clear $held,draw $held,end,frame,copy $held,endFrame',
			'the next frame draws into the target, copied to the screen: ${graphics.log}');
		ScreenReadTests.check(graphics.painted(0) == "50 60 1", 'the screen shows the next frame: ${graphics.painted(0)}');

		// Read between frames: the frame last shown, the target resumed and nothing drawn.
		graphics.log.resize(0);
		shot = LoadImageFromScreen();
		ScreenReadTests.check(graphics.log.join(",") == 'resume $held,end,read $held', 'between frames, the target read as it is: ${graphics.log}');
		ScreenReadTests.check(shot.width == 16 && shot.height == 12 && pixel(shot, 3, 3) == "50 60 1 255",
			'between frames, the frame last shown: ${shot.width} x ${shot.height}, ${pixel(shot, 3, 3)}');

		// A frame drawn without a clear after that read goes on over the frame last shown, as raylib's screen keeps it.
		BeginDrawing();
		DrawRectangle(0, 0, 2, 2, red);
		graphics.log.resize(0);
		EndDrawing();
		ScreenReadTests.check(graphics.log.join(",") == 'resume $held,draw $held,end,frame,copy $held,endFrame',
			'the frame goes on over what was read: ${graphics.log}');
		ScreenReadTests.check(graphics.painted(0) == "50 60 2", 'the screen: ${graphics.painted(0)}');

		// A frame drawn without a clear or a read is black, as the screen's are; its scissor at the framebuffer's scale.
		BeginDrawing();
		BeginScissorMode(1, 1, 2, 2);
		DrawRectangle(0, 0, 2, 2, red);
		EndScissorMode();
		graphics.log.resize(0);
		graphics.scissors.resize(0);
		EndDrawing();
		ScreenReadTests.check(graphics.log.join(",") == 'clear $held,draw $held,end,frame,copy $held,endFrame',
			'a frame not cleared clears the target: ${graphics.log}');
		ScreenReadTests.check(graphics.painted(0) == "0 0 1", 'the screen, black: ${graphics.painted(0)}');
		ScreenReadTests.check(graphics.scissors.join(",") == "2 6 4 4", 'the scissor in framebuffer pixels: ${graphics.scissors}');

		// Read twice in a frame: the second read goes on in the same target.
		BeginDrawing();
		ClearBackground(new Color(70, 80, 0, 255));
		DrawRectangle(0, 0, 2, 2, red);
		rlDrawRenderBatchActive();
		LoadImageFromScreen();
		DrawRectangle(0, 0, 2, 2, red);
		rlDrawRenderBatchActive();
		graphics.log.resize(0);
		shot = LoadImageFromScreen();
		ScreenReadTests.check(graphics.log.join(",") == 'resume $held,draw $held,end,read $held', 'the second read resumes: ${graphics.log}');
		ScreenReadTests.check(pixel(shot, 0, 0) == "70 80 2 255", 'both reads\' draws: ${pixel(shot, 0, 0)}');
		EndDrawing();
		ScreenReadTests.check(graphics.painted(0) == "70 80 2", 'the screen: ${graphics.painted(0)}');

		// The framebuffer's size changed between frames: the target made again at it, the read black.
		window.logicalWidth = 10;
		graphics.log.resize(0);
		shot = LoadImageFromScreen();
		var resized = graphics.targets[graphics.targets.length - 1];
		ScreenReadTests.check(resized != held && graphics.log.join(",") == 'target $resized 20 x 12,clear $resized,end,read $resized',
			'a target of the new size, cleared, then read: ${graphics.log}');
		ScreenReadTests.check(shot.width == 20 && shot.height == 12 && pixel(shot, 19, 11) == "0 0 0 255",
			'the new size, black: ${shot.width} x ${shot.height}, ${pixel(shot, 19, 11)}');
		BeginDrawing();
		ClearBackground(new Color(90, 100, 0, 255));
		DrawRectangle(0, 0, 2, 2, red);
		graphics.log.resize(0);
		EndDrawing();
		ScreenReadTests.check(graphics.log.join(",") == 'clear $resized,draw $resized,end,frame,copy $resized,endFrame',
			'the frame after draws into the new target: ${graphics.log}');
		ScreenReadTests.check(graphics.painted(0) == "90 100 1", 'the screen: ${graphics.painted(0)}');

		// Resized with no read: the frame's end makes the target again.
		window.logicalWidth = 12;
		BeginDrawing();
		ClearBackground(new Color(110, 120, 0, 255));
		graphics.log.resize(0);
		EndDrawing();
		var again = graphics.targets[graphics.targets.length - 1];
		ScreenReadTests.check(again != resized
			&& graphics.log.join(",") == 'target $again 24 x 12,clear $again,end,frame,copy $again,endFrame',
			'a target of the new size, drawn into: ${graphics.log}');
		ScreenReadTests.check(graphics.painted(0) == "110 120 0", 'the screen: ${graphics.painted(0)}');

		// A new window's first read, between frames, before a frame was kept: black.
		Runtime.frame = new Frame(graphics);
		BeginDrawing();
		ClearBackground(new Color(130, 140, 0, 255));
		EndDrawing();
		graphics.log.resize(0);
		shot = LoadImageFromScreen();
		var fresh = graphics.targets[graphics.targets.length - 1];
		ScreenReadTests.check(graphics.log.join(",") == 'target $fresh 24 x 12,clear $fresh,end,read $fresh'
			&& pixel(shot, 0, 0) == "0 0 0 255",
			'the first read between frames, black: ${graphics.log}, ${pixel(shot, 0, 0)}');
		BeginDrawing();
		ClearBackground(new Color(150, 160, 0, 255));
		graphics.log.resize(0);
		EndDrawing();
		ScreenReadTests.check(graphics.log.join(",") == 'clear $fresh,end,frame,copy $fresh,endFrame'
			&& graphics.painted(0) == "150 160 0",
			'the frame after draws into the target: ${graphics.log}, ${graphics.painted(0)}');
		return ScreenReadTests.checks;
	}

	// A pixel's channels, "r g b a".
	static function pixel(image:Image, x:Int, y:Int):String {
		var at = (y * image.width + x) * 4;
		return '${image.data.get(at)} ${image.data.get(at + 1)} ${image.data.get(at + 2)} ${image.data.get(at + 3)}';
	}
}

// Graphics painting each render target and the screen in one color, its clear's, counting the draws into it; a draw sampling a render
// target copies the target over the screen. Read back, a target is its color with the count in blue. Its passes are logged.
private class PaintingGraphics extends CountingGraphics {
	/** The passes' calls, the draws named by what they draw into. */
	public final log:Array<String> = [];

	/** The render targets made, in order. */
	public final targets:Array<Int> = [];

	/** The scissors applied, "x y width height" each. */
	public final scissors:Array<String> = [];

	/** The blending of the pipeline the last copy drew through. */
	public var copyBlend:Null<Blend> = null;

	final colors = new Map<Int, Int>();
	final counts = new Map<Int, Int>();
	final widths = new Map<Int, Int>();
	final heights = new Map<Int, Int>();
	final blends = new Map<Int, Blend>();
	var current = -1;

	/** Returns a target's or the screen's (0) color and count, "r g count".

		@param handle  The target, or 0.
		@return  The color's red and green, and the draws. */
	public function painted(handle:Int):String {
		var color = colors.get(handle);
		return '${color >> 16 & 255} ${color >> 8 & 255} ${counts.get(handle)}';
	}

	override public function createRenderTarget(width:Int, height:Int, format:TextureFormat = Rgba8, depth:helix.platform.RenderTargetDepth = Buffer,
			msaaSampleCount:Int = 0, bottomRowFirst:Bool = false):Int {
		var handle = super.createRenderTarget(width, height, format, depth, msaaSampleCount, bottomRowFirst);
		targets.push(handle);
		widths.set(handle, width);
		heights.set(handle, height);
		colors.set(handle, 0);
		counts.set(handle, 0);
		log.push('target $handle $width x $height');
		return handle;
	}

	override public function createPipeline(desc:PipelineDesc):Int {
		var handle = super.createPipeline(desc);
		blends.set(handle, desc.blend);
		return handle;
	}

	override public function beginTargetPass(target:Int, red:Float, green:Float, blue:Float, alpha:Float):Void {
		current = target;
		colors.set(target, Math.round(alpha * 255) << 24 | Math.round(red * 255) << 16 | Math.round(green * 255) << 8 | Math.round(blue * 255));
		counts.set(target, 0);
		log.push('clear $target');
	}

	override public function resumeTargetPass(target:Int):Void {
		current = target;
		log.push('resume $target');
	}

	override public function endTargetPass():Void {
		current = -1;
		log.push("end");
	}

	override public function beginFrame(width:Int, height:Int, clearColor:Int):Void {
		current = 0;
		colors.set(0, clearColor);
		counts.set(0, 0);
		log.push("frame");
	}

	override public function endFrame():Void {
		current = -1;
		log.push("endFrame");
	}

	override public function draw(pipeline:Int, buffers:Array<Int>, bufferOffsets:Null<Array<Int>>, indexBuffer:Int, firstElementIndex:Int, elementCount:Int,
			firstInstanceIndex:Int, instanceCount:Int, textures:Array<Int>, samplings:Array<Sampling>, uniforms:Array<Null<Bytes>>):Void {
		for (t in textures)
			if (widths.exists(t)) {
				colors.set(current, colors.get(t));
				counts.set(current, counts.get(t));
				copyBlend = blends.get(pipeline);
				log.push('copy $t');
				return;
			}
		counts.set(current, counts.get(current) + 1);
		log.push('draw $current');
	}

	override public function applyScissor(x:Int, y:Int, w:Int, h:Int):Void {
		scissors.push('$x $y $w $h');
	}

	override public function readPixels(handle:Int, read:(pixels:Bytes, width:Int, height:Int) -> Void, failed:String->Void):Void {
		log.push('read $handle');
		var width = widths.get(handle),
			height = heights.get(handle),
			color = colors.get(handle);
		var pixels = Bytes.alloc(width * height * 4);
		for (i in 0...width * height) {
			pixels.set(i * 4, color >> 16 & 255);
			pixels.set(i * 4 + 1, color >> 8 & 255);
			pixels.set(i * 4 + 2, counts.get(handle));
			pixels.set(i * 4 + 3, color >>> 24);
		}
		read(pixels, width, height);
	}
}
