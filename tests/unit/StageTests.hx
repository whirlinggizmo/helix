import Render2DTests.CountingGraphics;
import helix.host.Presentation;
import helix.render2d.Shape2D;
import helix.render2d.StageService;

/** The stage (helix.render2d.StageService): a frame drawn whole, cleared to its color, its children in order through the presentation's
	camera; children added (again: to the top) and taken off; nothing drawn of an empty stage but the clear;
	a paused node's emitter held still. */
class StageTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function main():Void {
		var gpu = new CountingGraphics(), presentation = new Presentation();
		@:privateAccess presentation.refit(800, 600, 1);
		var stage = new StageService(gpu, presentation);
		stage.draw(0);
		check(gpu.framesEnded == 1 && gpu.clearColor == 0xff000000 && gpu.draws.length == 0, "An empty stage: the frame cleared to black, nothing drawn");
		var back = Shape2D.rectangle(100, 50, 0xff102030),
			front = Shape2D.circle(10, 0xff66bfff);
		stage.addChild(back);
		stage.addChild(front);
		check(stage.childCount == 2, "Children added");
		stage.addChild(back);
		check(stage.childCount == 2 && @:privateAccess stage.tree.root.getChild(1) == back, "A child added again: moved to the top, as Flash's addChild does");
		stage.color = 0xff14161c;
		stage.draw(0);
		check(gpu.framesEnded == 2 && gpu.clearColor == 0xff14161c, "Cleared to the stage's color");
		check(gpu.draws.length > 0 && stage.drawnNodeCount == 2, "Its children drawn");
		check(stage.removeChild(back) && stage.childCount == 1 && !stage.removeChild(back), "A child taken off, once");
		stage.draw(0);
		check(stage.drawnNodeCount == 1, "What's left drawn");
		// A paused node holds its emitters still, still drawn.
		var sparks = new helix.particles.Emitter(null),
			node = new helix.render2d.Particles2D(sparks);
		sparks.rate = 100;
		sparks.setLife(10, 10);
		stage.addChild(node);
		stage.draw(0);
		stage.draw(1);
		var made = sparks.particleCount;
		check(made > 0, "An emitter on the stage moves on with the clock");
		node.paused = true;
		stage.draw(2);
		check(sparks.particleCount == made && stage.drawnNodeCount == 2, "Paused: held as it is, still drawn");
		node.paused = false;
		stage.draw(3);
		check(sparks.particleCount > made, "Unpaused: on again");
		stage.destroy();
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}
}
