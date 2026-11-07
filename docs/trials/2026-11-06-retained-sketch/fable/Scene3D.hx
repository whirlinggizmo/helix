import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raymath.*;
import helix.raylib.Rlgl.*;
import helix.raylib.extras.Lights.*;
import helix.raylib.extras.Models.*;

// A sketch, not an engine: a three.js-shaped scene drawn through raylib's calls alone, to find what raylib's API has no door for.
// Each place the sketch hits such a gap is marked GAP with a number, and docs/trials/2026-11-06-retained-sketch/sketch.md lists them.
// Type-checks; nothing here runs.

/** Represents a node in the scene: a transform in a tree, with children of its own kind (three.js's `Object3D`). */
class Object3D {
	/** Gets or sets the position, in the parent's units. */
	public var position = new Vector3(0, 0, 0);

	/** Gets or sets the rotation. */
	public var rotation = QuaternionIdentity();

	/** Gets or sets the scale on each axis. */
	public var scale = new Vector3(1, 1, 1);

	/** Gets or sets a value indicating whether the node and its subtree are drawn. */
	public var visible = true;

	/** Gets the node's transform in the world, as `updateMatrixWorld` last computed it. */
	public var matrixWorld(default, null) = MatrixIdentity();

	/** Gets the parent, or null at a tree's top. */
	public var parent(default, null):Null<Object3D> = null;

	/** Gets the children, in drawing order. */
	public var children(default, null):Array<Object3D> = [];

	/** Creates a node that draws nothing, a group for its children. */
	public function new() {}

	/** Adds a child last. */
	public function add(child:Object3D):Void {
		child.parent = this;
		children.push(child);
	}

	/** Removes a child. */
	public function remove(child:Object3D):Void {
		child.parent = null;
		children.remove(child);
	}

	/** Computes the world matrices of the node and its subtree from the parent's.
		raylib's `MatrixMultiply(left, right)` applies `left` first, so the local is scale, rotation, translation and the world is the local then
		the parent's. */
	public function updateMatrixWorld(parentWorld:Matrix):Void {
		var local = MatrixMultiply(MatrixMultiply(MatrixScale(scale.x, scale.y, scale.z), QuaternionToMatrix(rotation)),
			MatrixTranslate(position.x, position.y, position.z));
		matrixWorld = MatrixMultiply(local, parentWorld);
		for (child in children)
			child.updateMatrixWorld(matrixWorld);
	}
}

/** Represents the scene: the tree's top (three.js's `Scene`). */
class Scene3D extends Object3D {
	/** Gets or sets the ambient light's color, written to each lit shader's `ambient`. */
	public var ambient = new Color(40, 40, 40, 255);

	public function new()
		super();
}

/** Represents a camera node (three.js's `PerspectiveCamera`): raylib's `Camera3D` is its handle, placed by the node's world matrix. */
class PerspectiveCamera3D extends Object3D {
	/** Gets raylib's camera, as `BeginMode3D` takes it. */
	public var camera(default, null) = new Camera3D(new Vector3(0, 0, 0), new Vector3(0, 0, -1), new Vector3(0, 1, 0), 45, CAMERA_PERSPECTIVE);

	/** Gets or sets the near plane. raylib keeps one for every camera (`rlSetClipPlanes`), so the renderer sets it before `BeginMode3D`. */
	public var near = 0.1;

	/** Gets or sets the far plane. */
	public var far = 500.;

	public function new()
		super();

	/** Writes the node's world matrix into raylib's camera: its position, a target one unit down its -z, and its up. */
	public function updateCamera():Void {
		camera.position = Vector3Transform(new Vector3(0, 0, 0), matrixWorld);
		camera.target = Vector3Transform(new Vector3(0, 0, -1), matrixWorld);
		camera.up = Vector3Subtract(Vector3Transform(new Vector3(0, 1, 0), matrixWorld), camera.position);
	}
}

/** Represents a geometry: raylib's `Mesh` is its GPU handle (three.js's `BufferGeometry`), shared by any number of `Mesh3D` nodes. */
class Geometry3D {
	/** Gets raylib's mesh. */
	public var mesh(default, null):Mesh;

	/** Gets the bounds at rest, from `GetMeshBoundingBox`. */
	public var bounds(default, null):BoundingBox;

	public function new(mesh:Mesh) {
		this.mesh = mesh;
		bounds = GetMeshBoundingBox(mesh);
	}
}

