// The web size ladder (tools/measure_sizes.py): each rung adds one thing to the one before; this one + a 3D view of a lit cube.
import helix.app.AppOptions;
import helix.audio.Audio;
import helix.host.Window;
import helix.render2d.Shape2D;
import helix.render2d.Sprite2D;
import helix.render2d.Stage;
import helix.render2d.Text2D;
import helix.render2d.Textures;
import helix.render3d.Camera3D;
import helix.render3d.DirectionalLight;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.Model;
import helix.render3d.Node3D;
import helix.render3d.View3D;

/** The entry point: Game on the backend the build names. */
class Main {
	public static function main():Void {
		var options = new AppOptions();
		options.product = "size-6-3d";
		new Game(options);
	}
}

/** This rung's game: + a 3D view of a cube under a light, under the 2D. */
class Game extends helix.App {
	override public function init():Void {
		Window.title = "6-3d";
		Stage.color = 0xff202840;
		var level = new Node3D(), camera = new Camera3D();
		level.addChild(new DirectionalLight());
		var cube = new Model(Mesh.cube(2, 2, 2), new Material());
		cube.setPosition(0, 1, 0);
		level.addChild(cube);
		camera.setView(4, 4, 6, 0, 1, 0);
		Stage.addChild(new View3D(level, camera));
		var box = Shape2D.rectangle(320, 160, 0xff66bfff);
		box.setPosition(40, 40);
		Stage.addChild(box);
		var hello = new Text2D("Hello", 48, 0xff102030);
		hello.setPosition(60, 90);
		Stage.addChild(hello);
		Textures.load("sprites/logo.png", true, texture -> {
			var logo = new Sprite2D(texture);
			logo.setPosition(400, 300);
			logo.setSize(64, 64);
			Stage.addChild(logo);
		});
		Audio.instance.loadClip("audio/click.ogg", clip -> Audio.play(clip));
	}
}
