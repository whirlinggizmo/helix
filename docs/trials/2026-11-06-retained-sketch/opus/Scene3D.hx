import helix.raylib.Raylib.*;
import helix.raylib.Raymath.*;
import helix.raylib.Rlgl.*;
import helix.raylib.extras.Lights.*;
import helix.raylib.extras.Models.*;
import helix.raylib.extras.Textures.*;
import helix.raylib.BoundingBox;
import helix.raylib.Camera3D;
import helix.raylib.Color;
import helix.raylib.Light;
import helix.raylib.Material;
import helix.raylib.Matrix;
import helix.raylib.Mesh;
import helix.raylib.Model;
import helix.raylib.ModelAnimation;
import helix.raylib.Quaternion;
import helix.raylib.Ray;
import helix.raylib.RayCollision;
import helix.raylib.Shader;
import helix.raylib.Texture2D;
import helix.raylib.Vector2;
import helix.raylib.Vector3;

/** A sketch, not an engine: three.js's shape (`Scene`, `Object3D`, `Mesh` of a geometry and a material, lights as nodes,
	`renderer.render(scene, camera)`) issuing raylib's calls alone. Each `GAP n` comment marks a line where raylib's API had no door;
	sketch.md lists them by number. */
class Scene3D extends Object3D {
	/** Gets or sets the ambient light's color, as three.js's `AmbientLight` would give it. */
	public var ambient = new Color(40, 40, 50, 255);

	/** Creates an empty scene. */
	public function new() {
		super();
	}

	/** The program: a skinned glTF character, a row of crates sharing one geometry under three materials, six lights, a camera, and a
		pick under the mouse. */
	static function main():Void {
		InitWindow(800, 450, "retained sketch");
		var scene = new Scene3D();
		var camera = new PerspectiveCamera3D(45);
		camera.setPosition(0, 3, 8);
		camera.lookAt(new Vector3(0, 1, 0));
		scene.add(camera);
		var renderer = new Renderer3D();

		// Static meshes: one raylib Mesh, three Materials, each draw choosing its own through DrawMesh.
		var box = new Geometry3D(GenMeshCube(1, 1, 1));
		var colors = [RED, GREEN, new Color(80, 160, 255, 128)];
		for (i in 0...6) {
			var material = new Material3D(renderer.pbr);
			material.color = colors[i % 3];
			material.transparent = colors[i % 3].a < 255;
			var crate = new Mesh3D(box, material);
			crate.setPosition(-5 + i * 2, 0.5, -2);
			scene.add(crate);
		}

		// Six lights as nodes, in a group that turns.
		var rig = new Object3D();
		scene.add(rig);
		for (i in 0...6) {
			var light = i == 0 ? (new DirectionalLight3D() : Light3D) : new PointLight3D(6);
			light.color = i == 0 ? WHITE : [YELLOW, ORANGE, SKYBLUE, PINK, LIME][i - 1];
			light.setPosition(Math.cos(i) * 4, 2.5, Math.sin(i) * 4);
			rig.add(light);
		}

		// The character: a glTF loaded as a group of skinned meshes, each with a material of its own.
		var character:Null<GltfScene3D> = null;
		GltfScene3D.load("assets/robot.glb", renderer.pbr, loaded -> {
			character = loaded;
			loaded.setPosition(0, 0, 0);
			scene.add(loaded);
		});

		// A glow among the transparent crates, sorted with them.
		LoadTextureAsync("assets/glow.png", texture -> {
			var glow = new Sprite3D(texture);
			glow.setPosition(0, 2, -2);
			scene.add(glow);
		});

		var raycaster = new Raycaster3D();
		var layer = Layer2D.demo();
		while (!WindowShouldClose()) {
			var dt = GetFrameTime();
			rig.rotation = QuaternionMultiply(rig.rotation, QuaternionFromAxisAngle(new Vector3(0, 1, 0), dt * 0.5));
			if (character != null)
				character.mixer.update(dt);
			if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT)) {
				raycaster.setFromCamera(GetMousePosition(), camera);
				var hits = raycaster.intersectObject(scene);
				if (hits.length > 0)
					TraceLog(LOG_INFO, "picked " + hits[0].object.name);
			}
			BeginDrawing();
			ClearBackground(RAYWHITE);
			renderer.render(scene, camera);
			layer.render();
			EndDrawing();
		}
		CloseWindow();
	}
}

