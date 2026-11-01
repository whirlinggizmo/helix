package helix.ray.internal;

import haxe.io.FPHelper;
import helix.formats.gltf.GltfFile;
import helix.ray.*;
import helix.ray.raylib.RMath.*;

/** Reads a glTF file's animations as raylib 6.2's `LoadModelAnimationsGLTF` does, and poses a model by them as its
	`UpdateModelAnimation` and `UpdateModelAnimationEx` do: their code ported line by line, with raymath's functions. */
@:noCompletion
@:access(helix.ray.raylib.RMath)
class Animations {
	/** The frames a second raylib samples an animation at. */
	static inline final FRAMERATE = 60.0;

	/** Reads a glTF or GLB file through the assets, with the buffers in files of their own, answering once.

		@param path  The file.
		@param done  Receives the file, its buffers read.
		@param failed  Receives why it couldn't be read. */
	public static function read(path:String, done:GltfFile->Void, failed:String->Void):Void {
		Runtime.fetch(path, error -> {
			if (error != null) {
				failed(error);
				return;
			}
			var file = try GltfFile.read(Runtime.files.get(path), path) catch (e:Dynamic) {
				failed('$path: $e');
				return;
			}
			var missing = file.missingBuffers,
				left = missing.length,
				answered = false;
			if (left == 0) {
				done(file);
				return;
			}
			for (m in missing)
				Runtime.fetch(m.path, error -> {
					if (answered)
						return;
					if (error == null)
						try
							file.setBuffer(m.index, Runtime.files.get(m.path))
						catch (e:Dynamic)
							error = '$path: $e';
					if (error != null) {
						answered = true;
						failed(error);
					} else if (--left == 0) {
						answered = true;
						done(file);
					}
				});
		});
	}

	/** Returns, for each mesh the models service reads from a file (its scene's nodes in order, each mesh's triangles), the joint of the
		first skin its node is a child of, when that parent has no mesh and the mesh has no joints of its own, as raylib 6.2's `LoadGLTF`
		finds it; -1 for others.

		@param file  The file, its buffers read.
		@return  Each mesh's joint, or -1. */
	public static function attached(file:GltfFile):Array<Int> {
		var nodes = file.nodes, meshes = file.meshes, out = [];
		var joints = file.skins.length > 0 ? file.skins[0].joints : [];
		var parents = parentsOf(file);
		function visit(index:Int):Void {
			var node = nodes[index];
			if (node.mesh >= 0)
				for (p in meshes[node.mesh].primitives)
					if (p.mode == 4) {
						var parent = parents.get(index);
						out.push(p.joints == null && parent != null && nodes[parent].mesh < 0 ? joints.indexOf(parent) : -1);
					}
			for (child in node.children)
				visit(child);
		}
		for (root in file.scene)
			visit(root);
		return out;
	}

	static function parentsOf(file:GltfFile):Map<Int, Int> {
		var parents = new Map<Int, Int>();
		for (i => node in file.nodes)
			for (child in node.children)
				parents.set(child, i);
		return parents;
	}

	/** Returns a skin's bones as raylib 6.2's `LoadBoneInfoGLTF` makes them: each joint's name, cut to 31 bytes, and its parent, the
		nearest node above it that is one of the skin's joints, or -1.

		@param file  The file.
		@param joints  The skin's joints, as nodes.
		@return  The bones. */
	public static function bones(file:GltfFile, joints:Array<Int>):Array<BoneInfo> {
		var parents = parentsOf(file);
		return [
			for (joint in joints) {
				var parent = -1, above = parents.get(joint);
				while (above != null && parent == -1) {
					parent = joints.indexOf(above);
					if (parent == -1)
						above = parents.get(above);
				}
				new BoneInfo(Models.boneName(file.nodes[joint].name), parent);
			}
		];
	}

