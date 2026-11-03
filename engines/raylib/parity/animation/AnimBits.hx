import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Extras.*;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Runtime;

// helix-raylib's skeletal animation, printed as ref.c prints raylib 6.2's, for tools/raylib_parity.py.
@:access(helix.raylib.internal.Runtime)
@:access(helix.raylib.Model)
class AnimBits {
	static function line(s:String)
		Parity.line(s);

	static function g(x:Float):String
		return Std.string(x);

	static function tr(key:String, t:Transform)
		line('$key ${g(t.translation.x)} ${g(t.translation.y)} ${g(t.translation.z)} ${g(t.rotation.x)} ${g(t.rotation.y)} ${g(t.rotation.z)} ${g(t.rotation.w)} ${g(t.scale.x)} ${g(t.scale.y)} ${g(t.scale.z)}');

	static function matrices(key:String, m:Model)
		for (b in 0...m.boneCount) {
			var x = m.boneMatrices[b];
			var f = [
				x.m0, x.m4, x.m8, x.m12, x.m1, x.m5, x.m9, x.m13, x.m2, x.m6, x.m10, x.m14, x.m3, x.m7, x.m11, x.m15
			];
			line('$key $b ' + f.map(g).join(" "));
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
				line('$key $i $v ${g(a[v * 3])} ${g(a[v * 3 + 1])} ${g(a[v * 3 + 2])}'
					+ (n == null ? "" : ' ${g(n[v * 3])} ${g(n[v * 3 + 1])} ${g(n[v * 3 + 2])}'));
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

	static function key(parts:Array<Dynamic>):String
		return parts.map(p -> Std.isOfType(p, Float) && !Std.isOfType(p, Int) ? fmt(p) : Std.string(p)).join(" ");

	// C's %g of a frame (7.5, 30, 154).
	static function fmt(x:Float):String
		return x == Math.ffloor(x) ? Std.string(Std.int(x)) : Std.string(x);

	static function main() {
		SetTraceLogLevel(LOG_WARNING);
		var gr = new StubGraphics();
		Runtime.graphics = gr;
		Runtime.frame = new Frame(gr);
		var files = new DiskFiles(), decoder = new DiskFiles.WhiteDecoder();
		Runtime.polled.push(files);
		Runtime.assets = new helix.services.assets.Assets([new helix.services.assets.FileSystemSource(files)]);
		Runtime.decoding = new helix.services.images.Images(decoder, Runtime.assets);
		Runtime.polled.push(Runtime.decoding);
		Runtime.models = new helix.services.models.Models(Runtime.assets, Runtime.decoding);
		for (f => file in ["web/greenman.glb", "web/robot.glb", "web/rig.gltf"]) {
			line('file $f');
			var model:Model = null, anims:Array<ModelAnimation> = null;
			LoadModelAsync(file, m -> model = m, e -> throw e);
			pump(() -> model != null);
			LoadModelAnimationsAsync(file, a -> anims = a, e -> throw e);
			pump(() -> anims != null);
			line('model ${model.meshCount} ${model.materialCount} ${model.boneCount}');
			for (b in 0...model.boneCount) {
				line('bone $b ${model.bones[b].name} ${model.bones[b].parent}');
				tr('bind $b', model.bindPose[b]);
			}
			for (i => m in model.meshes) {
				line('mesh $i ${m.vertexCount} ${m.boneCount} ${m.boneIds != null ? 1 : 0} ${m.boneWeights != null ? 1 : 0}');
				if (m.boneIds != null) {
					var step = Std.int(m.vertexCount / 20) + 1, v = 0;
					while (v < m.vertexCount) {
						var w = m.boneWeights;
						line('ids $i $v ${m.boneIds[v * 4]} ${m.boneIds[v * 4 + 1]} ${m.boneIds[v * 4 + 2]} ${m.boneIds[v * 4 + 3]} ${g(w[v * 4])} ${g(w[v * 4 + 1])} ${g(w[v * 4 + 2])} ${g(w[v * 4 + 3])}');
						v += step;
					}
				}
			}
			line('anims ${anims.length}');
			for (a => an in anims) {
				line('anim $a ${an.name} ${an.frameCount} ${an.boneCount} ${IsModelAnimationValid(model, an) ? 1 : 0}');
				for (k in [0, 1, 7, 30, an.frameCount - 1]) {
					if (k >= an.frameCount)
						continue;
					for (b in 0...an.boneCount)
						tr('pose $a $k $b', an.framePoses[k][b]);
				}
				for (at in [0, 7.5, 30, an.frameCount + 3]) {
					UpdateModelAnimationBones(model, an, at);
					matrices('bones $a ${fmt(at)}', model);
				}
			}
			if (anims.length > 0) {
				var a = anims.length > 1 ? 1 : 0;
				for (at in [10, 22.25]) {
					UpdateModelAnimation(model, anims[a], at);
					vertices('skin $a ${fmt(at)}', model);
					matrices('skinbones $a ${fmt(at)}', model);
				}
				var b = anims.length > 2 ? 2 : 0;
				UpdateModelAnimationEx(model, anims[a], 5.5, anims[b], 12.25, 0.3);
				vertices('ex $a $b', model);
				matrices('exbones $a $b', model);
				UpdateModelAnimationEx(model, anims[a], anims[a].frameCount + 2.5, anims[b], 3.75, 0.8);
				matrices('exwrap $a $b', model);
			}
			UnloadModelAnimations(anims, anims.length);
			UnloadModel(model);
		}
		Parity.save();
	}
}
