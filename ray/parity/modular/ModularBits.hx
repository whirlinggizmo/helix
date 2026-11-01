import helix.ray.*;
import helix.ray.Raylib.*;
import helix.ray.internal.Frame;
import helix.ray.internal.Runtime;

// helix-ray's skeletal animation on Quaternius' Ultimate Modular Women, printed as ref.c prints raylib 6.2's, for tools/ray_parity.py.
@:access(helix.ray.internal.Runtime)
@:access(helix.ray.Model)
class ModularBits {
	static final PARTS = ["Head", "Body", "Legs", "Feet", "Sword"];
	static final FILES = [
		"web/Adventurer_Head.glb",
		"web/Adventurer_Body.glb",
		"web/Adventurer_Legs.glb",
		"web/Adventurer_Feet.glb",
		"web/Sword.glb"
	];
	static final CLIPS = [
		"CharacterArmature|Idle",
		"CharacterArmature|Walk",
		"CharacterArmature|Sword_Slash"
	];

	static function line(s:String)
		Parity.line(s);

	static function matrices(key:String, m:Model)
		for (b in 0...m.boneCount) {
			var x = m.boneMatrices[b];
			var f = [
				x.m0, x.m4, x.m8, x.m12, x.m1, x.m5, x.m9, x.m13, x.m2, x.m6, x.m10, x.m14, x.m3, x.m7, x.m11, x.m15
			];
			line('$key $b ' + f.join(" "));
		}

	static function vertices(key:String, m:Model)
		for (i => mesh in m.meshes) {
			if (mesh.animVertices == null) {
				line('$key $i none');
				continue;
			}
			var step = Std.int(mesh.vertexCount / 40) + 1, v = 0;
			while (v < mesh.vertexCount) {
				var a = mesh.animVertices, n = mesh.animNormals;
				line('$key $i $v ${a[v * 3]} ${a[v * 3 + 1]} ${a[v * 3 + 2]}' + (n == null ? "" : ' ${n[v * 3]} ${n[v * 3 + 1]} ${n[v * 3 + 2]}'));
				v += step;
			}
		}

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
		throw "never loaded";
	}

	// C's %g of a frame (7.5, 20, 40.25).
	static function fmt(x:Float):String
		return x == Math.ffloor(x) ? Std.string(Std.int(x)) : Std.string(x);

	static function main() {
		SetTraceLogLevel(LOG_WARNING);
		var gr = new StubGraphics();
		Runtime.graphics = gr;
		Runtime.frame = new Frame(gr);
		var files = new DiskFiles(), decoder = new DiskFiles.WhiteDecoder();
		Runtime.polled.push(files);
		Runtime.assets = new helix.services.assets.Assets({sources: [FileSystem(files)]});
		Runtime.decoding = new helix.services.images.Images(decoder, Runtime.assets);
		Runtime.polled.push(Runtime.decoding);
		Runtime.models = new helix.services.models.Models(Runtime.assets, Runtime.decoding);
		var anims:Array<ModelAnimation> = null;
		LoadModelAnimationsAsync("web/Animations.glb", a -> anims = a, e -> throw e);
		pump(() -> anims != null);
		line("part Animations");
		line('anims ${anims.length}');
		var clips = [-1, -1, -1];
		for (a => an in anims) {
			line('anim $a ${an.name} ${an.frameCount} ${an.boneCount}');
			for (c => name in CLIPS)
				if (an.name == name)
					clips[c] = a;
		}
		// The frames the fractional ones lie between, as LoadModelAnimationsAsync sampled them.
		for (c in 0...3) {
			if (clips[c] < 0)
				continue;
			var an = anims[clips[c]];
			for (k in [7, 8, 3])
				for (b in 0...an.boneCount) {
					var t = an.framePoses[k][b];
					line('pose $c $k $b ${t.translation.x} ${t.translation.y} ${t.translation.z} ${t.rotation.x} ${t.rotation.y} ${t.rotation.z} ${t.rotation.w} ${t.scale.x} ${t.scale.y} ${t.scale.z}');
				}
		}
		for (p => file in FILES) {
			var model:Model = null;
			LoadModelAsync(file, m -> model = m, e -> throw e);
			pump(() -> model != null);
			line('part ${PARTS[p]}');
			line('model ${model.meshCount} ${model.materialCount} ${model.boneCount}');
			for (i => m in model.meshes)
				line('mesh $i ${m.vertexCount} ${m.boneIds != null ? 1 : 0} ${m.boneWeights != null ? 1 : 0}');
			for (c in 0...3) {
				if (clips[c] < 0)
					continue;
				var an = anims[clips[c]];
				line('valid $c ${IsModelAnimationValid(model, an) ? 1 : 0}');
				for (at in [0, 7.5, 20, an.frameCount + 3.25]) {
					if (p == 1) {
						UpdateModelAnimationBones(model, an, at);
						matrices('bones $c ${fmt(at)}', model);
					}
					UpdateModelAnimation(model, an, at);
					vertices('skin $c ${fmt(at)}', model);
				}
			}
			UnloadModel(model);
		}
		UnloadModelAnimations(anims, anims.length);
		Parity.save();
	}
}