	/** Returns a file's animations as raylib 6.2's `LoadModelAnimationsGLTF` makes them, of its first skin's joints: each sampled at 60
		frames a second, (int)(duration * 60) + 1 frames, its duration its channels' last key; each frame's pose a joint's channels at that
		time (its node's own transform where it has none), after the nodes between it and its nearest joint above that aren't joints,
		then put in the model by its parents (raylib's `BuildPoseFromParentJoints`). None for a file without skins.

		@param file  The file, its buffers read.
		@param path  Its path, for raylib's messages.
		@return  The animations. */
	public static function fromGltf(file:GltfFile, path:String):Array<ModelAnimation> {
		var skins = file.skins;
		if (skins.length == 0)
			return [];
		var nodes = file.nodes, parents = parentsOf(file);
		var joints = skins[0].joints, jointCount = joints.length;
		// Per joint, the static transform of the nodes between it and its nearest joint ancestor that aren't joints.
		var extOffset = [
			for (k in 0...jointCount) {
				var offset = MatrixIdentity(), n = parents.get(joints[k]);
				while (n != null) {
					if (joints.indexOf(n) >= 0)
						break;
					offset = MatrixMultiply(offset,
						trs(nodes[n].local.position.x, nodes[n].local.position.y, nodes[n].local.position.z,
							new Quaternion(nodes[n].local.rotation.x, nodes[n].local.rotation.y, nodes[n].local.rotation.z, nodes[n].local.rotation.w),
							nodes[n].local.scale.x, nodes[n].local.scale.y, nodes[n].local.scale.z));
					n = parents.get(n);
				}
				offset;
			}
		];
		var animations = [];
		for (a => data in file.animations) {
			var anim = new ModelAnimation();
			var bones = Animations.bones(file, joints);
			anim.bones = bones;
			anim.boneCount = bones.length;
			// Each bone's channels: the last of each kind wins, as raylib keeps it.
			var translate:Array<Int> = [for (_ in 0...anim.boneCount) -1],
				rotate = translate.copy(),
				scale = translate.copy();
			var animDuration = 0.;
			for (j => channel in data.channels) {
				var boneIndex = channel.node < 0 ? -1 : joints.indexOf(channel.node);
				if (boneIndex == -1 || channel.sampler < 0 || channel.sampler >= data.samplers.length)
					continue;
				switch channel.path {
					case "translation":
						translate[boneIndex] = channel.sampler;
					case "rotation":
						rotate[boneIndex] = channel.sampler;
					case "scale":
						scale[boneIndex] = channel.sampler;
					case _:
						Runtime.log(4, 'MODEL: [$path] Unsupported target_path on channel $j\'s sampler for animation $a. Skipping.');
				}
				var input = data.samplers[channel.sampler].input;
				if (input.length == 0) {
					Runtime.log(4, 'MODEL: [$path] Failed to load input time');
					continue;
				}
				var time = input[input.length - 1];
				animDuration = time > animDuration ? time : animDuration;
			}
			anim.name = Models.boneName(data.name);
			anim.frameCount = Std.int(float32(animDuration * FRAMERATE)) + 1;
			anim.framePoses = [];
			for (j in 0...anim.frameCount) {
				var pose = [];
				var time = float32(j / FRAMERATE);
				for (k in 0...anim.boneCount) {
					var local = nodes[joints[k]].local;
					var translation = new Vector3(local.position.x, local.position.y, local.position.z);
					var rotation = new Quaternion(local.rotation.x, local.rotation.y, local.rotation.z, local.rotation.w);
					var scaling = new Vector3(local.scale.x, local.scale.y, local.scale.z);
					if (translate[k] >= 0) {
						var s = data.samplers[translate[k]],
							v = poseAtTime(s.interpolation, s.input, s.output, time, 3);
						if (v != null)
							translation = new Vector3(v[0], v[1], v[2]);
						else
							Runtime.log(3, 'MODEL: [$path] Failed to load translate pose data for bone ${bones[k].name}');
					}
					if (rotate[k] >= 0) {
						var s = data.samplers[rotate[k]],
							v = poseAtTime(s.interpolation, s.input, s.output, time, 4);
						if (v != null)
							rotation = new Quaternion(v[0], v[1], v[2], v[3]);
						else
							Runtime.log(3, 'MODEL: [$path] Failed to load rotate pose data for bone ${bones[k].name}');
					}
					if (scale[k] >= 0) {
						var s = data.samplers[scale[k]],
							v = poseAtTime(s.interpolation, s.input, s.output, time, 3);
						if (v != null)
							scaling = new Vector3(v[0], v[1], v[2]);
						else
							Runtime.log(3, 'MODEL: [$path] Failed to load scale pose data for bone ${bones[k].name}');
					}
					// The joint's own transform, then the static offsets of the nodes above it that aren't joints, so the pose is the
					// joint's in its skeleton parent.
					var jointLocal = trs(translation.x, translation.y, translation.z, rotation, scaling.x, scaling.y, scaling.z);
					var combined = MatrixMultiply(jointLocal, extOffset[k]);
					var tr = new Transform();
					MatrixDecompose(combined, tr.translation, tr.rotation, tr.scale);
					pose.push(tr);
				}
				buildPoseFromParentJoints(bones, pose);
				anim.framePoses.push(pose);
			}
			Runtime.log(3,
				'MODEL: [$path] Loaded animation: ${data.name == "" ? "NULL" : data.name} | Frames: ${anim.frameCount} | Duration: ${fixed(animDuration)}s');
			animations.push(anim);
		}
		if (skins.length > 1)
			Runtime.log(4, 'MODEL: [$path] Expected one unique skin to load animation data from, but found ${skins.length}');
		return animations;
	}