/** Represents a node: a transform in a tree, as three.js's `Object3D`. */
class Object3D {
	/** Gets or sets the node's name. */
	public var name = "";

	/** Gets the node's parent, null at the top. */
	public var parent(default, null):Null<Object3D> = null;

	/** Gets the node's children, drawn and walked in order. */
	public var children(default, null):Array<Object3D> = [];

	/** Gets or sets the position, relative to the parent. */
	public var position = new Vector3(0, 0, 0);

	/** Gets or sets the rotation, relative to the parent. */
	public var rotation:Quaternion = QuaternionIdentity();

	/** Gets or sets the scale on each axis. */
	public var scale = new Vector3(1, 1, 1);

	/** Gets or sets a value indicating whether the node and its subtree are drawn. */
	public var visible = true;

	/** Gets the world matrix the last `updateWorld` computed. */
	public var world(default, null):Matrix = MatrixIdentity();

	/** Creates a node at the origin. */
	public function new() {}

	/** Sets the position.

		@param x  The x.
		@param y  The y.
		@param z  The z. */
	public function setPosition(x:Float, y:Float, z:Float):Void {
		position = new Vector3(x, y, z);
	}

	/** Adds a child, last.

		@param child  The child. */
	public function add(child:Object3D):Void {
		if (child.parent != null)
			child.parent.children.remove(child);
		child.parent = this;
		children.push(child);
	}

	/** Turns the node to face a point, as three.js's `lookAt`, its -z toward the point.

		@param point  The point, in the parent's space. */
	public function lookAt(point:Vector3):Void {
		// raylib's MatrixLookAt is a view matrix: the node's own matrix is its inverse.
		rotation = QuaternionFromMatrix(MatrixInvert(MatrixLookAt(position, point, new Vector3(0, 1, 0))));
	}

	/** Computes the world matrices of the node and its subtree, raylib's order: scale, then rotation, then translation, then the
		parent's.

		@param parentWorld  The parent's world matrix. */
	public function updateWorld(parentWorld:Matrix):Void {
		var local = MatrixMultiply(MatrixMultiply(MatrixScale(scale.x, scale.y, scale.z), QuaternionToMatrix(rotation)),
			MatrixTranslate(position.x, position.y, position.z));
		world = MatrixMultiply(local, parentWorld);
		for (c in children)
			c.updateWorld(world);
	}

	/** Gets the world position, the world matrix's translation. */
	public var worldPosition(get, never):Vector3;

	function get_worldPosition():Vector3
		return new Vector3(world.m12, world.m13, world.m14);
}

/** Represents a geometry: a raylib `Mesh` shared by any number of `Mesh3D` nodes. */
class Geometry3D {
	/** Gets the raylib mesh, the GPU handle. */
	public var mesh(default, null):Mesh;

	/** Gets the mesh's bounds in its own space, computed once. */
	public var bounds(default, null):BoundingBox;

	/** Creates a geometry of a mesh.

		@param mesh  The mesh, uploaded. */
	public function new(mesh:Mesh) {
		this.mesh = mesh;
		// GetMeshBoundingBox walks every vertex, so the engine keeps the box.
		bounds = GetMeshBoundingBox(mesh);
	}
}

/** Represents a material: a raylib `Material` and what three.js's material says that raylib's doesn't. */
class Material3D {
	/** Gets the raylib material, drawn through `DrawMesh`. */
	public var material(default, null):Material;

	/** Gets or sets a value indicating whether it is drawn after the opaque, back to front, without writing depth. */
	public var transparent = false;

	/** Gets or sets a value indicating whether both sides are drawn. */
	public var doubleSided = false;

	/** Creates a material through a shader.

		@param shader  The shader.
		@param from  Optional. The raylib material to wear, a model's; a default one when omitted. */
	public function new(shader:Shader, ?from:Material) {
		material = from != null ? from : LoadMaterialDefault();
		material.shader = shader;
	}

	/** Gets or sets the base color, the albedo map's. */
	public var color(get, set):Color;

	function get_color():Color
		return material.maps[MATERIAL_MAP_ALBEDO].color;

	function set_color(c:Color):Color
		return material.maps[MATERIAL_MAP_ALBEDO].color = c;
}

/** Represents a drawn node: a geometry under a material, as three.js's `Mesh`. */
class Mesh3D extends Object3D {
	/** Gets or sets the geometry. */
	public var geometry:Geometry3D;