/** Represents a material: raylib's `Material` is its handle (three.js's `Material`), with the sort flag raylib's hasn't. */
class Material3D {
	/** Gets raylib's material: the shader and the maps `DrawMesh` binds. */
	public var material(default, null):Material;

	/** Gets or sets a value indicating whether the material is drawn after the opaque ones, back to front, without writing depth. */
	public var transparent = false;

	public function new(material:Material)
		this.material = material;

	/** Returns a material of its own from a loaded one: the same maps and shader in a new record, so a change to it changes no other mesh. */
	public static function copyOf(source:Material):Material3D {
		var maps:Array<MaterialMap> = [for (m in source.maps) {texture: m.texture, color: m.color, value: m.value}];
		var copy = new Material(source.shader, maps, source.params);
		copy.unlit = source.unlit;
		return new Material3D(copy);
	}
}

/** Represents a mesh node: a geometry drawn with a material (three.js's `Mesh`), one `DrawMesh` a frame. */
class Mesh3D extends Object3D {
	public var geometry:Geometry3D;
	public var material:Material3D;

	public function new(geometry:Geometry3D, material:Material3D) {
		super();
		this.geometry = geometry;
		this.material = material;
	}

	/** Returns raylib's mesh to draw and to pick: the geometry's. */
	public function meshToDraw():Mesh
		return geometry.mesh;

	/** Returns the bounds in the world: the rest bounds' eight corners through the world matrix, as `GetModelBoundingBox` leaves to the
		program. */
	public function computeWorldBounds():BoundingBox {
		var b = geometry.bounds;
		var min = new Vector3(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY);
		var max = new Vector3(Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY);
		for (i in 0...8) {
			var corner = new Vector3((i & 1) == 0 ? b.min.x : b.max.x, (i & 2) == 0 ? b.min.y : b.max.y, (i & 4) == 0 ? b.min.z : b.max.z);
			var p = Vector3Transform(corner, matrixWorld);
			min = new Vector3(Math.min(min.x, p.x), Math.min(min.y, p.y), Math.min(min.z, p.z));
			max = new Vector3(Math.max(max.x, p.x), Math.max(max.y, p.y), Math.max(max.z, p.z));
		}
		return new BoundingBox(min, max);
	}
}

/** Represents a loaded skinned model's skeleton and animations: raylib's `Model` is the handle the pose lives in (three.js's `Skeleton`
	with its `AnimationMixer`). Its meshes are drawn by `SkinnedMesh3D` nodes, one each. */
class Skeleton3D {
	/** Gets raylib's model, null until loaded. */
	public var model(default, null):Null<Model> = null;

	/** Gets the animations, none until loaded. */
	public var animations(default, null):Array<ModelAnimation> = [];

	/** Gets the nodes drawing the model's meshes, made when it loads. */
	public var meshes(default, null):Array<SkinnedMesh3D> = [];

	public function new() {}

	/** Asynchronously loads the file, then makes a `SkinnedMesh3D` under `parent` for each mesh, each with a material of its own, under the
		PBR shader. */
	public function load(fileName:String, parent:Object3D, shader:Shader):Void {
		LoadModelAsync(fileName, loaded -> {
			model = loaded;
			for (i in 0...loaded.meshCount) {
				var material = Material3D.copyOf(loaded.materials[loaded.meshMaterial[i]]);
				material.material.shader = shader;
				var node = new SkinnedMesh3D(this, i, material);
				meshes.push(node);
				parent.add(node);
			}
		});
		LoadModelAnimationsAsync(fileName, loaded -> animations = loaded);
	}

	/** Poses the model by a frame of an animation: `UpdateModelAnimation`, the pose kept on each mesh until the next call, so each
		`SkinnedMesh3D` draws it through `DrawMesh` under any material. */
	public function pose(animationIndex:Int, frame:Float):Void {
		if (model != null && animationIndex < animations.length)
			UpdateModelAnimation(model, animations[animationIndex], frame);
	}

	/** Asynchronously loads the file again, for a file changed on disk, and swaps the new model into every node drawing the old one.
		GAP 1: a load answers with a new `Model` whose meshes are new `Mesh` records; nothing refills the record the nodes hold, so the
		engine walks every holder. A `Geometry3D` shared by many `Mesh3D` nodes has the same problem, one node at a time. */
	public function reload(fileName:String):Void {
		LoadModelAsync(fileName, loaded -> {
			var old = model;
			model = loaded;
			for (node in meshes)
				node.geometry = new Geometry3D(loaded.meshes[node.meshIndex]);
			if (old != null)
				UnloadModel(old);
		});
	}
}