	// Scale, then rotation, then translation, as raylib composes a node's transform.
	static function trs(tx:Float, ty:Float, tz:Float, rotation:Quaternion, sx:Float, sy:Float, sz:Float):Matrix {
		return MatrixMultiply(MatrixMultiply(MatrixScale(sx, sy, sz), QuaternionToMatrix(rotation)), MatrixTranslate(tx, ty, tz));
	}

	// raylib 6.2's GetPoseAtTimeGLTF: a sampler's value at a time, size 3 (translation, scale) or 4 (a rotation); null for an
	// interpolation it doesn't know. Before the first key the first interval's start; at or past the last, the last interval, clamped
	// (step then gives the second last key, as raylib's does).
	static function poseAtTime(interpolation:String, input:Array<Float>, output:Array<Float>, time:Float, size:Int):Null<Array<Float>> {
		var type = switch interpolation {
			case "STEP": 0;
			case "LINEAR": 1;
			case "CUBICSPLINE": 2;
			case _: -1;
		}
		if (type < 0)
			return null;
		var tstart = 0., tend = 0., keyframe = 0, found = false;
		for (i in 0...input.length - 1) {
			tstart = input[i];
			tend = input[i + 1];
			if (tstart <= time && time < tend) {
				keyframe = i;
				found = true;
				break;
			}
		}
		// No interval holds a time at or past the last key, as the search above wants time < tend: the edge interval instead.
		if (!found && input.length >= 2) {
			keyframe = input.length - 2;
			if (time < input[0])
				keyframe = 0;
			tstart = input[keyframe];
			tend = input[keyframe + 1];
		}
		// A constant animation needs no interpolation.
		if (FloatEquals(tend, tstart) == 1)
			type = 0;
		var duration = float32(Math.max(tend - tstart, Raymath.EPSILON));
		var t = float32((time - tstart) / duration);
		t = t < 0 ? 0 : t;
		t = t > 1 ? 1 : t;
		inline function at(element:Int):Array<Float>
			return [
				for (c in 0...size)
					element * size + c < output.length ? output[element * size + c] : 0
			];
		if (size == 3) {
			inline function v3(a:Array<Float>):Vector3
				return new Vector3(a[0], a[1], a[2]);
			var r = switch type {
				case 0:
					v3(at(keyframe));
				case 1:
					Vector3Lerp(v3(at(keyframe)), v3(at(keyframe + 1)), t);
				case _:
					Vector3CubicHermite(v3(at(3 * keyframe + 1)), v3(at(3 * keyframe + 2)), v3(at(3 * (keyframe + 1) + 1)), v3(at(3 * (keyframe + 1))), t);
			}
			return [r.x, r.y, r.z];
		}
		inline function v4(a:Array<Float>, w:Null<Float>):Vector4
			return new Vector4(a[0], a[1], a[2], w == null ? a[3] : w);
		var r = switch type {
			case 0:
				v4(at(keyframe), null);
			case 1:
				QuaternionSlerp(v4(at(keyframe), null), v4(at(keyframe + 1), null), t);
			case _:
				var v1 = QuaternionNormalize(v4(at(3 * keyframe + 1), null));
				var outTangent1 = v4(at(3 * keyframe + 2), 0);
				var v2 = QuaternionNormalize(v4(at(3 * (keyframe + 1) + 1), null));
				var inTangent2 = v4(at(3 * (keyframe + 1)), 0);
				if (Vector4DotProduct(v1, v2) < 0)
					v2 = Vector4Negate(v2);
				outTangent1 = Vector4Scale(outTangent1, duration);
				inTangent2 = Vector4Scale(inTangent2, duration);
				QuaternionCubicHermiteSpline(v1, outTangent1, v2, inTangent2, t);
		}
		return [r.x, r.y, r.z, r.w];
	}

