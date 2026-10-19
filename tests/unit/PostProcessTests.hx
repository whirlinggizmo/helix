import Render2DTests.CountingGraphics;
import helix.graphics.Graphics;
import helix.graphics.PostProcess;
import helix.graphics.ScreenEffect;
import helix.graphics.ScreenFrame;
import helix.graphics.Shader;
import helix.graphics.TextureFormat;
import helix.render3d.Stage3D;
import helix.shaders.Tonemap;

/** An effect of several passes: intermediates at the fractions given, each drawn into from the one before (the first from the frame). */
class Steps extends ScreenEffect {
	public function new(gpu:CountingGraphics, shader:Shader, fractions:Array<Float>) {
		super(gpu, shader);
		intermediates = fractions;
	}

	override public function drawIntermediates(frame:ScreenFrame):Void {
		var from = frame.source;
		for (t in frame.intermediates) {
			drawInto(t, from, frame.time);
			from = t;
		}
	}
}

/** PostProcess's plan: which textures a chain gets, at which sizes and in which formats, and which of them each pass draws into, on graphics
	that only counts: an 8-bit chain, intermediates at fractions of the screen, an HDR chain with its tone mapping added (and without half
	floats, none), the order kept through add and remove, and sizes following the screen. */
class PostProcessTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static var gpu:CountingGraphics;
	static var shader:Shader;

	// The target a pass drew into, by its place in this frame's passes.
	static function pass(i:Int):{
		width:Int,
		height:Int,
		format:TextureFormat,
		depth:Bool
	}
		return gpu.renderTargets[gpu.targetPasses[i]];

	// A frame of post at width x height, the passes counted from its start.
	static function frame(post:PostProcess, width:Int, height:Int):Void {
		gpu.targetPasses = [];
		post.beginScene(width, height, 0x000000ff);
		post.endScene(1);
		gpu.beginFrame(width, height, 0x000000ff);
		post.present();
	}

	static function main():Void {
		gpu = new CountingGraphics();
		@:privateAccess Graphics.bind(gpu);
		var stages = {vertex: "", fragment: ""};
		var text = haxe.Json.stringify({
			helixShader: 2,
			kind: "screen",
			attributes: [],
			glsl410: stages,
			glsl300es: stages,
			uniformBlocks: [
				{
					slot: 0,
					stage: "vertex",
					size: 16,
					glslName: "v",
					vec4s: 1,
					name: "helix_screen_vs_params"
				},
				{
					slot: 1,
					stage: "fragment",
					size: 16,
					glslName: "f",
					vec4s: 1,
					name: "helix_screen_params"
				}
			],
			textures: [
				{
					slot: 0,
					stage: "fragment",
					name: "helix_screen_texture",
					glslName: "a"
				}
			]
		});
		shader = Shader.fromText(gpu, text);

		// No effect: the scene alone, RGBA8 with depth at the screen's size, copied to the screen.
		var post = new PostProcess(gpu);
		frame(post, 800, 600);
		check(gpu.targetPasses.length == 1
			&& pass(0).width == 800
			&& pass(0).height == 600
			&& pass(0).format == Rgba8
			&& pass(0).depth,
			"Without effects the scene is one RGBA8 texture with depth, the screen's size");
		check(gpu.draws.length == 1 && gpu.draws[0].vertices == 6, "The scene is copied to the screen as it is");

		// Two effects, 8 bits: the first draws into a texture of the chain without depth, the last over the screen.
		var a = new ScreenEffect(gpu, shader),
			b = new ScreenEffect(gpu, shader);
		check(post.add(a) && post.add(b) && !post.add(a), "Effects are added once");
		frame(post, 800, 600);
		check(!post.hdr && gpu.targetPasses.length == 2 && pass(0).format == Rgba8 && pass(0).depth, "An 8-bit chain's scene is RGBA8 with depth");
		check(pass(1).width == 800 && pass(1).height == 600 && pass(1).format == Rgba8 && !pass(1).depth,
			"The chain's textures are the screen's size, RGBA8, without depth");
		var c = new ScreenEffect(gpu, shader);
		post.add(c);
		frame(post, 800, 600);
		check(gpu.targetPasses.length == 3 && gpu.targetPasses[1] != gpu.targetPasses[2] && !pass(2).depth,
			"Three effects draw back and forth between two textures");
		b.enabled = false;
		frame(post, 800, 600);
		check(gpu.targetPasses.length == 2, "An effect turned off is skipped");
		b.enabled = true;
		check(post.remove(c) && !post.remove(c), "An effect is removed once");

		// Intermediates: fractions of the screen each way, rounded down, at least a pixel, in the frame's format, without depth; the last
		// effect's drawn before the screen's pass too.
		var steps = new Steps(gpu, shader, [.5, .25, .001]);
		post.add(steps);
		frame(post, 801, 601);
		check(gpu.targetPasses.length == 6, "The scene, two effects' passes and the last effect's three intermediates are drawn before the screen");
		check(pass(3).width == 400 && pass(3).height == 300 && pass(4).width == 200 && pass(4).height == 150 && pass(5).width == 1 && pass(5).height == 1,
			"Intermediates are their fractions of the screen, rounded down, at least a pixel");
		check(pass(3).format == Rgba8 && !pass(3).depth, "An 8-bit chain's intermediates are RGBA8 without depth");
		var made = Lambda.count(gpu.renderTargets);
		frame(post, 801, 601);
		check(Lambda.count(gpu.renderTargets) == made, "The same size makes nothing again");
		var destroyed = gpu.destroyedTextures;
		frame(post, 640, 480);
		check(gpu.destroyedTextures - destroyed == 6
			&& pass(0).width == 640
			&& pass(3).width == 320, "A new size makes every texture again");
		destroyed = gpu.destroyedTextures;
		post.remove(steps);
		check(gpu.destroyedTextures - destroyed == 3, "A removed effect's intermediates are freed");

		// HDR: an effect wanting it opens the scene in half floats, its stage told so while the scene is drawn; the tone mapping follows the last
		// effect wanting HDR (with the stage's mode), the ones before it drawing half floats, the ones after it RGBA8.
		var stage = new Stage3D(gpu);
		stage.tonemap = Aces;
		var hdrPost = new PostProcess(gpu, stage);
		var bright = new Steps(gpu, shader, [.5]);
		bright.hdr = true;
		var after = new ScreenEffect(gpu, shader);
		hdrPost.add(bright);
		hdrPost.add(after);
		gpu.targetPasses = [];
		hdrPost.beginScene(800, 600, 0x000000ff);
		check(hdrPost.hdr && stage.hdr, "An effect wanting HDR draws the scene HDR, its stage told so");
		hdrPost.endScene(1);
		check(!stage.hdr, "The stage is told only while the scene is drawn");
		check(pass(0).format == Rgba16f && pass(0).depth, "An HDR scene is half floats with depth");
		check(gpu.targetPasses.length == 4 && pass(1).format == Rgba16f && pass(1).width == 400 && !pass(1).depth,
			"The scene, the HDR effect's intermediate in half floats, its pass, the tone mapping's");
		check(pass(2).format == Rgba16f && !pass(2).depth && pass(3).format == Rgba8 && !pass(3).depth,
			"Before the tone mapping the chain is half floats, from it on RGBA8");
		var tonemap:Tonemap = @:privateAccess hdrPost.tonemap;
		check(tonemap != null && tonemap.mode == Aces && @:privateAccess hdrPost.steps[1] == tonemap, "The tone mapping added takes the stage's mode");

		// Without half floats: 8 bits throughout, no tone mapping added, and a Tonemap of the chain's own skipped.
		gpu.floatTargets = false;
		var own = new Tonemap();
		hdrPost.add(own);
		frame(hdrPost, 800, 600);
		check(!hdrPost.hdr && pass(0).format == Rgba8 && gpu.targetPasses.length == 3 && pass(1).format == Rgba8,
			"Without half floats the chain is RGBA8 and no tone mapping runs");

		// A Tonemap of the chain's own is where it was added, and none is added.
		gpu.floatTargets = true;
		hdrPost.remove(after);
		hdrPost.add(after);
		frame(hdrPost, 800, 600);
		var planned:Array<ScreenEffect> = @:privateAccess hdrPost.steps;
		check(planned.length == 3 && planned[1] == own && planned[2] == after, "A Tonemap of the chain's own is used where it was added");
		check(pass(3).format == Rgba8, "After its own tone mapping the chain is RGBA8");
		post.destroy();
		hdrPost.destroy();
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}
}