/** Represents a skinned mesh node (three.js's `SkinnedMesh`): one mesh of a `Skeleton3D`'s model, drawn as the skeleton last posed it. */
class SkinnedMesh3D extends Mesh3D {
	public var skeleton:Skeleton3D;
	public var meshIndex:Int;

	public function new(skeleton:Skeleton3D, meshIndex:Int, material:Material3D) {
		super(new Geometry3D(skeleton.model.meshes[meshIndex]), material);
		this.skeleton = skeleton;
		this.meshIndex = meshIndex;
	}

	/** Returns the mesh as posed, for picking: `GetRayCollisionMesh` reads `vertices`, the bind pose, so the sketch hands it a mesh whose
		positions are `animVertices`, which costs a CPU skin of every vertex at the first read after each pose.
		GAP 4: no ray test reads the pose a `DrawMesh` draws. */
	public function meshToPick():Mesh {
		var posed = new Mesh();
		var source = geometry.mesh;
		posed.vertexCount = source.vertexCount;
		posed.triangleCount = source.triangleCount;
		posed.vertices = source.animVertices != null ? source.animVertices : source.vertices;
		posed.indices = source.indices;
		return posed;
	}
}

/** Represents a light node (three.js's `Light`): color and intensity, placed by the node's world matrix. rlights' `Light` is the slot it is
	written into each frame, one per lit shader. */
class Light3D extends Object3D {
	/** Gets or sets the color. */
	public var color = WHITE;

	/** Gets or sets the intensity, 0 to 1: rlights' shader has a color alone, so the intensity scales the color's bytes. */
	public var intensity = 1.;

	public function new()
		super();

	/** Returns rlights' type. */
	public function lightType():Int
		return LIGHT_POINT;

	/** Returns the color as rlights takes it, the intensity folded in. */
	public function shadedColor():Color
		return new Color(Std.int(color.r * intensity), Std.int(color.g * intensity), Std.int(color.b * intensity), 255);
}

/** Represents a point light (three.js's `PointLight`). */
class PointLight3D extends Light3D {
	public function new()
		super();
}

/** Represents a directional light (three.js's `DirectionalLight`), shining down the node's -z. */
class DirectionalLight3D extends Light3D {
	public function new()
		super();

	override public function lightType():Int
		return LIGHT_DIRECTIONAL;
}

/** Represents a camera's view as six planes, from the matrices raylib holds inside `BeginMode3D`. */
class Frustum3D {
	// Each plane's a, b, c, d: a point is inside where a*x + b*y + c*z + d >= 0.
	var planes:Array<Array<Float>> = [];

	/** Builds the planes from the view and the projection: the rows of their product (raylib's `Matrix` names its rows `m0, m4, m8, m12`
		and so on), as Gribb and Hartmann extract them. */
	public function new(view:Matrix, projection:Matrix) {
		var m = MatrixMultiply(view, projection);
		var rows = [
			[m.m0, m.m4, m.m8, m.m12],
			[m.m1, m.m5, m.m9, m.m13],
			[m.m2, m.m6, m.m10, m.m14],
			[m.m3, m.m7, m.m11, m.m15]
		];
		for (axis in 0...3) {
			planes.push([for (i in 0...4) rows[3][i] + rows[axis][i]]);
			planes.push([for (i in 0...4) rows[3][i] - rows[axis][i]]);
		}
	}

	/** Returns whether any of a box is inside, by each plane's nearest corner. */
	public function containsBox(box:BoundingBox):Bool {
		for (p in planes) {
			var x = p[0] >= 0 ? box.max.x : box.min.x;
			var y = p[1] >= 0 ? box.max.y : box.min.y;
			var z = p[2] >= 0 ? box.max.z : box.min.z;
			if (p[0] * x + p[1] * y + p[2] * z + p[3] < 0)
				return false;
		}
		return true;
	}
}

/** Represents what `Renderer3D.pick` found: the node and how far along the ray. */
class PickHit3D {
	public var node:Mesh3D;
	public var collision:RayCollision;

	public function new(node:Mesh3D, collision:RayCollision) {
		this.node = node;
		this.collision = collision;
	}
}