	// raylib's BuildPoseFromParentJoints: each bone's pose put in its parent's, parents first; a bone listed before its parent is left,
	// with raylib's warning.
	static function buildPoseFromParentJoints(bones:Array<BoneInfo>, transforms:Array<Transform>):Void {
		for (i in 0...bones.length) {
			var parent = bones[i].parent;
			if (parent < 0)
				continue;
			if (parent > i) {
				Runtime.log(4, 'Skipping bone not topologically sorted: Bone $i has parent $parent');
				continue;
			}
			var t = transforms[i], p = transforms[parent];
			t.rotation = QuaternionMultiply(p.rotation, t.rotation);
			t.scale = Vector3Multiply(t.scale, p.scale);
			t.translation = Vector3Multiply(t.translation, p.scale);
			t.translation = Vector3RotateByQuaternion(t.translation, p.rotation);
			t.translation = Vector3Add(t.translation, p.translation);
		}
	}

	/** Poses a model by a frame of an animation, as raylib 6.2's `UpdateModelAnimationBones`: the frame's whole part and the next (each
		wrapped to the animation's frames) mixed by its fraction, lerped and slerped, into the model's pose; each bone's matrix its bind
		pose's inverse, then the pose. Nothing for a model without bones or an animation without frames.

		@param model  The model.
		@param anim  The animation.
		@param frame  The frame, fractional. */
	public static function updateBones(model:Model, anim:ModelAnimation, frame:Float):Void {
		if (model.boneMatrices == null)
			return;
		if (anim.frameCount <= 0 || model.bones == null || anim.framePoses == null)
			return;
		var currentFrame = truncate(frame);
		var nextFrame = currentFrame + 1;
		var blend = Clamp(frame - currentFrame, 0, 1);
		if (currentFrame >= anim.frameCount)
			currentFrame = currentFrame % anim.frameCount;
		if (nextFrame >= anim.frameCount)
			nextFrame = nextFrame % anim.frameCount;
		for (boneIndex in 0...model.boneCount) {
			var a = anim.framePoses[currentFrame][boneIndex],
				b = anim.framePoses[nextFrame][boneIndex];
			setPose(model, boneIndex, Vector3Lerp(a.translation, b.translation, blend), QuaternionSlerp(a.rotation, b.rotation, blend),
				Vector3Lerp(a.scale, b.scale, blend));
		}
	}