	/** Gets or sets the material. */
	public var material:Material3D;

	/** Creates a mesh node.

		@param geometry  The geometry.
		@param material  The material. */
	public function new(geometry:Geometry3D, material:Material3D) {
		super();
		this.geometry = geometry;
		this.material = material;
	}

	/** Returns the node's bounds in the world, its geometry's box through its world matrix.

		@return  The box. */
	public function computeWorldBounds():BoundingBox {
		return transformBox(geometry.bounds, world);
	}

	static function transformBox(b:BoundingBox, m:Matrix):BoundingBox {
		var lo = new Vector3(1e30, 1e30, 1e30), hi = new Vector3(-1e30, -1e30, -1e30);
		for (i in 0...8) {
			var p = Vector3Transform(new Vector3(i & 1 == 0 ? b.min.x : b.max.x, i & 2 == 0 ? b.min.y : b.max.y, i & 4 == 0 ? b.min.z : b.max.z), m);
			lo = Vector3Min(lo, p);
			hi = Vector3Max(hi, p);
		}
		return new BoundingBox(lo, hi);
	}
}

/** Represents a texture facing the camera among the meshes, as three.js's `Sprite`. */
class Sprite3D extends Object3D {
	/** Gets or sets the texture. */
	public var texture:Texture2D;

	/** Creates a sprite.

		@param texture  The texture. */
	public function new(texture:Texture2D) {
		super();
		this.texture = texture;
	}
}

/** Represents a skinned mesh: a mesh of a glTF model posed by its skeleton. */
class SkinnedMesh3D extends Mesh3D {
	/** Gets the skeleton, the raylib `Model` its meshes are posed through. */
	public var skeleton(default, null):Skeleton3D;

	/** Creates a skinned mesh.

		@param geometry  The geometry.
		@param material  The material.
		@param skeleton  The skeleton. */
	public function new(geometry:Geometry3D, material:Material3D, skeleton:Skeleton3D) {
		super(geometry, material);
		this.skeleton = skeleton;
	}

	override public function computeWorldBounds():BoundingBox {
		// A cost, not a gap: the box is the whole model's, each skinned vertex moved on the CPU each call, so the mixer keeps it once a frame.
		return Mesh3D.transformBox(skeleton.posedBounds, world);
	}
}

/** Represents a skeleton: the raylib `Model` a glTF's skinned meshes share, since `UpdateModelAnimation` poses a model. */
class Skeleton3D {
	/** Gets the model. */
	public var model(default, null):Model;

	/** Gets or sets the model's bounds as last posed, in its own space. */
	public var posedBounds:BoundingBox;

	/** Creates a skeleton of a model.

		@param model  The model. */
	public function new(model:Model) {
		this.model = model;
		posedBounds = GetModelBoundingBox(model);
	}
}

/** Represents a glTF's scene: a group of its meshes, as three.js's `GLTFLoader` gives one. */
class GltfScene3D extends Object3D {
	/** Gets the animation mixer, posing the skeleton. */
	public var mixer(default, null):AnimationMixer3D;

	/** Gets the skeleton. */
	public var skeleton(default, null):Skeleton3D;

	function new(model:Model, shader:Shader, animations:Array<ModelAnimation>) {
		super();
		skeleton = new Skeleton3D(model);
		mixer = new AnimationMixer3D(skeleton, animations);
		// GAP 5: the file's node tree is gone. Every mesh's node transform is in its vertices and a Mesh has no name, so the children
		// here are flat, unnamed, and `getObjectByName("door")` has nothing to find.
		for (i in 0...model.meshCount) {
			// Each mesh its own material, the model's, as LoadModelAsync made it.
			var material = new Material3D(shader, model.materials[model.meshMaterial[i]]);
			// GAP 4: the glTF's alphaMode and doubleSided aren't read into raylib's Material, so a BLEND material can't be told from an
			// OPAQUE one and a one-sided leaf from a two-sided one. The program has to say so by hand.
			material.transparent = false;
			var node = new SkinnedMesh3D(new Geometry3D(model.meshes[i]), material, skeleton);
			node.name = 'mesh $i';
			add(node);
		}
	}

