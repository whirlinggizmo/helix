import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Models.*;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Runtime;

/** Checks `UpdateModelAnimationMasked` and `GetModelBoneMask` on a chain of three bones (a root, a spine on it, an arm on the spine) and
	two animations of one frame: the first raising the root by one, as a run's hips, the second turning the spine a quarter about z. A
	blend of 0 poses the first, every bone weighted 1 at a blend of 1 the second, and a blend of 2 is clamped to 1. The spine's mask
	keeps the first's root and uses the second's spine and arm relative to their parents: the spine follows the raised root. Under a
	root turned a quarter, the spine turns with the root relative to its parent, and keeps the second's facing with the rotation in the
	model. Another rotation space, or a mask of another count of bones, leaves the model as it was. The mask is the spine's branch,
	fills the array provided, and is 0 for a bone the model hasn't. */
@:access(helix.raylib.internal.Runtime)
@:access(helix.raylib.Model)
class AnimationMaskTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float):Bool {
		return Math.abs(a - b) < 1e-5;
	}

	static function pose(t:Float, ty:Float, tz:Float, qz:Float, qw:Float):Transform {
		return new Transform(new Vector3(t, ty, tz), new Quaternion(0, 0, qz, qw), new Vector3(1, 1, 1));
	}

	static function bones():Array<BoneInfo> {
		return [new BoneInfo("root", -1), new BoneInfo("spine", 0), new BoneInfo("arm", 1)];
	}

	// A cube skinned to the root, its model set to the chain's bones at rest: the root at the origin, the spine one up, the arm one
	// along x from it.
	static function chain():Model {
		var mesh = GenMeshCube(1, 1, 1);
		mesh.boneIds = [for (k in 0...mesh.vertexCount * 4) 0];
		mesh.boneWeights = [for (k in 0...mesh.vertexCount * 4) k % 4 == 0 ? 1. : 0.];
		var model = LoadModelFromMesh(mesh);
		model.boneCount = 3;
		model.bones = bones();
		model.bindPose = [pose(0, 0, 0, 0, 1), pose(0, 1, 0, 0, 1), pose(1, 1, 0, 0, 1)];
		return model;
	}

	// An animation of one frame, its poses in the model as raylib's loader leaves them.
	static function animation(frame:Array<Transform>):ModelAnimation {
		var anim = new ModelAnimation();
		anim.boneCount = 3;
		anim.bones = bones();
		anim.frameCount = 1;
		anim.framePoses = [frame];
		return anim;
	}

	static function same(t:Transform, x:Float, y:Float, z:Float, qz:Float, qw:Float):Bool {
		return near(t.translation.x, x) && near(t.translation.y, y) && near(t.translation.z, z) && near(t.rotation.z, qz) && near(t.rotation.w, qw);
	}

	static function main():Void {
		SetTraceLogLevel(LOG_NONE);
		var graphics = new CountingGraphics();
		Runtime.graphics = graphics;
		Runtime.frame = new Frame(graphics);
		var quarter = Math.sqrt(0.5);
		// The run: the root raised by one, the spine and arm carried up with it.
		var run = animation([pose(0, 1, 0, 0, 1), pose(0, 2, 0, 0, 1), pose(1, 2, 0, 0, 1)]);
		// The attack: the root still, the spine turned a quarter about z, the arm turned with it, now one up from the spine.
		var attack = animation([
			pose(0, 0, 0, 0, 1),
			pose(0, 1, 0, quarter, quarter),
			pose(0, 2, 0, quarter, quarter)
		]);

		var model = chain();
		var all = [1., 1., 1.];
		UpdateModelAnimationMasked(model, run, 0, attack, 0, all, 0);
		check(same(model.pose[0], 0, 1, 0, 0, 1) && same(model.pose[1], 0, 2, 0, 0, 1) && same(model.pose[2], 1, 2, 0, 0, 1),
			"a blend of 0 poses the first animation");
		UpdateModelAnimationMasked(model, run, 0, attack, 0, all, 1);
		check(same(model.pose[0], 0, 0, 0, 0, 1)
			&& same(model.pose[1], 0, 1, 0, quarter, quarter)
			&& same(model.pose[2], 0, 2, 0, quarter, quarter),
			"every bone weighted 1 at a blend of 1 poses the second");

		UpdateModelAnimationMasked(model, run, 0, attack, 0, all, 2);
		check(same(model.pose[1], 0, 1, 0, quarter, quarter), "a blend above 1 is clamped to 1");

		var spine = GetModelBoneMask(model, "spine");
		check(spine.join(",") == "0,1,1", 'the spine\'s mask is the spine and the arm: $spine');
		UpdateModelAnimationMasked(model, run, 0, attack, 0, spine, 1);
		check(same(model.pose[0], 0, 1, 0, 0, 1), "the mask keeps the first's root, raised");
		check(same(model.pose[1], 0, 2, 0, quarter, quarter), "the spine is the second's, on the raised root");
		check(same(model.pose[2], 0, 3, 0, quarter, quarter), "the arm follows the turned spine on the raised root");

		// A run turned a quarter about z at the root: the spine and arm turned with it.
		var turned = animation([
			pose(0, 0, 0, quarter, quarter),
			pose(-1, 0, 0, quarter, quarter),
			pose(-1, 1, 0, quarter, quarter)
		]);
		UpdateModelAnimationMasked(model, turned, 0, attack, 0, spine, 1);
		check(same(model.pose[1], -1, 0, 0, 1, 0) && same(model.pose[2], -2, 0, 0, 1, 0),
			"relative to its parent, the attack's spine turns with the turned root, a half turn in all");
		UpdateModelAnimationMasked(model, turned, 0, attack, 0, spine, 1, BLEND_ROTATION_MODEL);
		check(same(model.pose[1], -1, 0, 0, quarter, quarter), "in the model, the spine keeps the attack's quarter turn, placed on the turned root");
		check(same(model.pose[2], -1, 1, 0, quarter, quarter), "and the arm hangs from it as the attack hangs it");
		check(same(model.pose[0], 0, 0, 0, quarter, quarter), "the root, weighted 0, keeps the run's turn");
		UpdateModelAnimationMasked(model, run, 0, attack, 0, spine, 1, 2);
		check(same(model.pose[1], -1, 0, 0, quarter, quarter), "a rotation space that isn't a BLEND_ROTATION_ value leaves the model as it was");

		UpdateModelAnimationMasked(model, run, 0, attack, 0, [1., 1.], 1);
		check(same(model.pose[2], -1, 1, 0, quarter, quarter), "a mask of another count of bones leaves the model as it was");

		var reused = [9., 9., 9., 9., 9.];
		var filled = GetModelBoneMask(model, "arm", reused);
		check(filled == reused && filled.join(",") == "0,0,1", 'the mask fills the array provided, sized to the bones: $filled');
		check(GetModelBoneMask(model, "tail").join(",") == "0,0,0", "a bone the model hasn't masks nothing");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