/** Provides the walk that draws a scene through a camera each frame, and picks in it (three.js's `WebGLRenderer.render(scene, camera)`). */
class Renderer3D {
	// The lit shaders seen this frame, each written the ambient, the view position and the lights once.
	var shaders:Array<Shader> = [];
	// Each lit shader's light slots, rlights' records, by the shader's id.
	var slots:Map<Int, Array<Light>> = [];
	// This frame's visible meshes, sorted, and its lights.
	var opaque:Array<Mesh3D> = [];
	var transparent:Array<Mesh3D> = [];
	var lights:Array<Light3D> = [];

	public function new() {}

	/** Draws the scene through the camera, inside `BeginDrawing`: world matrices, the camera, the culled and sorted meshes, the lights, then
		the opaque meshes front to back and the transparent ones back to front. */
	public function render(scene:Scene3D, camera:PerspectiveCamera3D):Void {
		scene.updateMatrixWorld(MatrixIdentity());
		camera.updateCamera();
		rlSetClipPlanes(camera.near, camera.far);
		BeginMode3D(camera.camera);
		// The matrices raylib built for the camera, read back inside the mode.
		var frustum = new Frustum3D(rlGetMatrixModelview(), rlGetMatrixProjection());
		opaque.resize(0);
		transparent.resize(0);
		lights.resize(0);
		shaders.resize(0);
		gather(scene, frustum);
		var eye = camera.camera.position;
		opaque.sort((a, b) -> compareDistance(a, b, eye, 1));
		transparent.sort((a, b) -> compareDistance(a, b, eye, -1));
		for (shader in shaders)
			writeLights(shader, scene, eye);
		for (mesh in opaque)
			DrawMesh(mesh.meshToDraw(), mesh.material.material, mesh.matrixWorld);
		rlDisableDepthMask();
		BeginBlendMode(BLEND_ALPHA);
		for (mesh in transparent)
			DrawMesh(mesh.meshToDraw(), mesh.material.material, mesh.matrixWorld);
		EndBlendMode();
		rlEnableDepthMask();
		EndMode3D();
	}

	// Walks the tree: each visible mesh inside the frustum into its list, each light into lights, each material's shader into shaders.
	function gather(node:Object3D, frustum:Frustum3D):Void {
		if (!node.visible)
			return;
		if (node is Mesh3D) {
			var mesh:Mesh3D = cast node;
			if (frustum.containsBox(mesh.computeWorldBounds())) {
				(mesh.material.transparent ? transparent : opaque).push(mesh);
				var shader = mesh.material.material.shader;
				if (shaders.indexOf(shader) < 0)
					shaders.push(shader);
			}
		} else if (node is Light3D)
			lights.push(cast node);
		for (child in node.children)
			gather(child, frustum);
	}

	static function compareDistance(a:Mesh3D, b:Mesh3D, eye:Vector3, sign:Int):Int {
		var da = Vector3Distance(eye, Vector3Transform(new Vector3(0, 0, 0), a.matrixWorld));
		var db = Vector3Distance(eye, Vector3Transform(new Vector3(0, 0, 0), b.matrixWorld));
		return da < db ? -sign : (da > db ? sign : 0);
	}

	/** Writes the frame's lights into a lit shader: the ambient, `viewPos`, and the nearest `MAX_LIGHTS` light nodes into its slots, the
		rest of the slots off.
		GAP 2: the shader has four slots (rlights' `MAX_LIGHTS`), so a scene of six lights lights with four, chosen each frame.
		GAP 3: `CreateLight` counts the program's lights, not the shader's, so the second lit shader would get no slot; the sketch fills
		rlights' `Light` records itself, by the names `CreateLight` looks up. */
	function writeLights(shader:Shader, scene:Scene3D, eye:Vector3):Void {
		SetShaderValue(shader, GetShaderLocation(shader, "ambient"), [scene.ambient.r / 255, scene.ambient.g / 255, scene.ambient.b / 255, 1.0],
			SHADER_UNIFORM_VEC4);
		SetShaderValue(shader, shader.locs[SHADER_LOC_VECTOR_VIEW], [eye.x, eye.y, eye.z], SHADER_UNIFORM_VEC3);
		if (!slots.exists(shader.id))
			slots.set(shader.id, [for (i in 0...MAX_LIGHTS) slotOf(shader, i)]);
		lights.sort((a, b) -> {
			var da = Vector3Distance(eye, Vector3Transform(new Vector3(0, 0, 0), a.matrixWorld));
			var db = Vector3Distance(eye, Vector3Transform(new Vector3(0, 0, 0), b.matrixWorld));
			return da < db ? -1 : (da > db ? 1 : 0);
		});
		var records = slots.get(shader.id);
		for (i in 0...MAX_LIGHTS) {
			var record = records[i];
			if (i < lights.length) {
				var light = lights[i];
				record.enabled = true;
				record.type = light.lightType();
				record.position = Vector3Transform(new Vector3(0, 0, 0), light.matrixWorld);
				record.target = Vector3Transform(new Vector3(0, 0, -1), light.matrixWorld);
				record.color = light.shadedColor();
			} else
				record.enabled = false;
			UpdateLightValues(shader, record);
		}
	}

