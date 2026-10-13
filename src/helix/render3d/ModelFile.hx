package helix.render3d;

import helix.graphics.Sampling;
import helix.render2d.Texture2D;
import helix.render3d.Gltf.field;
import helix.render3d.Light.LightKind;

/** A model file read into what a Stage3D draws: its meshes (a part a glTF primitive), its materials and its node tree, from a glTF 2.0 file
	(Models loads them). instantiate() makes a fresh node tree each call, sharing the file's meshes and materials, so any number of copies draw
	together; each copy has lights of its own. Made by Models; read, never changed after.

	Read: triangle primitives' positions, normals (worked out when missing), first texture coordinates and tangents (worked out when missing);
	metallic-roughness materials' base color and texture, metallic and roughness factors, normal map and its scale, emissive color (with
	KHR_materials_emissive_strength) and alphaMode BLEND; nodes' names, translation, rotation and scale or matrix, and children; the default
	scene's roots; textures' samplers (filter and wrap); KHR_lights_punctual's directional, point and spot lights. Not read yet (warned once a file): skins and animations (a skinned
	mesh draws in its bind pose), morph targets, metallic-roughness, occlusion and emissive textures, alphaMode MASK, double-sided materials,
	texture transforms, a second texture coordinate set, and files other than GLB. */
class ModelFile {
	var gltf:Gltf;
	var parts:Array<Array<{mesh:Mesh, material:Material}>> = [];
	var materials:Array<Material> = [];
	var lights:Array<Dynamic>;
	var roots:Array<Int> = [];
	var warnings:Array<String> = [];

	/** The file read, its images not yet decoded (Models decodes them and sets them on its materials). Throws, saying why, for a file it can't
		read. */
	@:allow(helix.render3d.Models)
	function new(gltf:Gltf) {
		this.gltf = gltf;
		for (m in gltf.list("materials"))
			materials.push(material(m));
		var fallback = new Material();
		for (m in gltf.list("meshes")) {
			var list = [];
			var primitives:Array<Dynamic> = field(m, "primitives");
			for (p in primitives) {
				var mode:Null<Int> = field(p, "mode");
				if (mode != null && mode != 4) {
					warn('a primitive of mode $mode (not triangles) is skipped');
					continue;
				}
				if (field(p, "targets") != null)
					warn("morph targets are ignored");
				var index:Null<Int> = field(p, "material");
				list.push({mesh: mesh(p), material: index == null ? fallback : materials[index]});
			}
			parts.push(list);
		}
		if (gltf.list("skins").length > 0 || gltf.list("animations").length > 0)
			warn("skins and animations are ignored: a skinned mesh draws in its bind pose");
		lights = field(field(field(gltf.document, "extensions"), "KHR_lights_punctual"), "lights");
		if (lights == null)
			lights = [];
		var scenes = gltf.list("scenes");
		var scene:Null<Int> = field(gltf.document, "scene");
		if (scenes.length > 0) {
			var nodes:Array<Int> = field(scenes[scene == null ? 0 : scene], "nodes");
			roots = nodes == null ? [] : nodes;
		} else {
			// No scene: every node that is no node's child.
			var children = new Map<Int, Bool>();
			for (n in gltf.list("nodes")) {
				var list:Array<Int> = field(n, "children");
				if (list != null)
					for (c in list)
						children[c] = true;
			}
			roots = [for (i in 0...gltf.list("nodes").length) if (!children.exists(i)) i];
		}
	}

	/** What the file used that isn't read yet, each once. */
	public function getWarnings():Array<String>
		return warnings.copy();

	/** Its materials, in the file's order: change one and every copy's parts with it change. */
	public function getMaterials():Array<Material>
		return materials.copy();

	/** A new node tree of the file's default scene, under a group named name: its nodes' names, transforms and children, models sharing the
		file's meshes and materials, and lights of their own. */
	public function instantiate(name = ""):Node {
		var root = Node.group();
		root.setName(name);
		for (r in roots)
			root.add(node(r));
		return root;
	}

	function warn(message:String):Void
		if (warnings.indexOf(message) < 0)
			warnings.push(message);

	// 0..1 linear, as glTF's factors are, to the sRGB-encoded 0..255 of the convention's colors.
	static function srgb(c:Float):Int {
		c = c < 0 ? 0 : c > 1 ? 1 : c;
		return Math.round((c <= .0031308 ? c * 12.92 : 1.055 * Math.pow(c, 1 / 2.4) - .055) * 255);
	}

	static function color(rgba:Array<Float>):Int
		return srgb(rgba[0]) << 24 | srgb(rgba[1]) << 16 | srgb(rgba[2]) << 8 | Math.round((rgba.length > 3 ? rgba[3] : 1) * 255);

	function material(m:Dynamic):Material {
		var material = new Material(),
			pbr:Dynamic = field(m, "pbrMetallicRoughness");
		var base:Array<Float> = field(pbr, "baseColorFactor");
		material.setBaseColor(base == null ? 0xffffffff : color(base));
		var metallic:Null<Float> = field(pbr, "metallicFactor"),
			roughness:Null<Float> = field(pbr, "roughnessFactor");
		material.setMetallic(metallic == null ? 1 : metallic);
		material.setRoughness(roughness == null ? 1 : roughness);
		var emissive:Array<Float> = field(m, "emissiveFactor");
		if (emissive != null) {
			var strength:Null<Float> = field(field(field(m, "extensions"), "KHR_materials_emissive_strength"), "emissiveStrength");
			material.setEmissive(color(emissive), strength == null ? 1 : strength);
		}
		var normal:Dynamic = field(m, "normalTexture");
		if (normal != null) {
			var scale:Null<Float> = field(normal, "scale");
			material.setNormalScale(scale == null ? 1 : scale);
		}
		if (field(m, "alphaMode") == "BLEND")
			material.setBlended(true);
		else if (field(m, "alphaMode") == "MASK")
			warn("alphaMode MASK draws opaque");
		if (field(m, "doubleSided") == true)
			warn("double-sided materials draw one-sided");
		if (field(pbr, "metallicRoughnessTexture") != null || field(m, "occlusionTexture") != null || field(m, "emissiveTexture") != null)
			warn("metallic-roughness, occlusion and emissive textures are ignored");
		return material;
	}

