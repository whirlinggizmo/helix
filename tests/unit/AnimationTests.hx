import Render2DTests.CountingGraphics;
import haxe.ds.Vector;
import helix.render3d.AnimationClip;
import helix.render3d.Animator;
import helix.render3d.Camera3D;
import helix.render3d.Gltf;
import helix.render3d.JointPalette;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.Model;
import helix.render3d.ModelFile;
import helix.render3d.Node3D;
import helix.render3d.Skin;
import helix.render3d.Stage3D;

/** Skinning and skeletal animation: tracks' sampling, skins and clips read from glTF (Quaternius's modular women, the animation example's),
	the Animator's binding, refusal and crossfade, joint matrices, and a posed model's culling box. */
class AnimationTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float):Bool
		return Math.abs(a - b) < 1e-5;

	static function file(name:String):ModelFile
		return @:privateAccess new ModelFile(Gltf.read(sys.io.File.getBytes('examples/assets/models/modular-women/$name.glb')));

	public static function main():Void {
		tracks();
		weights();
		files();
		animator();
		joints();
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}

	static function tracks():Void {
		var out = new Vector<Float>(4);
		var move = new Track("a", Translation, Linear, [0, 1], [0, 0, 0, 10, 20, 30]);
		move.sample(.25, out);
		check(near(out[0], 2.5) && near(out[1], 5) && near(out[2], 7.5), "Linear between keys");
		move.sample(-1, out);
		check(out[0] == 0, "Held before the first key");
		move.sample(5, out);
		check(out[0] == 10, "Held after the last");
		var step = new Track("a", Translation, Step, [0, 1], [0, 0, 0, 10, 0, 0]);
		step.sample(.99, out);
		check(out[0] == 0, "A step holds until the next key");
		// A cubic spline with flat tangents eases: a quarter of the way in time is less than a quarter of the way.
		var cubic = new Track("a", Translation, CubicSpline, [0, 1], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0]);
		cubic.sample(.25, out);
		check(near(out[0], 10 * (3 * .0625 - 2 * .015625)), "A cubic spline through its values, flat tangents");
		// q and -q are one rotation: halfway takes the short way, and stays normalized.
		var s = Math.sqrt(.5);
		var turn = new Track("a", Rotation, Linear, [0, 1], [0, 0, 0, 1, 0, -s, 0, -s]);
		turn.sample(.5, out);
		var length = Math.sqrt(out[0] * out[0] + out[1] * out[1] + out[2] * out[2] + out[3] * out[3]);
		check(near(length, 1) && Math.abs(out[1]) < Math.abs(out[3]), "Rotation slerps the short way, normalized");
		var threw = try {
			new Track("a", Translation, Linear, [0, 1], [0, 0, 0]);
			false;
		} catch (_:Dynamic)
			true;
		check(threw, "Values that don't match the times throw");
	}

	static function weights():Void {
		// One triangle, its first vertex weighted .25 to joint 1 alone (normalized to 1), its second unweighted (follows joint 0).
		var mesh = Mesh.fromArrays([0, 0, 0, 1, 0, 0, 0, 1, 0], null, null, null, null, [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0],
			[.25, 0, 0, 0, 0, 0, 0, 0, .5, .5, 0, 0]);
		var skin = mesh.getSkinData();
		check(skin.getFloat(Skinned3DLayout.weightsOffset) == 1, "Weights normalized to sum to 1");
		check(skin.getFloat(Skinned3DLayout.skinStride + Skinned3DLayout.weightsOffset) == 1, "An unweighted vertex follows its first joint");
		check(skin.getFloat(2 * Skinned3DLayout.skinStride + Skinned3DLayout.weightsOffset + 4) == .5, "Split weights kept");
	}

	static function files():Void {
		var animations = file("Animations");
		check(animations.getClips().length == 24 && animations.getSkins().length == 1, "24 clips and the skeleton's skin");
		var walk = animations.getClip("Walk");
		check(walk != null && walk.getName() == "CharacterArmature|Walk" && animations.getClip("CharacterArmature|Walk") == walk,
			"A clip found by the part after | or its whole name");
		check(animations.getClip("Moonwalk") == null && walk.getDuration() > 0, "None for an unknown name; a length");
		var body = file("Casual_Body");
		check(body.getWarnings().length == 0, "Skins read without warnings: " + body.getWarnings().join("; "));
		var a = body.instantiate("a"), b = body.instantiate("b");
		// A node with a mesh is one model, its primitives its parts.
		var modelA = Std.downcast(a.find("Casual_Body"), Model),
			modelB = Std.downcast(b.find("Casual_Body"), Model);
		check(modelA != null && modelB != null && modelA.getPartCount() > 0, "The file's skinned node is a model");
		if (modelA == null || modelB == null)
			return;
		check(modelA.getJointCount() == 62 && modelA.getSkin().getJointName(0) != "", "Each copy's skinned model bound to its 62 joints");
		check(modelA.getJoint(0) != modelB.getJoint(0)
			&& modelA.getJoint(5) == a.find(modelA.getSkin().getJointName(5)), "Each copy follows its own skeleton");
		// Gear from another file binds to a skeleton by name; one asking for a joint the skeleton hasn't is refused.
		var skeleton = animations.instantiate("character");
		check(modelB.bindSkeleton(skeleton) && modelB.getJoint(3) == skeleton.find(modelB.getSkin().getJointName(3)),
			"A part binds to another file's skeleton by joint name");
		var partial = new Skin(["Hips", "NoSuchBone"]);
		check(!modelB.bindSkeleton(skeleton, partial) && modelB.getJointCount() == 62, "A missing joint is refused, the binding kept");
	}

	static function animator():Void {
		// A root "a" holding "b": clip one puts b at x 0, clip two at x 10; clip three moves only a.
		var a = new Node3D(), b = new Node3D();
		a.setName("a");
		b.setName("b");
		a.add(b);
		b.setPosition(2, 0, 0);
		var one = new AnimationClip("one", [new Track("b", Translation, Linear, [0, 1], [0, 0, 0, 0, 0, 0])]);
		var two = new AnimationClip("two", [new Track("b", Translation, Linear, [0, 1], [10, 0, 0, 10, 0, 0])]);
		var three = new AnimationClip("three", [new Track("a", Translation, Linear, [0, 1], [0, 5, 0, 0, 5, 0])]);
		var ghost = new AnimationClip("ghost", [new Track("nobody", Translation, Linear, [0], [0, 0, 0])]);
		var animator = new Animator(a);
		check(!animator.play(ghost) && animator.getClip() == null, "A clip moving a node the root hasn't is refused");
		check(animator.play(one), "A clip binds by name");
		animator.update(.1);
		check(b.getX() == 0, "Posed by the clip");
		check(animator.play(two, true, 1), "Crossfades over a second");
		animator.update(.5);
		check(near(b.getX(), 5) && animator.isFading(), "Halfway through the fade, halfway between the clips");
		animator.update(.6);
		check(b.getX() == 10 && !animator.isFading(), "The fade ends on the new clip");
		// Into a clip that doesn't move b: b blends back to its rest (x 2, where it was first bound), a to its new place.
		animator.play(three, true, 1);
		animator.update(.5);
		check(near(b.getX(), 6) && near(a.getY(), 2.5), "A node the new clip doesn't move fades to its rest");
		animator.play(one, false);
		animator.update(5);
		check(animator.isFinished() && animator.getTime() == 1, "A clip that doesn't loop holds at its end");
		check(animator.play(two) && animator.setTime(2.5) && near(animator.getTime(), .5), "A looping clip's time wraps");
		check(!animator.play(two, true, -1) && !animator.setSpeed(Math.NaN), "A negative fade or a speed not finite is refused");
	}

	static function joints():Void {
		// A strip from x 0 to 2 along two joints: joint 0 at the origin weighting x <= 1, joint 1 at x 1 weighting beyond, bound in place.
		var positions = [0., 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 2, 0, 0, 1, 1, 0];
		var mesh = Mesh.fromArrays(positions, null, null, null, null, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0],
			[1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0]);
		// Joint 1's inverse bind takes the mesh's space to the joint's: a move of -1 along x.
		var skin = new Skin(["hip", "knee"], [
			1., 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -1, 0, 0, 1
		]);
		check(near(skin.getBindPosition(1, 0), 1) && near(skin.getBindPosition(0, 0), 0), "A joint's bind position, its inverse bind's inverse");
		var reach = mesh.getJointReach(skin);
		check(near(reach[0], 1) && near(reach[1], 1), "Each joint reaches as far as the vertices it weights");
		var gpu = new CountingGraphics(), stage = new Stage3D(gpu);
		var character = new Node3D(), hip = new Node3D(), knee = new Node3D();
		hip.setName("hip");
		knee.setName("knee");
		knee.setPosition(1, 0, 0);
		hip.add(knee);
		character.add(hip);
		var model = new Model(mesh, new Material());
		character.add(model);
		check(model.bindSkeleton(character, skin) && model.getJointCount() == 2, "Bound to its joints");
		stage.add(character);
		// The knee swung far out of the bind pose's box, out to x 40: the posed box follows it.
		knee.setPosition(40, 0, 0);
		var view = new Camera3D();
		view.setViewport(800, 600);
		view.setView(40, 0, 10, 40, 0, 0);
		gpu.beginFrame(800, 600, 0);
		stage.draw(view);
		check(stage.getDrawnNodeCount() == 1, "A model posed out of its rest box is drawn where its joints are");
		var palette:JointPalette = @:privateAccess stage.palette,
			data = @:privateAccess palette.data;
		// Joint 1's matrix: the model's space moved to the knee at x 40, its inverse bind's -1 applied: x + 39.
		check(palette.getJointCount() == 2
			&& near(data.getFloat(48 + 12), 39)
			&& near(data.getFloat(48), 1)
			&& near(data.getFloat(12), 0),
			"Joint matrices: inverse(model) x joint x inverse bind, their top rows");
		var record = @:privateAccess stage.records;
		check(record.getFloat(Lit3DLayout.normal2Offset + 12) == 0, "The model's first joint in its record");
		var box = new Vector<Float>(6);
		check(JointPalette.computePosedBox(model, model.getMesh(), box) && box[0] + box[3] > 41 && box[0] - box[3] < 0,
			"The posed box holds both joints' reach");
		// The model moved far off while its joints stay: it draws where its joints are, so nothing is drawn there.
		knee.setPosition(1, 0, 0);
		model.setPosition(500, 0, 0);
		view.setView(500, 0, 10, 500, 0, 0);
		stage.draw(view);
		check(stage.getDrawnNodeCount() == 0, "A skinned model's own placement doesn't move it: its joints do");
	}
}
