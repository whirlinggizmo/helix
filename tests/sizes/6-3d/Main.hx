// The web size ladder (tools/measure_sizes.py): each rung adds one thing to the one before; this one + a 3D camera and a cube.
import helix.app.AppOptions;
import helix.audio.Audio;
import helix.graphics.Graphics;
import helix.host.Window;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Texture2D;
import helix.render2d.Textures;
import helix.render3d.Batch3D;
import helix.render3d.Camera3D;

/** The entry point: Game on the backend the build names. */
class Main {
	public static function main():Void {
		var options = new AppOptions();
		options.product = "size-6-3d";
		new Game(options);
	}
}

/** This rung's game: + a 3D camera and a cube. */
class Game extends helix.App {
	var batch:Batch2D;
	var camera = new Camera2D();
	var logo:Texture2D;
	var batch3D:Batch3D;
	var camera3D = new Camera3D();

	override public function init():Void {
		Window.title = "6-3d";
		batch = new Batch2D();
		Textures.load("sprites/logo.png", true, texture -> logo = texture);
		Audio.instance.loadClip("audio/click.ogg", clip -> Audio.play(clip));
		batch3D = new Batch3D();
	}

	override public function frame(dt:Float):Void {
		camera.pixels(Window.pixelRatio);
		camera3D.setViewport(Window.framebufferWidth, Window.framebufferHeight);
		Graphics.beginFrame(Window.framebufferWidth, Window.framebufferHeight, 0x202840ff);
		batch3D.begin(camera3D);
		batch3D.cube(0, 1, 0, 2, 2, 2, 0x66bfffff);
		batch3D.end();
		batch.begin(camera);
		batch.rect(40, 40, 320, 160, 0x66bfffff);
		batch.drawText("Hello", 60, 90, 48, 0x102030ff);
		if (logo != null)
			batch.sprite(logo, 400, 300, 64, 64);
		batch.end();
		Graphics.endFrame();
	}
}
