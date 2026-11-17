package helix.raylib.internal;

import haxe.io.FPHelper;
import helix.math.Interpolate;
import helix.math.Matrix4;
import helix.formats.gltf.GltfFile;
import helix.raylib.*;
import helix.raylib.modules.RMath.*;

/** Reads a glTF file's animations as raylib 6.2's `LoadModelAnimationsGLTF` does, and poses a model's bones by them as its
	`UpdateModelAnimationBones` and `UpdateModelAnimationBonesEx` do: their code ported line by line, on helix-math's vectors and rotations. */
@:noCompletion
@:access(helix.raylib.modules.RMath)
@:access(helix.raylib.modules.RModels)
class Animations {
	/** The frames a second raylib samples an animation at. */
	static inline final FRAMERATE = 60.0;

	// A bone's rotation part way between two rotations, chosen as raylib's QuaternionSlerp chooses it, which the poses of raylib's C
	// are matched by: the first rotation when the two are one to C's floats, the straight line between two near each other (nlerp,
	// which takes no trigonometry), and the arc between the rest (slerp).
	static inline function rotationBetween(from:Quaternion, to:Quaternion, amount:Float, ?out:Quaternion):Quaternion {
		var cos = from.x * to.x + from.y * to.y + from.z * to.z + from.w * to.w;
		// Each product and sum rounded to a float, as C's are.
		var rounded = f32(f32(f32(f32(f32(from.x) * f32(to.x)) + f32(f32(from.y) * f32(to.y))) + f32(f32(from.z) * f32(to.z))) + f32(f32(from.w) * f32(to.w)));
		return Math.abs(rounded) >= 1 ? from.copy(out) : Math.abs(cos) > 0.95 ? Quaternion.nlerp(from, to, amount,
			out) : Quaternion.slerp(from, to, amount, out);
	}

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
							file.setBuffer(m.bufferIndex, Runtime.files.get(m.path))
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
		var joints = file.skins.length > 0 ? file.skins[0].jointIndices : [];
		var parents = parentsOf(file);
		function visit(index:Int):Void {
			var node = nodes[index];
			if (node.meshIndex >= 0)
				for (p in meshes[node.meshIndex].primitives)
					if (p.mode == 4) {
						var parent = parents.get(index);
						out.push(p.jointIndices == null && parent != null && nodes[parent].meshIndex < 0 ? joints.indexOf(parent) : -1);
					}
			for (child in node.childIndices)
				visit(child);
		}
		for (root in file.sceneNodeIndices)
			visit(root);
		return out;
	}

	static function parentsOf(file:GltfFile):Map<Int, Int> {
		var parents = new Map<Int, Int>();
		for (i => node in file.nodes)
			for (child in node.childIndices)
				parents.set(child, i);
		return parents;
	}

	/** Returns a skin's bones as raylib 6.2's `LoadBoneInfoGLTF` makes them: each joint's name and its parent, the
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
				new BoneInfo(file.nodes[joint].name, parent);
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
		var joints = skins[0].jointIndices, jointCount = joints.length;
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
				var boneIndex = channel.nodeIndex < 0 ? -1 : joints.indexOf(channel.nodeIndex);
				if (boneIndex == -1 || channel.samplerIndex < 0 || channel.samplerIndex >= data.samplers.length)
					continue;
				switch channel.path {
					case "translation":
						translate[boneIndex] = channel.samplerIndex;
					case "rotation":
						rotate[boneIndex] = channel.samplerIndex;
					case "scale":
						scale[boneIndex] = channel.samplerIndex;
					case _:
						Runtime.log(4, 'MODEL: [$path] Unsupported target_path on channel $j\'s sampler for animation $a. Skipping.');
				}
				var input = data.samplers[channel.samplerIndex].input;
				if (input.length == 0) {
					Runtime.log(4, 'MODEL: [$path] Failed to load input time');
					continue;
				}
				var time = input[input.length - 1];
				animDuration = time > animDuration ? time : animDuration;
			}
			anim.name = data.name;
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
		if (Interpolate.equals(tend, tstart, Raymath.EPSILON))
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
					Vector3.lerp(v3(at(keyframe)), v3(at(keyframe + 1)), t);
				case _:
					Vector3.hermite(v3(at(3 * keyframe + 1)), v3(at(3 * keyframe + 2)), v3(at(3 * (keyframe + 1) + 1)), v3(at(3 * (keyframe + 1))), t);
			}
			return [r.x, r.y, r.z];
		}
		inline function q4(a:Array<Float>, w:Null<Float>):Quaternion
			return new Quaternion(a[0], a[1], a[2], w == null ? a[3] : w);
		var r = switch type {
			case 0:
				q4(at(keyframe), null);
			case 1:
				rotationBetween(q4(at(keyframe), null), q4(at(keyframe + 1), null), t);
			case _:
				var q1 = q4(at(3 * keyframe + 1), null);
				q1.normalize(q1);
				var outTangent1 = q4(at(3 * keyframe + 2), 0);
				var q2 = q4(at(3 * (keyframe + 1) + 1), null);
				q2.normalize(q2);
				var inTangent2 = q4(at(3 * (keyframe + 1)), 0);
				// The short way round.
				if (q1.x * q2.x + q1.y * q2.y + q1.z * q2.z + q1.w * q2.w < 0)
					q2.set(-q2.x, -q2.y, -q2.z, -q2.w);
				outTangent1.set(outTangent1.x * duration, outTangent1.y * duration, outTangent1.z * duration, outTangent1.w * duration);
				inTangent2.set(inTangent2.x * duration, inTangent2.y * duration, inTangent2.z * duration, inTangent2.w * duration);
				Quaternion.hermite(q1, outTangent1, q2, inTangent2, t);
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
			t.rotation = Quaternion.compose(t.rotation, p.rotation);
			t.scale = t.scale.multiply(p.scale);
			var moved = t.translation.multiply(p.scale);
			p.rotation.transformPoint(moved.x, moved.y, moved.z, moved);
			t.translation = moved.add(p.translation, moved);
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
		var blend = Interpolate.clamp(frame - currentFrame, 0, 1);
		if (currentFrame >= anim.frameCount)
			currentFrame = currentFrame % anim.frameCount;
		if (nextFrame >= anim.frameCount)
			nextFrame = nextFrame % anim.frameCount;
		var poses = posed(model);
		for (boneIndex in 0...model.boneCount) {
			var a = anim.framePoses[currentFrame][boneIndex],
				b = anim.framePoses[nextFrame][boneIndex],
				pose = poses[boneIndex];
			Vector3.lerp(a.translation, b.translation, blend, pose.translation);
			rotationBetween(a.rotation, b.rotation, blend, pose.rotation);
			Vector3.lerp(a.scale, b.scale, blend, pose.scale);
			setPose(model, boneIndex, pose);
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
		var blendA = Interpolate.clamp(frameA - currentFrameA, 0, 1);
		if (nextFrameA >= animA.frameCount)
			nextFrameA = nextFrameA % animA.frameCount;
		var currentFrameB = truncate(frameB) % animB.frameCount;
		var nextFrameB = currentFrameB + 1;
		var blendB = Interpolate.clamp(frameB - currentFrameB, 0, 1);
		if (nextFrameB >= animB.frameCount)
			nextFrameB = nextFrameB % animB.frameCount;
		var poses = posed(model);
		var ta = mixA.translation, ra = mixA.rotation, sa = mixA.scale;
		var tb = mixB.translation, rb = mixB.rotation, sb = mixB.scale;
		for (boneIndex in 0...model.boneCount) {
			var a0 = animA.framePoses[currentFrameA][boneIndex],
				a1 = animA.framePoses[nextFrameA][boneIndex];
			var b0 = animB.framePoses[currentFrameB][boneIndex],
				b1 = animB.framePoses[nextFrameB][boneIndex];
			Vector3.lerp(a0.translation, a1.translation, blendA, ta);
			rotationBetween(a0.rotation, a1.rotation, blendA, ra);
			Vector3.lerp(a0.scale, a1.scale, blendA, sa);
			Vector3.lerp(b0.translation, b1.translation, blendB, tb);
			rotationBetween(b0.rotation, b1.rotation, blendB, rb);
			Vector3.lerp(b0.scale, b1.scale, blendB, sb);
			var pose = poses[boneIndex];
			Vector3.lerp(ta, tb, blend, pose.translation);
			rotationBetween(ra, rb, blend, pose.rotation);
			Vector3.lerp(sa, sb, blend, pose.scale);
			setPose(model, boneIndex, pose);
		}
	}

	/** Poses a model by two animations mixed bone by bone (helix-raylib's `UpdateModelAnimationMasked`): each bone's pose relative to its
		parent taken from each animation's frame as `updateBonesEx` takes them, mixed by its weight times blend, then put in the model by
		its parents as `buildPoseFromParentJoints` puts them. With `BLEND_ROTATION_MODEL`, a weighted bone's rotation is instead each
		animation's own in the model, mixed by its weight. The blend is clamped to [0, 1]. Refused for a model without bones or an
		animation without frames. Refused, with the reason logged, for a mask or an animation of another count of bones than the model's.

		@param model  The model.
		@param animA  The first animation.
		@param frameA  Its frame, fractional.
		@param animB  The second animation.
		@param frameB  Its frame, fractional.
		@param boneWeights  Each bone's share of the second, 0 to 1.
		@param blend  How much of the second the weighted bones take.
		@param rotationSpace  `BLEND_ROTATION_LOCAL` (0) or `BLEND_ROTATION_MODEL` (1).
		@return  False when refused. */
	public static function updateBonesMasked(model:Model, animA:ModelAnimation, frameA:Float, animB:ModelAnimation, frameB:Float, boneWeights:Array<Float>,
			blend:Float, rotationSpace:Int):Bool {
		if (model.boneMatrices == null || model.bones == null)
			return false;
		if (animA.frameCount <= 0 || animA.framePoses == null || animB.frameCount <= 0 || animB.framePoses == null)
			return false;
		blend = Interpolate.clamp(blend, 0, 1);
		var count = model.boneCount;
		if (boneWeights.length != count || animA.boneCount != count || animB.boneCount != count) {
			Runtime.log(4,
				'MODEL: UpdateModelAnimationMasked: the model has $count bones, the mask ${boneWeights.length}, the animations ' +
				'${animA.boneCount} and ${animB.boneCount}');
			return false;
		}
		var localA = localFrames(animA), localB = localFrames(animB);
		var currentFrameA = truncate(frameA) % animA.frameCount;
		var nextFrameA = (currentFrameA + 1) % animA.frameCount;
		var blendA = Interpolate.clamp(frameA - currentFrameA, 0, 1);
		var currentFrameB = truncate(frameB) % animB.frameCount;
		var nextFrameB = (currentFrameB + 1) % animB.frameCount;
		var blendB = Interpolate.clamp(frameB - currentFrameB, 0, 1);
		var poses = posed(model);
		var ta = mixA.translation, ra = mixA.rotation, sa = mixA.scale;
		var tb = mixB.translation, rb = mixB.rotation, sb = mixB.scale;
		var t = mixed.translation, r = mixed.rotation, s = mixed.scale;
		for (boneIndex in 0...count) {
			var a0 = localA[currentFrameA][boneIndex],
				a1 = localA[nextFrameA][boneIndex];
			var b0 = localB[currentFrameB][boneIndex],
				b1 = localB[nextFrameB][boneIndex];
			Vector3.lerp(a0.translation, a1.translation, blendA, ta);
			rotationBetween(a0.rotation, a1.rotation, blendA, ra);
			Vector3.lerp(a0.scale, a1.scale, blendA, sa);
			Vector3.lerp(b0.translation, b1.translation, blendB, tb);
			rotationBetween(b0.rotation, b1.rotation, blendB, rb);
			Vector3.lerp(b0.scale, b1.scale, blendB, sb);
			var weight = Interpolate.clamp(boneWeights[boneIndex] * blend, 0, 1);
			Vector3.lerp(ta, tb, weight, t);
			rotationBetween(ra, rb, weight, r);
			Vector3.lerp(sa, sb, weight, s);
			var pose = poses[boneIndex],
				parent = model.bones[boneIndex].parent;
			if (parent < 0 || parent >= boneIndex)
				copyInto(mixed, pose);
			else
				composeInto(poses[parent], mixed, pose);
			if (rotationSpace == 1 && weight > 0) {
				// Each animation's rotation in the model, from its own frames there, mixed by the weight.
				rotationBetween(animA.framePoses[currentFrameA][boneIndex].rotation, animA.framePoses[nextFrameA][boneIndex].rotation, blendA, modelA);
				rotationBetween(animB.framePoses[currentFrameB][boneIndex].rotation, animB.framePoses[nextFrameB][boneIndex].rotation, blendB, modelB);
				rotationBetween(modelA, modelB, weight, pose.rotation);
			}
			setPose(model, boneIndex, pose);
		}
		return true;
	}

	// The pose updateBonesMasked mixes for a bone, relative to its parent, before it's put in the model.
	static final mixed = new Transform();

	// The two animations' rotations in the model that updateBonesMasked mixes for a weighted bone with BLEND_ROTATION_MODEL.
	static final modelA = new Quaternion(0, 0, 0, 1);
	static final modelB = new Quaternion(0, 0, 0, 1);

	// An animation's frames relative to each bone's parent, worked out from its frames in the model the first time and kept on it: each
	// bone's pose taken back out of its parent's, the inverse of buildPoseFromParentJoints.
	static function localFrames(anim:ModelAnimation):Array<Array<Transform>> {
		if (anim.localPoses != null)
			return anim.localPoses;
		var bones = anim.bones;
		var out = [];
		for (frame in anim.framePoses) {
			var local = [];
			for (i => pose in frame) {
				var parent = bones == null ? -1 : bones[i].parent;
				var l = new Transform();
				if (parent < 0 || parent >= i)
					copyInto(pose, l);
				else
					uncomposeInto(frame[parent], pose, l);
				local.push(l);
			}
			out.push(local);
		}
		return anim.localPoses = out;
	}

	// out = a transform copied, its vectors kept.
	static function copyInto(from:Transform, out:Transform):Void {
		var t = from.translation, r = from.rotation, s = from.scale;
		out.translation.x = t.x;
		out.translation.y = t.y;
		out.translation.z = t.z;
		out.rotation.x = r.x;
		out.rotation.y = r.y;
		out.rotation.z = r.z;
		out.rotation.w = r.w;
		out.scale.x = s.x;
		out.scale.y = s.y;
		out.scale.z = s.z;
	}

	// out = local put in its parent, as buildPoseFromParentJoints puts it: the parent's rotation times local's, the scales multiplied,
	// local's translation scaled by the parent's, turned by its rotation and moved by its translation.
	static function composeInto(parent:Transform, local:Transform, out:Transform):Void {
		var pr = parent.rotation, ps = parent.scale, pt = parent.translation;
		var lr = local.rotation, ls = local.scale, lt = local.translation;
		multiplyInto(pr.x, pr.y, pr.z, pr.w, lr.x, lr.y, lr.z, lr.w, out.rotation);
		out.scale.x = ls.x * ps.x;
		out.scale.y = ls.y * ps.y;
		out.scale.z = ls.z * ps.z;
		rotateInto(lt.x * ps.x, lt.y * ps.y, lt.z * ps.z, pr.x, pr.y, pr.z, pr.w, out.translation);
		out.translation.x += pt.x;
		out.translation.y += pt.y;
		out.translation.z += pt.z;
	}

	// out = a pose in the model taken back out of its parent's: composeInto undone.
	static function uncomposeInto(parent:Transform, pose:Transform, out:Transform):Void {
		var pr = parent.rotation, ps = parent.scale, pt = parent.translation;
		var r = pose.rotation, s = pose.scale, t = pose.translation;
		multiplyInto(-pr.x, -pr.y, -pr.z, pr.w, r.x, r.y, r.z, r.w, out.rotation);
		out.scale.x = ps.x == 0 ? 0 : s.x / ps.x;
		out.scale.y = ps.y == 0 ? 0 : s.y / ps.y;
		out.scale.z = ps.z == 0 ? 0 : s.z / ps.z;
		rotateInto(t.x - pt.x, t.y - pt.y, t.z - pt.z, -pr.x, -pr.y, -pr.z, pr.w, out.translation);
		out.translation.x = ps.x == 0 ? 0 : out.translation.x / ps.x;
		out.translation.y = ps.y == 0 ? 0 : out.translation.y / ps.y;
		out.translation.z = ps.z == 0 ? 0 : out.translation.z / ps.z;
	}

	// out = the quaternion a times b, raymath's QuaternionMultiply.
	static function multiplyInto(ax:Float, ay:Float, az:Float, aw:Float, bx:Float, by:Float, bz:Float, bw:Float, out:Quaternion):Void {
		out.x = ax * bw + aw * bx + ay * bz - az * by;
		out.y = ay * bw + aw * by + az * bx - ax * bz;
		out.z = az * bw + aw * bz + ax * by - ay * bx;
		out.w = aw * bw - ax * bx - ay * by - az * bz;
	}

	// out = the vector turned by the quaternion, raymath's Vector3RotateByQuaternion.
	static function rotateInto(x:Float, y:Float, z:Float, qx:Float, qy:Float, qz:Float, qw:Float, out:Vector3):Void {
		out.x = x * (qx * qx + qw * qw - qy * qy - qz * qz) + y * (2 * qx * qy - 2 * qw * qz) + z * (2 * qx * qz + 2 * qw * qy);
		out.y = x * (2 * qw * qz + 2 * qx * qy) + y * (qw * qw - qx * qx + qy * qy - qz * qz) + z * (-2 * qw * qx + 2 * qy * qz);
		out.z = x * (-2 * qw * qy + 2 * qx * qz) + y * (2 * qw * qx + 2 * qy * qz) + z * (qw * qw - qx * qx - qy * qy + qz * qz);
	}

	// The model's pose, a transform a bone, each with vectors of its own that the posing functions write into: made the first time.
	static function posed(model:Model):Array<Transform> {
		if (model.pose == null)
			model.pose = [for (_ in 0...model.boneCount) new Transform()];
		return model.pose;
	}

	// The two animations' poses updateBonesEx mixes, written for each bone.
	static final mixA = new Transform();
	static final mixB = new Transform();

	// A bone's matrix from its pose, just written into the model's: the bind pose's inverse, then the pose, as raylib's
	// MatrixMultiply(MatrixInvert(bind), current) and helix-raylib's raymath compute it (through Matrix4's compose), written into the
	// bone's matrix in place, so a pose allocates no matrix.
	static function setPose(model:Model, boneIndex:Int, pose:Transform):Void {
		var translation = pose.translation,
			rotation = pose.rotation,
			scale = pose.scale;
		Matrix4.fromScale(scale.x, scale.y, scale.z, scaled);
		Matrix4.fromQuaternion(rotation.x, rotation.y, rotation.z, rotation.w, rotated);
		Matrix4.compose(scaled, rotated, current);
		Matrix4.fromTranslation(translation.x, translation.y, translation.z, scaled);
		Matrix4.compose(current, scaled, rotated);
		var v = Matrix4.compose(inverseBind(model, boneIndex), rotated, current).values;
		var m = model.boneMatrices[boneIndex];
		m.m0 = v[0];
		m.m1 = v[1];
		m.m2 = v[2];
		m.m3 = v[3];
		m.m4 = v[4];
		m.m5 = v[5];
		m.m6 = v[6];
		m.m7 = v[7];
		m.m8 = v[8];
		m.m9 = v[9];
		m.m10 = v[10];
		m.m11 = v[11];
		m.m12 = v[12];
		m.m13 = v[13];
		m.m14 = v[14];
		m.m15 = v[15];
	}

	// What setPose works in.
	static final scaled = new Matrix4();
	static final rotated = new Matrix4();
	static final current = new Matrix4();

	// A bone's bind pose's matrix inverted, kept on the model with the ten numbers it was made from, and made again only when they change.
	static function inverseBind(model:Model, boneIndex:Int):Matrix4 {
		var bind = model.bindPose[boneIndex];
		var t = bind.translation, r = bind.rotation, s = bind.scale;
		var keys = model.inverseBindKeys, at = boneIndex * 10;
		if (keys.length < at + 10)
			keys.resize(at + 10);
		var inverse = model.inverseBinds[boneIndex];
		if (inverse == null || keys[at] != t.x || keys[at + 1] != t.y || keys[at + 2] != t.z || keys[at + 3] != r.x || keys[at + 4] != r.y
			|| keys[at + 5] != r.z || keys[at + 6] != r.w || keys[at + 7] != s.x || keys[at + 8] != s.y || keys[at + 9] != s.z) {
			inverse = model.inverseBinds[boneIndex] = helix.raylib.modules.RModels.toMatrix4(MatrixInvert(trs(t.x, t.y, t.z, r, s.x, s.y, s.z)));
			keys[at] = t.x;
			keys[at + 1] = t.y;
			keys[at + 2] = t.z;
			keys[at + 3] = r.x;
			keys[at + 4] = r.y;
			keys[at + 5] = r.z;
			keys[at + 6] = r.w;
			keys[at + 7] = s.x;
			keys[at + 8] = s.y;
			keys[at + 9] = s.z;
		}
		return inverse;
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