	// glTF's wrap modes (WebGL's numbers) as a Sampling's; repeat when unset.
	static function wrap(mode:Null<Int>):Wrap
		return mode == 33071 ? Clamp : mode == 33648 ? Mirror : Repeat;

	/** The images materials use: for each, the buffer view holding its file, how its texture samples (its sampler's filter, linear unless
		its magnification filter is nearest, and wrap), and how to set it once decoded. */
	@:allow(helix.render3d.Models)
	function images():Array<{view:Int, sampling:Sampling, set:Texture2D->Void}> {
		var out = [], textures = gltf.list("textures"), images = gltf.list("images"), samplers = gltf.list("samplers");
		function image(info:Dynamic, set:Texture2D->Void):Void {
			if (info == null)
				return;
			if (field(info, "texCoord") != null && field(info, "texCoord") != 0)
				warn("a second texture coordinate set is read as the first");
			var t = textures[field(info, "index")],
				source:Null<Int> = field(t, "source");
			if (source == null || field(images[source], "bufferView") == null) {
				warn("images outside the GLB's buffer are skipped");
				return;
			}
			var index:Null<Int> = field(t, "sampler"),
				sampler:Dynamic = index == null ? null : samplers[index];
			var mag:Null<Int> = field(sampler, "magFilter");
			out.push({
				view: field(images[source], "bufferView"),
				sampling: new Sampling(mag != 9728, wrap(field(sampler, "wrapS")), wrap(field(sampler, "wrapT"))),
				set: set
			});
		}
		var list = gltf.list("materials");
		for (i in 0...list.length) {
			var target = materials[i];
			image(field(field(list[i], "pbrMetallicRoughness"), "baseColorTexture"), t -> target.setTexture(t));
			image(field(list[i], "normalTexture"), t -> target.setNormalTexture(t));
		}
		return out;
	}

	@:allow(helix.render3d.Models)
	function gltfFile():Gltf
		return gltf;

	function mesh(p:Dynamic):Mesh {
		var attributes:Dynamic = field(p, "attributes");
		var position:Null<Int> = field(attributes, "POSITION");
		if (position == null)
			throw "A primitive has no POSITION";
		var normal:Null<Int> = field(attributes, "NORMAL"),
			uv:Null<Int> = field(attributes, "TEXCOORD_0"),
			tangent:Null<Int> = field(attributes, "TANGENT"),
			indices:Null<Int> = field(p, "indices");
		return Mesh.fromArrays(gltf.floats(position), normal == null ? null : gltf.floats(normal), uv == null ? null : gltf.floats(uv),
			tangent == null ? null : gltf.floats(tangent), indices == null ? null : gltf.ints(indices));
	}

	function light(index:Int):Light {
		var l = lights[index], type:String = field(l, "type");
		var light = new Light(type == "spot" ? Spot : type == "point" ? Point : Directional);
		var c:Array<Float> = field(l, "color");
		light.setColor(c == null ? 0xffffffff : color(c));
		var intensity:Null<Float> = field(l, "intensity"),
			range:Null<Float> = field(l, "range");
		light.setIntensity(intensity == null ? 1 : intensity);
		light.setRange(range == null ? 0 : range);
		var spot:Dynamic = field(l, "spot");
		if (spot != null) {
			var inner:Null<Float> = field(spot, "innerConeAngle"),
				outer:Null<Float> = field(spot, "outerConeAngle");
			light.setCone(inner == null ? 0 : inner, outer == null ? Math.PI / 4 : outer);
		}
		return light;
	}

	function node(index:Int):Node {
		var n = gltf.list("nodes")[index],
			meshIndex:Null<Int> = field(n, "mesh");
		var lightIndex:Null<Int> = field(field(field(n, "extensions"), "KHR_lights_punctual"), "light");
		var list = meshIndex == null ? [] : parts[meshIndex];
		// One part and nothing else: the node is the model; otherwise a group holding its parts and its light.
		var node = list.length == 1
			&& lightIndex == null ? Node.model(list[0].mesh,
				list[0].material) : lightIndex != null && list.length == 0 ? Node.light(light(lightIndex)) : Node.group();
		if (node.getKind() == Group) {
			for (part in list)
				node.add(Node.model(part.mesh, part.material));
			if (lightIndex != null)
				node.add(Node.light(light(lightIndex)));
		}
		var name:String = field(n, "name");
		node.setName(name == null ? "" : name);
		var matrix:Array<Float> = field(n, "matrix");
		if (matrix != null)
			node.setMatrix(matrix);
		else {
			var t:Array<Float> = field(n, "translation"),
				r:Array<Float> = field(n, "rotation"),
				s:Array<Float> = field(n, "scale");
			if (t != null)
				node.setPosition(t[0], t[1], t[2]);
			if (r != null)
				node.setQuaternion(r[0], r[1], r[2], r[3]);
			if (s != null)
				node.setScale(s[0], s[1], s[2]);
		}
		var children:Array<Int> = field(n, "children");
		if (children != null)
			for (c in children)
				node.add(this.node(c));
		return node;
	}
}