	/** Poses a model by two animations mixed, as raylib 6.2's `UpdateModelAnimationBonesEx`: each at its frame as `updateBones` takes
		one, then the two lerped and slerped by the blend. Nothing for a blend outside 0 to 1 or an animation without frames.

		@param model  The model.
		@param animA  The first animation.
		@param frameA  Its frame, fractional.
		@param animB  The second animation.
		@param frameB  Its frame, fractional.
		@param blend  How much of the second, 0 to 1. */
	public static function updateBonesEx(model:Model, animA:ModelAnimation, frameA:Float, animB:ModelAnimation, frameB:Float, blend:Float):Void {
		if (model.boneMatrices == null)
			return;
		if (animA.frameCount <= 0 || animA.framePoses == null || animB.frameCount <= 0 || animB.framePoses == null || !(blend >= 0 && blend <= 1))
			return;
		// raylib wraps the frame before taking its fraction, so a frame past the end mixes with a fraction above 1, clamped.
		var currentFrameA = truncate(frameA) % animA.frameCount;
		var nextFrameA = currentFrameA + 1;
		var blendA = Clamp(frameA - currentFrameA, 0, 1);
		if (nextFrameA >= animA.frameCount)
			nextFrameA = nextFrameA % animA.frameCount;
		var currentFrameB = truncate(frameB) % animB.frameCount;
		var nextFrameB = currentFrameB + 1;
		var blendB = Clamp(frameB - currentFrameB, 0, 1);
		if (nextFrameB >= animB.frameCount)
			nextFrameB = nextFrameB % animB.frameCount;
		for (boneIndex in 0...model.boneCount) {
			var a0 = animA.framePoses[currentFrameA][boneIndex],
				a1 = animA.framePoses[nextFrameA][boneIndex];
			var b0 = animB.framePoses[currentFrameB][boneIndex],
				b1 = animB.framePoses[nextFrameB][boneIndex];
			var ta = Vector3Lerp(a0.translation, a1.translation, blendA),
				ra = QuaternionSlerp(a0.rotation, a1.rotation, blendA),
				sa = Vector3Lerp(a0.scale, a1.scale, blendA);
			var tb = Vector3Lerp(b0.translation, b1.translation, blendB),
				rb = QuaternionSlerp(b0.rotation, b1.rotation, blendB),
				sb = Vector3Lerp(b0.scale, b1.scale, blendB);
			setPose(model, boneIndex, Vector3Lerp(ta, tb, blend), QuaternionSlerp(ra, rb, blend), Vector3Lerp(sa, sb, blend));
		}
	}

	// A bone's pose, and its matrix from it: the bind pose's inverse, then the pose.
	static function setPose(model:Model, boneIndex:Int, translation:Vector3, rotation:Quaternion, scale:Vector3):Void {
		var pose = model.pose[boneIndex];
		pose.translation = translation;
		pose.rotation = rotation;
		pose.scale = scale;
		var bind = model.bindPose[boneIndex];
		var bindPoseMatrix = trs(bind.translation.x, bind.translation.y, bind.translation.z, bind.rotation, bind.scale.x, bind.scale.y, bind.scale.z);
		var currentPoseMatrix = trs(translation.x, translation.y, translation.z, rotation, scale.x, scale.y, scale.z);
		model.boneMatrices[boneIndex] = MatrixMultiply(MatrixInvert(bindPoseMatrix), currentPoseMatrix);
	}