	/** Asynchronously loads a glTF file as a scene and its animations.

		@param fileName  The file.
		@param shader  The shader its materials draw through.
		@param loaded  Receives the scene. */
	public static function load(fileName:String, shader:Shader, loaded:GltfScene3D->Void):Void {
		// GAP 7: `fileName` isn't a constant here, so LoadModelAsync's macro can't choose the reader and this links the OBJ reader too.
		LoadModelAsync(fileName, model -> LoadModelAnimationsAsync(fileName, anims -> loaded(new GltfScene3D(model, shader, anims))));
	}

	/** Loads the file again after it changed, keeping the nodes, as a watching asset system would ask.

		@param fileName  The file. */
	public function reload(fileName:String):Void {
		// GAP 1: a load of a file while a load of it lives shares that load's buffers and textures, so this answers with the old model.
		// No call reads the file anew, and none puts new data behind the Mesh, Material and Texture2D records the nodes hold.
		LoadModelAsync(fileName, model -> {});
	}
}

/** Represents an animation player for a skeleton, as three.js's `AnimationMixer`. */
class AnimationMixer3D {
	/** Gets the time played, in seconds. */
	public var time(default, null) = 0.0;

	/** Gets or sets the animation played. */
	public var clipIndex = 0;

	final skeleton:Skeleton3D;
	final clips:Array<ModelAnimation>;

	/** Creates a mixer.

		@param skeleton  The skeleton.
		@param clips  The animations. */
	public function new(skeleton:Skeleton3D, clips:Array<ModelAnimation>) {
		this.skeleton = skeleton;
		this.clips = clips;
	}

	/** Advances the time and poses the skeleton.

		@param seconds  The time passed. */
	public function update(seconds:Float):Void {
		time += seconds;
		if (clips.length == 0)
			return;
		// LoadModelAnimationsAsync samples 60 times a second.
		UpdateModelAnimation(skeleton.model, clips[clipIndex], time * 60);
		skeleton.posedBounds = GetModelBoundingBoxPosed(skeleton.model);
	}
}

/** Represents a light as a node, as three.js's lights. */
class Light3D extends Object3D {
	/** Gets or sets the color. */
	public var color = WHITE;

	/** Gets or sets the intensity, a multiplier of the color. */
	public var intensity = 1.0;

	/** Creates a light. */
	public function new() {
		super();
	}
}

/** Represents a light from far off along the node's -z, as three.js's `DirectionalLight`. */
class DirectionalLight3D extends Light3D {}

/** Represents a light from the node's position every way, as three.js's `PointLight`. */
class PointLight3D extends Light3D {
	/** Gets or sets the distance past which nothing is lit, 0 for none. */
	public var distance:Float;

	/** Creates a point light.

		@param distance  The distance past which nothing is lit. */
	public function new(distance:Float = 0) {
		super();
		this.distance = distance;
	}
}

/** Represents a perspective camera as a node, as three.js's `PerspectiveCamera`. */
class PerspectiveCamera3D extends Object3D {
	/** Gets or sets the vertical field of view, in degrees, as raylib's `fovy`. */
	public var fov:Float;

	/** Creates a camera.

		@param fov  The vertical field of view, in degrees. */
	public function new(fov:Float) {
		super();
		this.fov = fov;
	}

	/** Returns the raylib camera the node is: its world position, looking along its world -z, up its world y.

		@return  The camera. */
	public function toRaylib():Camera3D {
		var p = worldPosition;
		var forward = new Vector3(-world.m8, -world.m9, -world.m10);
		var up = new Vector3(world.m4, world.m5, world.m6);
		return new Camera3D(p, Vector3Add(p, forward), up, fov, CAMERA_PERSPECTIVE);
	}
}

/** Represents a draw the renderer gathered. */
private class Draw3D {
	public var node:Object3D;
	public var depth:Float;

	public function new(node:Object3D, depth:Float) {
		this.node = node;
		this.depth = depth;
	}
}

/** Renders a scene through a camera, as three.js's `WebGLRenderer.render`, with raylib's calls. */
class Renderer3D {
	/** Gets the PBR shader every material here draws through. */
	public var pbr(default, null):Shader;

	// The shader's four light slots, made once.
	final slots:Array<Light> = [];

	/** Creates a renderer. */
	public function new() {
		pbr = LoadPbrShader();
		// GAP 2: a lit shader holds MAX_LIGHTS (4), and CreateLight counts across the program, so a second lit shader's lights come back off.
		// The four slots are made here and refilled per draw (`chooseLights`).
		for (i in 0...MAX_LIGHTS)
			slots.push(CreateLight(LIGHT_POINT, Vector3Zero(), Vector3Zero(), BLACK, pbr));
	}