	// rlights' CreateLight for one slot of one shader, written out because CreateLight's count is global.
	static function slotOf(shader:Shader, index:Int):Light {
		var light = new Light();
		light.enabledLoc = GetShaderLocation(shader, 'lights[$index].enabled');
		light.typeLoc = GetShaderLocation(shader, 'lights[$index].type');
		light.positionLoc = GetShaderLocation(shader, 'lights[$index].position');
		light.targetLoc = GetShaderLocation(shader, 'lights[$index].target');
		light.colorLoc = GetShaderLocation(shader, 'lights[$index].color');
		return light;
	}

	/** Returns the nearest mesh under a screen position, or null: raylib's ray from the camera, each mesh's world box first
		(`GetRayCollisionBox`), then its triangles (`GetRayCollisionMesh`) for the boxes hit. */
	public function pick(scene:Scene3D, camera:PerspectiveCamera3D, position:Vector2):Null<PickHit3D> {
		var ray = GetScreenToWorldRay(position, camera.camera);
		var best:Null<PickHit3D> = null;
		function walk(node:Object3D):Void {
			if (!node.visible)
				return;
			if (node is Mesh3D) {
				var mesh:Mesh3D = cast node;
				if (GetRayCollisionBox(ray, mesh.computeWorldBounds()).hit) {
					var target = node is SkinnedMesh3D ? (cast node : SkinnedMesh3D).meshToPick() : mesh.meshToDraw();
					var hit = GetRayCollisionMesh(ray, target, mesh.matrixWorld);
					if (hit.hit && (best == null || hit.distance < best.collision.distance))
						best = new PickHit3D(mesh, hit);
				}
			}
			for (child in node.children)
				walk(child);
		}
		walk(scene);
		return best;
	}
}

/** The scene the sketch draws: a skinned model, a shared cube under three materials, six lights, a camera, and a pick each frame. */
class Sketch3D {
	static function main():Void {
		InitWindow(800, 450, "sketch");
		var pbr = LoadPbrShader();
		var scene = new Scene3D();
		var camera = new PerspectiveCamera3D();
		camera.position = new Vector3(0, 3, 8);
		scene.add(camera);

		// The skinned model, each mesh a node with a material of its own, under a group turned by the program.
		var character = new Object3D();
		scene.add(character);
		var skeleton = new Skeleton3D();
		skeleton.load("assets/robot.glb", character, pbr);

		// One geometry, three materials, three nodes: one of them transparent.
		var cube = new Geometry3D(GenMeshCube(1, 1, 1));
		var colors = [RED, GREEN, BLUE];
		for (i in 0...3) {
			var material = new Material3D(LoadMaterialDefault());
			material.material.shader = pbr;
			material.material.maps[MATERIAL_MAP_ALBEDO].color = colors[i];
			material.transparent = i == 2;
			var node = new Mesh3D(cube, material);
			node.position = new Vector3(i * 2 - 2, 0.5, 0);
			scene.add(node);
		}

		// Six lights as nodes, one directional. A frame writes the four nearest into each lit shader (GAP 2).
		for (i in 0...6) {
			var light:Light3D = i == 0 ? new DirectionalLight3D() : new PointLight3D();
			light.position = new Vector3(Math.cos(i) * 4, 3, Math.sin(i) * 4);
			light.color = i == 0 ? WHITE : YELLOW;
			scene.add(light);
		}

		var renderer = new Renderer3D();
		var frame = 0.;
		while (!WindowShouldClose()) {
			frame += GetFrameTime() * 60;
			skeleton.pose(0, frame);
			character.rotation = QuaternionFromEuler(0, GetTime(), 0);
			var hit = renderer.pick(scene, camera, GetMousePosition());
			BeginDrawing();
			ClearBackground(RAYWHITE);
			renderer.render(scene, camera);
			if (hit != null)
				DrawText("hit", 10, 10, 20, DARKGRAY);
			EndDrawing();
		}
		CloseWindow();
	}
}