	/** Moves each skinned mesh's vertices by the model's bone matrices, as raylib 6.2's `UpdateModelAnimationVertexBuffers`: a vertex's
		position and normal (by the matrices inverted and transposed, not normalized) each bone's times its weight, added; the mesh's
		position and normal buffers on the GPU then made of them. A mesh whose material's shader reads the bone ids skins itself and is
		left.

		@param model  The model. */
	public static function skin(model:Model):Void {
		var normalMatrices:Null<Array<Matrix>> = null;
		for (m in 0...model.meshCount) {
			var mesh = model.meshes[m];
			if (mesh.boneWeights == null || mesh.boneIds == null)
				continue;
			var material = model.materials[model.meshMaterial[m]];
			if (material != null
				&& material.shader != null
				&& material.shader.locs != null
				&& material.shader.locs[Raylib.SHADER_LOC_VERTEX_BONEIDS] != -1)
				continue;
			var count = mesh.vertexCount * 3;
			if (mesh.animVertices == null)
				mesh.animVertices = mesh.vertices.slice(0, count);
			if (mesh.normals != null && mesh.animNormals == null)
				mesh.animNormals = mesh.normals.slice(0, count);
			// A normal's matrix depends on its bone alone: once a bone, not once a vertex.
			if (mesh.normals != null && normalMatrices == null)
				normalMatrices = [
					for (b in 0...(model.boneCount < 256 ? model.boneCount : 256))
						MatrixTranspose(MatrixInvert(model.boneMatrices[b]))
				];
			var vertices = mesh.vertices,
				normals = mesh.normals,
				anim = mesh.animVertices,
				animNormals = mesh.animNormals;
			var boneCounter = 0, bufferUpdateRequired = false;
			var v = 0;
			while (v < count) {
				anim[v] = 0;
				anim[v + 1] = 0;
				anim[v + 2] = 0;
				if (animNormals != null) {
					animNormals[v] = 0;
					animNormals[v + 1] = 0;
					animNormals[v + 2] = 0;
				}
				for (_ in 0...4) {
					var boneWeight = mesh.boneWeights[boneCounter];
					var boneIndex = mesh.boneIds[boneCounter];
					boneCounter++;
					// Nothing to add for a bone of no weight.
					if (boneWeight == 0)
						continue;
					var bone = model.boneMatrices[boneIndex];
					var x = vertices[v],
						y = vertices[v + 1],
						z = vertices[v + 2];
					anim[v] += (bone.m0 * x + bone.m4 * y + bone.m8 * z + bone.m12) * boneWeight;
					anim[v + 1] += (bone.m1 * x + bone.m5 * y + bone.m9 * z + bone.m13) * boneWeight;
					anim[v + 2] += (bone.m2 * x + bone.m6 * y + bone.m10 * z + bone.m14) * boneWeight;
					bufferUpdateRequired = true;
					if (normals != null && animNormals != null) {
						var n = normalMatrices[boneIndex];
						var nx = normals[v],
							ny = normals[v + 1],
							nz = normals[v + 2];
						animNormals[v] += (n.m0 * nx + n.m4 * ny + n.m8 * nz + n.m12) * boneWeight;
						animNormals[v + 1] += (n.m1 * nx + n.m5 * ny + n.m9 * nz + n.m13) * boneWeight;
						animNormals[v + 2] += (n.m2 * nx + n.m6 * ny + n.m10 * nz + n.m14) * boneWeight;
					}
				}
				v += 3;
			}
			if (bufferUpdateRequired)
				Models.animate(mesh, anim, normals != null ? animNormals : null);
		}
	}

	// C's cast of a float to int, toward 0.
	static function truncate(x:Float):Int
		return x < 0 ? Std.int(Math.ceil(x)) : Std.int(Math.floor(x));

	// A number as C's float holds it.
	static function float32(x:Float):Float
		return FPHelper.i32ToFloat(FPHelper.floatToI32(x));

	// A number as C's %f prints it, to 6 places.
	static function fixed(x:Float):String {
		var scaled = Math.round(Math.abs(x) * 1000000);
		var whole = Math.floor(scaled / 1000000),
			part = Std.string(scaled - whole * 1000000);
		while (part.length < 6)
			part = "0" + part;
		return (x < 0 ? "-" : "") + whole + "." + part;
	}
}