	/** Draws a scene through a camera.

		@param scene  The scene.
		@param camera  The camera. */
	public function render(scene:Scene3D, camera:PerspectiveCamera3D):Void {
		scene.updateWorld(MatrixIdentity());
		var rc = camera.toRaylib();
		SetShaderValue(pbr, pbr.locs[SHADER_LOC_VECTOR_VIEW], [rc.position.x, rc.position.y, rc.position.z], SHADER_UNIFORM_VEC3);
		SetShaderValue(pbr, GetShaderLocation(pbr, "ambient"), [scene.ambient.r / 255, scene.ambient.g / 255, scene.ambient.b / 255, 1.0],
			SHADER_UNIFORM_VEC4);

		BeginMode3D(rc);
		// The camera's matrices, read back from rlgl as BeginMode3D set them.
		var viewProjection = MatrixMultiply(rlGetMatrixModelview(), rlGetMatrixProjection());
		var planes = frustumPlanes(viewProjection);

		// Gather: the lights and the drawn nodes the camera sees.
		var lights:Array<Light3D> = [];
		var opaque:Array<Draw3D> = [], transparent:Array<Draw3D> = [];
		gather(scene, planes, rc.position, lights, opaque, transparent);
		opaque.sort((a, b) -> a.depth < b.depth ? -1 : a.depth > b.depth ? 1 : 0);
		transparent.sort((a, b) -> a.depth > b.depth ? -1 : a.depth < b.depth ? 1 : 0);

		for (d in opaque)
			drawOne(cast d.node, lights);
		// Transparent: depth tested, not written, blended, back to front.
		rlDisableDepthMask();
		BeginBlendMode(BLEND_ALPHA);
		for (d in transparent)
			if (Std.isOfType(d.node, Sprite3D)) {
				var sprite:Sprite3D = cast d.node;
				DrawBillboard(rc, sprite.texture, sprite.worldPosition, sprite.scale.y, WHITE);
				// A billboard waits in rlgl's batch, and a mesh draws ahead of it. This draws it now, so the sort holds (raylib's own door).
				rlDrawRenderBatchActive();
			} else
				drawOne(cast d.node, lights);
		EndBlendMode();
		rlEnableDepthMask();
		EndMode3D();
	}

	function drawOne(node:Mesh3D, lights:Array<Light3D>):Void {
		// Each draw keeps the shader's values as they are at the call, so the four slots can be refilled per draw with the lights
		// nearest the node: six lights in the scene, four on any one mesh (GAP 2 is the mesh the other two also reach).
		chooseLights(node, lights);
		if (node.material.doubleSided)
			rlDisableBackfaceCulling();
		DrawMesh(node.geometry.mesh, node.material.material, node.world);
		if (node.material.doubleSided)
			rlEnableBackfaceCulling();
	}

	function chooseLights(node:Mesh3D, lights:Array<Light3D>):Void {
		var at = node.worldPosition;
		lights.sort((a, b) -> Vector3DistanceSqr(a.worldPosition, at) < Vector3DistanceSqr(b.worldPosition, at) ? -1 : 1);
		for (i in 0...MAX_LIGHTS) {
			var slot = slots[i];
			slot.enabled = i < lights.length;
			if (slot.enabled) {
				var l = lights[i];
				slot.type = Std.isOfType(l, DirectionalLight3D) ? LIGHT_DIRECTIONAL : LIGHT_POINT;
				slot.position = l.worldPosition;
				slot.target = Vector3Transform(new Vector3(0, 0, -1), l.world);
				// GAP 3: rlights' light is a color alone. A point light's distance, its falloff and a spot light have no uniform, and
				// the intensity can only be folded into the color's bytes, which stop at 255.
				var k = l.intensity;
				slot.color = new Color(Std.int(Math.min(l.color.r * k, 255)), Std.int(Math.min(l.color.g * k, 255)), Std.int(Math.min(l.color.b * k, 255)), 255);
			}
			UpdateLightValues(pbr, slot);
		}
	}

