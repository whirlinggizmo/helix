import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raymath.*;
import helix.raylib.extras.Models.*;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Runtime;

/** Checks `extras.Models.LoadModelFromModels` on graphics that count what is live: meshes whose materials differ only in diffuse color
	merged into one with the colors in the vertices, other materials kept apart, the provided models unchanged, normals given to a mesh
	without, a merge without a skeleton baking the transforms and having no bones, and one with a skeleton taking its bones, renumbering
	each model's by name, following the nearest ancestor, rebinding a model bound elsewhere, placing a model without bones, and being
	posed by an animation of the skeleton; and the three refusals. */
@:access(helix.raylib.Mesh)
@:access(helix.raylib.Model)
@:access(helix.raylib.internal.Runtime)
@:access(helix.raylib.internal.Frame)
class ModelMergeTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float):Bool
		return Math.abs(a - b) < 1e-5;

	static function atRest(?x:Float = 0, ?y:Float = 0, ?z:Float = 0):Transform
		return new Transform(new Vector3(x, y, z), new Quaternion(0, 0, 0, 1), new Vector3(1, 1, 1));

	// A cube of the color, its vertices following the one bone, of the bones given with their parents.
	static function part(color:Color, ?names:Array<String>, ?parents:Array<Int>, follows = 0):Model {
		var mesh = GenMeshCube(1, 1, 1);
		var model = LoadModelFromMesh(mesh);
		model.materials[0].maps[MATERIAL_MAP_ALBEDO].color = color;
		if (names != null) {
			mesh.boneIds = [for (k in 0...mesh.vertexCount * 4) k % 4 == 0 ? follows : 0];
			mesh.boneWeights = [for (k in 0...mesh.vertexCount * 4) k % 4 == 0 ? 1. : 0.];
			model.boneCount = names.length;
			model.bones = [for (i => n in names) new BoneInfo(n, parents[i])];
			model.bindPose = [for (_ in names) atRest()];
		}
		return model;
	}

	static function main():Void {
		SetTraceLogLevel(LOG_NONE);
		var graphics = new CountingGraphics();
		Runtime.graphics = graphics;
		Runtime.frame = new Frame(graphics);
		var red = new Color(255, 0, 0, 255),
			gray = new Color(128, 128, 128, 255);

		check(LoadModelFromModels([]) == null, "an empty list is refused");

		// Materials differing only in diffuse color: one mesh, one white material, the colors in the vertices.
		var a = part(red), b = part(gray);
		var merged = LoadModelFromModels([a, b]);
		var mesh = merged.meshes[0];
		check(merged.meshCount == 1 && merged.materialCount == 1 && mesh.vertexCount == 48 && mesh.triangleCount == 24, "merged into one mesh");
		check(merged.materials[0].maps[MATERIAL_MAP_ALBEDO].color.g == 255, "the merged mesh's material is white");
		check(mesh.colors[0] == 255 && mesh.colors[1] == 0 && mesh.colors[24 * 4] == 128 && mesh.colors[24 * 4 + 3] == 255,
			"each material's color is in its vertices");
		check(mesh.indices[36] == 24, "the second mesh's indices follow the first's vertices");
		check(mesh.gpu.buffers != null, "the merged mesh is uploaded");
		check(a.meshes[0].colors == null && a.materials[0].maps[MATERIAL_MAP_ALBEDO].color.r == 255 && a.meshes[0].vertexCount == 24,
			"the provided model is unchanged");
		check(merged.boneCount == 0 && merged.bones == null && mesh.boneIds == null, "without a skeleton, no bones");

		// Materials differing in more: separate meshes.
		var valued = part(red);
		valued.materials[0].maps[MATERIAL_MAP_METALNESS].value = .5;
		var unlit = part(red);
		unlit.materials[0].unlit = true;
		var apart = LoadModelFromModels([part(gray), valued, unlit, part(red)]);
		check(apart.meshCount == 3 && apart.materialCount == 3 && apart.meshMaterial[2] == 2, "a map's value and unlit keep meshes apart");
		check(apart.meshes[0].vertexCount == 48 && apart.materials[1].maps[MATERIAL_MAP_METALNESS].value == .5 && apart.materials[2].unlit,
			"the kept materials as they were");

		// A mesh without normals, merged with a mesh with them: raylib's default.
		var plain = part(red);
		plain.meshes[0].normals = null;
		var withNormals = LoadModelFromModels([part(red), plain]).meshes[0];
		check(withNormals.normals[24 * 3] == 0 && withNormals.normals[24 * 3 + 1] == 0 && withNormals.normals[24 * 3 + 2] == 1,
			"normals (0, 0, 1) for the mesh without");

		// Without a skeleton: each model's transform in its vertices, the new model at the identity.
		var moved = part(red);
		moved.transform = MatrixTranslate(10, 0, 0);
		var rigged = part(red, ["root"], [-1]);
		rigged.transform = MatrixTranslate(0, 20, 0);
		var baked = LoadModelFromModels([moved, rigged]);
		var box = GenMeshCube(1, 1, 1).vertices;
		check(near(baked.meshes[0].vertices[0], box[0] + 10) && near(baked.meshes[0].vertices[24 * 3 + 1], box[1] + 20),
			"each model's transform in its vertices");
		check(baked.transform.m12 == 0 && baked.transform.m13 == 0, "the identity transform");
		check(baked.meshes[0].boneIds == null, "a model with bones merged at its bind pose, its bones gone");

		// With a skeleton: its bones, in its order, each model's renumbered by name.
		var skeleton = part(red, ["root", "hand"], [-1, 0]);
		var reversed = part(gray, ["hand", "root"], [1, -1], 0);
		var tipped = part(gray, ["root", "hand", "tip"], [-1, 0, 1], 2);
		var stranger = part(gray, ["other"], [-1], 0);
		var onto = LoadModelFromModels([skeleton, reversed, tipped, stranger], skeleton);
		var joined = onto.meshes[0];
		check(onto.boneCount == 2 && onto.bones[1].name == "hand" && onto.bones != skeleton.bones && onto.bindPose.length == 2, "the skeleton's bones");
		check(joined.boneIds[0] == 0 && joined.boneWeights[0] == 1, "the skeleton's own vertices keep their bone");
		check(joined.boneIds[24 * 4] == 1 && joined.boneWeights[24 * 4] == 1, "a bone matched by name in another order is renumbered");
		check(joined.boneIds[48 * 4] == 1 && joined.boneWeights[48 * 4] == 1, "a bone the skeleton lacks follows its nearest ancestor there");
		check(joined.boneWeights[72 * 4] == 0, "a bone with no such ancestor: the vertex has weight 0");

		// Posed by an animation of the skeleton, and the vertices of no bone left at rest.
		var anim = new ModelAnimation();
		anim.boneCount = 2;
		anim.bones = [new BoneInfo("root", -1), new BoneInfo("hand", 0)];
		anim.frameCount = 1;
		anim.framePoses = [[atRest(), atRest(0, 1, 0)]];
		check(IsModelAnimationValid(onto, anim), "an animation of the skeleton is valid for the new model");
		UpdateModelAnimation(onto, anim, 0);
		check(joined.boneMatrices != null && joined.boneMatrices[1].m13 == 1 && joined.boneMatrices[0].m13 == 0, "posed by the animation");

		// A model bound in another bind pose, rebound: a vertex moves from the model's bind pose to the skeleton's.
		var boundElsewhere = part(gray, ["root", "hand"], [-1, 0], 1);
		boundElsewhere.bindPose[1] = atRest(0, 3, 0);
		var rebound = LoadModelFromModels([boundElsewhere], skeleton).meshes[0];
		check(near(rebound.vertices[1], box[1] - 3) && near(rebound.vertices[0], box[0]), "rebound to the skeleton's bind pose");
		check(near(rebound.normals[1], GenMeshCube(1, 1, 1).normals[1]), "a move without a turn leaves the normals");
		var split = part(gray, ["root", "hand"], [-1, 0], 1);
		split.bindPose[1] = atRest(0, 4, 0);
		split.meshes[0].boneIds[1] = 0;
		split.meshes[0].boneWeights[0] = .5;
		split.meshes[0].boneWeights[1] = .5;
		check(near(LoadModelFromModels([split], skeleton).meshes[0].vertices[1], box[1] - 2), "several bones: the moves blended by the weights");

		// A model without bones under a skeleton stays where its transform put it; the new model has the skeleton's transform.
		var placedSkeleton = part(red, ["root"], [-1]);
		placedSkeleton.transform = MatrixTranslate(0, 0, 5);
		var prop = part(gray);
		prop.transform = MatrixTranslate(1, 0, 0);
		var placed = LoadModelFromModels([prop], placedSkeleton);
		check(placed.transform.m14 == 5
			&& near(placed.meshes[0].vertices[0], box[0] + 1)
			&& near(placed.meshes[0].vertices[2], box[2] - 5),
			"placed where its transform put it");
		check(placed.boneCount == 1 && placed.meshes[0].boneWeights == null, "a model without bones follows none");

		// Refusals.
		var askew = part(gray, ["root"], [-1]);
		askew.transform = MatrixTranslate(0, 1, 0);
		check(LoadModelFromModels([askew], skeleton) == null, "a model with bones in another transform is refused");
		var huge = part(gray, [for (i in 0...257) 'b$i'], [for (i in 0...257) i - 1]);
		check(LoadModelFromModels([part(red)], huge) == null, "a skeleton of more than 256 bones is refused");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
