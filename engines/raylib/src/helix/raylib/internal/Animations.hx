package helix.raylib.internal;

import haxe.io.FPHelper;
import helix.math.Matrix3D;
import helix.formats.gltf.GltfFile;
import helix.raylib.*;
import helix.raylib.modules.RMath.*;

/** Reads a glTF file's animations as raylib 6.2's `LoadModelAnimationsGLTF` does, and poses a model's bones by them as its
	`UpdateModelAnimationBones` and `UpdateModelAnimationBonesEx` do: their code ported line by line, with raymath's functions. */
@:noCompletion
@:access(helix.raylib.modules.RMath)
@:access(helix.raylib.modules.RModels)
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
		var poses = posed(model);
		for (boneIndex in 0...model.boneCount) {
			var a = anim.framePoses[currentFrame][boneIndex],
				b = anim.framePoses[nextFrame][boneIndex],
				pose = poses[boneIndex];
			vector3LerpInto(a.translation, b.translation, blend, pose.translation);
			quaternionSlerpInto(a.rotation, b.rotation, blend, pose.rotation);
			vector3LerpInto(a.scale, b.scale, blend, pose.scale);
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
		var blendA = Clamp(frameA - currentFrameA, 0, 1);
		if (nextFrameA >= animA.frameCount)
			nextFrameA = nextFrameA % animA.frameCount;
		var currentFrameB = truncate(frameB) % animB.frameCount;
		var nextFrameB = currentFrameB + 1;
		var blendB = Clamp(frameB - currentFrameB, 0, 1);
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
			vector3LerpInto(a0.translation, a1.translation, blendA, ta);
			quaternionSlerpInto(a0.rotation, a1.rotation, blendA, ra);
			vector3LerpInto(a0.scale, a1.scale, blendA, sa);
			vector3LerpInto(b0.translation, b1.translation, blendB, tb);
			quaternionSlerpInto(b0.rotation, b1.rotation, blendB, rb);
			vector3LerpInto(b0.scale, b1.scale, blendB, sb);
			var pose = poses[boneIndex];
			vector3LerpInto(ta, tb, blend, pose.translation);
			quaternionSlerpInto(ra, rb, blend, pose.rotation);
			vector3LerpInto(sa, sb, blend, pose.scale);
			setPose(model, boneIndex, pose);
		}
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
	// MatrixMultiply(MatrixInvert(bind), current) and helix-raylib's raymath compute it (through Matrix3D's compose), written into the
	// bone's matrix in place, so a pose allocates no matrix.
	static function setPose(model:Model, boneIndex:Int, pose:Transform):Void {
		var translation = pose.translation,
			rotation = pose.rotation,
			scale = pose.scale;
		Matrix3D.fromScale(scale.x, scale.y, scale.z, scaled);
		Matrix3D.fromQuaternion(rotation.x, rotation.y, rotation.z, rotation.w, rotated);
		Matrix3D.compose(scaled, rotated, current);
		Matrix3D.fromTranslation(translation.x, translation.y, translation.z, scaled);
		Matrix3D.compose(current, scaled, rotated);
		var v = Matrix3D.compose(inverseBind(model, boneIndex), rotated, current).values;
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
	static final scaled = new Matrix3D();
	static final rotated = new Matrix3D();
	static final current = new Matrix3D();

	// A bone's bind pose's matrix inverted, kept on the model with the ten numbers it was made from, and made again only when they change.
	static function inverseBind(model:Model, boneIndex:Int):Matrix3D {
		var bind = model.bindPose[boneIndex];
		var t = bind.translation, r = bind.rotation, s = bind.scale;
		var keys = model.inverseBindKeys, at = boneIndex * 10;
		if (keys.length < at + 10)
			keys.resize(at + 10);
		var inverse = model.inverseBinds[boneIndex];
		if (inverse == null || keys[at] != t.x || keys[at + 1] != t.y || keys[at + 2] != t.z || keys[at + 3] != r.x || keys[at + 4] != r.y
			|| keys[at + 5] != r.z || keys[at + 6] != r.w || keys[at + 7] != s.x || keys[at + 8] != s.y || keys[at + 9] != s.z) {
			inverse = model.inverseBinds[boneIndex] = helix.raylib.modules.RModels.toMatrix3D(MatrixInvert(trs(t.x, t.y, t.z, r, s.x, s.y, s.z)));
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