	function gather(node:Object3D, planes:Array<Float>, eye:Vector3, lights:Array<Light3D>, opaque:Array<Draw3D>, transparent:Array<Draw3D>):Void {
		if (!node.visible)
			return;
		if (Std.isOfType(node, Light3D))
			lights.push(cast node);
		if (Std.isOfType(node, Sprite3D))
			transparent.push(new Draw3D(node, Vector3DistanceSqr(eye, node.worldPosition)));
		if (Std.isOfType(node, Mesh3D)) {
			var mesh:Mesh3D = cast node;
			var box = mesh.computeWorldBounds();
			if (boxInFrustum(box, planes)) {
				var depth = Vector3DistanceSqr(eye, Vector3Lerp(box.min, box.max, 0.5));
				(mesh.material.transparent ? transparent : opaque).push(new Draw3D(mesh, depth));
			}
		}
		for (c in node.children)
			gather(c, planes, eye, lights, opaque, transparent);
	}

	// Culling is the engine's own arithmetic: raylib has no frustum, and helix-geometry's Frustum3D would do this from a Matrix3D.
	static function frustumPlanes(m:Matrix):Array<Float> {
		var r0 = [m.m0, m.m4, m.m8, m.m12], r1 = [m.m1, m.m5, m.m9, m.m13], r2 = [m.m2, m.m6, m.m10, m.m14], r3 = [m.m3, m.m7, m.m11, m.m15];
		var out = [];
		for (sign in [1.0, -1.0])
			for (r in [r0, r1, r2])
				for (k in 0...4)
					out.push(r3[k] + sign * r[k]);
		return out;
	}

	static function boxInFrustum(b:BoundingBox, planes:Array<Float>):Bool {
		for (p in 0...6) {
			var a = planes[p * 4], c = planes[p * 4 + 1], d = planes[p * 4 + 2], w = planes[p * 4 + 3];
			var x = a >= 0 ? b.max.x : b.min.x, y = c >= 0 ? b.max.y : b.min.y, z = d >= 0 ? b.max.z : b.min.z;
			if (a * x + c * y + d * z + w < 0)
				return false;
		}
		return true;
	}
}

/** Represents a hit, as three.js's `Raycaster` returns one. */
class Intersection3D {
	/** Gets the distance along the ray. */
	public var distance(default, null):Float;

	/** Gets the node hit. */
	public var object(default, null):Mesh3D;

	/** Creates a hit.

		@param distance  The distance.
		@param object  The node. */
	public function new(distance:Float, object:Mesh3D) {
		this.distance = distance;
		this.object = object;
	}
}

/** Finds the nodes under a point on the screen, as three.js's `Raycaster`. */
class Raycaster3D {
	/** Gets the ray. */
	public var ray(default, null) = new Ray();

	/** Creates a raycaster. */
	public function new() {}

	/** Sets the ray from a camera through a point on the screen.

		@param position  The point, in screen pixels.
		@param camera  The camera. */
	public function setFromCamera(position:Vector2, camera:PerspectiveCamera3D):Void {
		ray = GetScreenToWorldRay(position, camera.toRaylib());
	}

	/** Returns the nodes the ray meets in a subtree, nearest first.

		@param root  The subtree.
		@return  The hits. */
	public function intersectObject(root:Object3D):Array<Intersection3D> {
		var hits = [];
		collect(root, hits);
		hits.sort((a, b) -> a.distance < b.distance ? -1 : 1);
		return hits;
	}

	function collect(node:Object3D, hits:Array<Intersection3D>):Void {
		if (Std.isOfType(node, Mesh3D)) {
			var mesh:Mesh3D = cast node;
			// The box first, then the triangles: raylib's own two tests.
			if (GetRayCollisionBox(ray, mesh.computeWorldBounds()).hit) {
				var hit = GetRayCollisionMesh(ray, triangles(mesh), mesh.world);
				if (hit.hit)
					hits.push(new Intersection3D(hit.distance, mesh));
			}
		}
		for (c in node.children)
			collect(c, hits);
	}

	function triangles(node:Mesh3D):Mesh {
		if (!Std.isOfType(node, SkinnedMesh3D))
			return node.geometry.mesh;
		// GAP 6: GetRayCollisionMesh reads `vertices`, the bind pose, so a posed character is picked where it stood when skinned. The
		// posed positions are `animVertices`, worked out on the CPU when read, and only a Mesh of their own carries them to the test.
		var src = node.geometry.mesh;
		var posed = new Mesh();
		posed.vertexCount = src.vertexCount;
		posed.triangleCount = src.triangleCount;
		posed.vertices = src.animVertices;
		posed.indices = src.indices;
		return posed;
	}
}
