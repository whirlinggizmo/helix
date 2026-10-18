package helix.scene;

import haxe.io.Bytes;
import helix.assets.Failure;
import helix.behavior.Behaviors;
import helix.render3d.Stage3D;
import helix.scene.SceneSchema;

/** A .scene file as parsed: HeliX's own JSON, one tree. Its version ("helix-scene"), its stage section and its nodes, each a SceneNode
	with its kind's properties as SceneSchema's tables say. Parsed from bytes, every problem logged through Failure and the whole refused, so
	a file either loads as written or says why; written back canonically (write), so load, write, load gives the same bytes and a hand
	edit stays where it was made; instantiated onto a stage (instantiate) and captured back from a live instance (capture). */
class SceneFile {
	/** The format version read and written: the file's "helix-scene" value. */
	public static inline var VERSION = 1;

	/** The file's "helix-scene" version: VERSION, the only one read. */
	public var version:Int = VERSION;

	/** Its stage section, or null when the file has none. */
	public var stage:Null<SceneStage>;

	/** Its nodes at the root, in drawing order. */
	public var nodes:Array<SceneNode> = [];

	/** An empty file of the current version: no stage section, no nodes. */
	public function new() {}

	/** The file in bytes (JSON), parsed; path names it in the log. Null, with every problem logged through Failure naming the node's path or
		the key, for a file that isn't a JSON object, a missing or other "helix-scene" version, an unknown key at the root, in the stage section
		or in a material, a node without a name, two siblings with one name, a node with both "kind" and "scene" or neither, a kind no table
		has, a key no table has on a node or an override, a value of the wrong shape, a file or a material on a kind that isn't a Model,
		overrides on a node with no file and no scene, an override with a name or a kind or an empty path, or a behavior without a kind. */
	public static function parse(bytes:Bytes, ?path:String):Null<SceneFile> {
		var file = new SceneReader(path != null ? path : "scene").read(bytes);
		if (file != null)
			file.path = path;
		return file;
	}

	/** Makes the file's tree on stage, its behaviors on behaviors: the stage section applied (ambient, tonemap and exposure at once, the
		environment and background once their files land through Environments), then every node at once under a new group named after the
		file (its path without directory and extension) added to the stage's root, a Model's file and a prefab landing later through Models
		and SceneFiles (their nodes moved under the entry's node, which is then the file's root, the entry's overrides applied by path), each
		node's behaviors made from BehaviorRegistry and attached once everything has landed. ready, when given, is called at the pass's
		next update after that, once the behaviors have started: never inside this call. A missing model, prefab or environment, a prefab
		naming itself (directly or through another), an unknown behavior, a refused prop or property, and an override naming no node are
		each logged through Failure with this file's path and the node's, the rest made, and ready still comes. The instance remembers
		where each node came from, for capture. */
	public function instantiate(stage:Stage3D, behaviors:Behaviors, ?ready:Void->Void):SceneInstance
		return SceneInstance.make(this, path != null ? path : "scene", stage, behaviors, ready);

	/** The path it was parsed under, as parse was given it; "scene" for none. What instantiate names the instance by. */
	public var path(default, null):Null<String>;

	/** The file that would instantiate to what instance is now: the stage section from its stage (what isn't the stage's default), each of
		the instance's own nodes from the live node (its kind, name, transform, flags, properties, material where the file gave one, the
		behaviors the instance attached with their props away from their defaults, its props), a node from a model file or a prefab as the
		reference plus an override for every node under it whose values differ from what the file gave (what differs only, with the
		children and behaviors attached there; a file that hasn't landed keeps its overrides as written), and a node a game added at run
		time as its class with its properties (a Model made in code has no file and loads back as an empty Model: logged once). A reference
		is written as the node's name when one node of the instance has it, else its path. The defaults rule: a capture says only what
		differs from the defaults, so the stage section holds what isn't the stage's default, a behavior's prop at its schema default is
		left out, a kind's property at its class's default is left out, and a flag at its kind's own default is left out; a default a hand
		wrote into the file vanishes on capture. Capturing an untouched instance gives the file it was made from, written canonically. */
	public static function capture(instance:SceneInstance):SceneFile
		return @:privateAccess instance.capture();

	/** The file as canonical JSON: keys in a fixed order, two-space indentation, one key per line, number lists on one line, a trailing
		newline, numbers with at most six decimals and no trailing zeros, written alike on every target. Absent keys mean defaults: a
		transform at identity, a node's flag at its kind's own default (an override's is written whenever said), a property at its class's
		default, an unsaid stage or material value, and a property no table has, are not written. */
	public function write():Bytes
		return Bytes.ofString(new SceneWriter().write(this));
}

/** The parser: reads the JSON into the file's classes, checking every key and shape against the schema, logging each problem with the
	path of the node it was found in and going on, so one load says everything wrong with a file. */
private class SceneReader {
	final path:String;
	var problems = 0;

	/** A reader logging its problems under path. */
	public function new(path:String)
		this.path = path;

	/** bytes as a file, or null with every problem logged. */
	public function read(bytes:Bytes):Null<SceneFile> {
		var root:Dynamic = try haxe.Json.parse(bytes.toString()) catch (_:Dynamic) null;
		if (!isObject(root)) {
			refuse("file", "not a JSON object");
			return null;
		}
		var file = new SceneFile();
		if (!Reflect.hasField(root, "helix-scene"))
			refuse("file", 'no helix-scene version; ${SceneFile.VERSION} is read');
		for (key in Reflect.fields(root)) {
			var value:Dynamic = Reflect.field(root, key);
			switch key {
				case "helix-scene":
					if (isNumber(value) && (value : Float) == SceneFile.VERSION)
						file.version = SceneFile.VERSION;
					else
						refuse("helix-scene", 'version ${describe(value)} is not ${SceneFile.VERSION}');
				case "stage":
					file.stage = readStage(value);
				case "nodes":
					file.nodes = readNodes(value, "nodes", "");
				case _:
					refuse("file", 'unknown key $key');
			}
		}
		return problems == 0 ? file : null;
	}

	function refuse(where:String, reason:String):Void {
		Failure.report(path, '$where: $reason', null);
		problems++;
	}

	// A list of nodes, siblings under parentPath ("" at the root, else the parent's path and a slash), each named once among them.
	function readNodes(value:Dynamic, where:String, parentPath:String):Array<SceneNode> {
		var nodes = [];
		if (!Std.isOfType(value, Array)) {
			refuse(where, "expected a list of nodes");
			return nodes;
		}
		var list:Array<Dynamic> = value, names = new Map<String, Bool>();
		for (i in 0...list.length) {
			var node = readNode(list[i], '$where[$i]', parentPath, false);
			if (node == null)
				continue;
			if (node.name != null) {
				if (names.exists(node.name))
					refuse(parentPath + node.name, "two siblings with one name");
				names.set(node.name, true);
			}
			nodes.push(node);
		}
		return nodes;
	}

	// One node (or, as an override, what changes on one): where names it until its name is known, parentPath leads its path.
	function readNode(value:Dynamic, where:String, parentPath:String, overriding:Bool):Null<SceneNode> {
		if (!isObject(value)) {
			refuse(where, overriding ? "expected an override object" : "expected a node object");
			return null;
		}
		var node = new SceneNode();
		var kind:Dynamic = Reflect.field(value, "kind"),
			scene:Dynamic = Reflect.field(value, "scene"),
			name:Dynamic = Reflect.field(value, "name"),
			file:Dynamic = Reflect.field(value, "file");
		if (overriding) {
			for (key in ["kind", "scene", "name", "file"])
				if (Reflect.hasField(value, key))
					refuse(where, 'an override has no $key, only what changes');
		} else {
			if (Reflect.hasField(value, "name")) {
				if (Std.isOfType(name, String) && (name : String) != "")
					node.name = name;
				else
					refuse(where, "expected a name, text that isn't empty");
			} else
				refuse(where, "a node needs a name");
			if (node.name != null)
				where = parentPath + node.name;
			if (Reflect.hasField(value, "kind") && Reflect.hasField(value, "scene"))
				refuse(where, "a node has a kind or a scene, not both");
			else if (!Reflect.hasField(value, "kind") && !Reflect.hasField(value, "scene"))
				refuse(where, "a node needs a kind or a scene");
			if (Reflect.hasField(value, "kind")) {
				if (Std.isOfType(kind, String) && SceneSchema.kind(kind) != null)
					node.kind = kind;
				else
					refuse(where, 'unknown kind ${describe(kind)}');
			}
			if (Reflect.hasField(value, "scene")) {
				if (Std.isOfType(scene, String) && (scene : String) != "")
					node.scene = scene;
				else
					refuse(where, "expected a scene, a file's path");
			}
			if (Reflect.hasField(value, "file")) {
				if (node.kind != "Model")
					refuse(where, "a file belongs to a Model");
				else if (Std.isOfType(file, String) && (file : String) != "")
					node.file = file;
				else
					refuse(where, "expected a file, a glTF's path");
			}
		}
		var schema = node.kind != null ? SceneSchema.kind(node.kind) : null;
		for (key in Reflect.fields(value)) {
			var item:Dynamic = Reflect.field(value, key);
			switch key {
				case "kind" | "scene" | "name" | "file":
				case "position":
					node.position = readFloats(item, 3, where, key);
				case "rotation":
					node.rotation = readFloats(item, 3, where, key);
				case "scale":
					node.scale = readFloats(item, 3, where, key);
				case "enabled":
					node.enabled = readBool(item, where, key);
				case "visible":
					node.visible = readBool(item, where, key);
				case "pickable":
					node.pickable = readBool(item, where, key);
				case "material":
					if (overriding || node.kind == "Model")
						node.material = readMaterial(item, where);
					else
						refuse(where, "a material belongs to a Model");
				case "overrides":
					if (overriding || node.file != null || node.scene != null)
						readOverrides(item, node, where);
					else
						refuse(where, "overrides belong to a node with a file or a scene");
				case "children":
					node.children = readNodes(item, '$where/children', where + "/");
				case "behaviors":
					node.behaviors = readBehaviors(item, where);
				case "props":
					if (isObject(item))
						node.props = readValues(item, '$where props');
					else
						refuse(where, "expected props, an object of values");
				case _:
					var property = schema != null ? schema.property(key) : overriding ? SceneSchema.property(key) : null;
					if (property == null) {
						refuse(where, 'unknown key $key');
						continue;
					}
					var read = readTyped(item, property.type, where, key);
					if (read != null)
						node.properties.set(key, read);
			}
		}
		return node;
	}

	function readOverrides(value:Dynamic, node:SceneNode, where:String):Void {
		if (!isObject(value)) {
			refuse(where, "expected overrides, an object by path");
			return;
		}
		for (key in Reflect.fields(value)) {
			if (key == "") {
				refuse(where, "an override's path is empty");
				continue;
			}
			var found = readNode(Reflect.field(value, key), '$where overrides $key', '$where/$key/', true);
			if (found != null)
				node.overrides.set(key, found);
		}
	}

	function readBehaviors(value:Dynamic, where:String):Array<SceneBehavior> {
		var behaviors = [];
		if (!Std.isOfType(value, Array)) {
			refuse(where, "expected behaviors, a list");
			return behaviors;
		}
		var list:Array<Dynamic> = value;
		for (i in 0...list.length) {
			var item:Dynamic = list[i], at = '$where behaviors[$i]';
			if (!isObject(item)) {
				refuse(at, "expected a behavior object");
				continue;
			}
			var kind:Dynamic = Reflect.field(item, "kind");
			if (!Std.isOfType(kind, String) || (kind : String) == "") {
				refuse(at, "a behavior needs a kind");
				continue;
			}
			var behavior = new SceneBehavior(kind);
			for (key in Reflect.fields(item)) {
				var field:Dynamic = Reflect.field(item, key);
				switch key {
					case "kind":
					case "props":
						if (isObject(field))
							behavior.props = readValues(field, at);
						else
							refuse(at, "expected props, an object of values");
					case _:
						refuse(at, 'unknown key $key');
				}
			}
			behaviors.push(behavior);
		}
		return behaviors;
	}

	// Values without a table: a behavior's props and a node's own, each as its JSON shape says.
	function readValues(value:Dynamic, where:String):Map<String, SceneValue> {
		var values = new Map<String, SceneValue>();
		for (key in Reflect.fields(value)) {
			var read = readFree(Reflect.field(value, key), where, key);
			if (read != null)
				values.set(key, read);
		}
		return values;
	}

	function readFree(value:Dynamic, where:String, key:String):Null<SceneValue> {
		if (isNumber(value))
			return Number(value);
		if (Std.isOfType(value, Bool))
			return Flag(value);
		if (Std.isOfType(value, String)) {
			var text:String = value;
			if (text.length > 1 && text.charAt(0) == "@")
				return Reference(text.substr(1));
			var color = parseColor(text);
			return color != null ? Color(color) : Text(text);
		}
		if (Std.isOfType(value, Array)) {
			var list:Array<Dynamic> = value, numbers = [];
			for (item in list) {
				if (!isNumber(item)) {
					refuse(where, '$key: a list holds numbers only');
					return null;
				}
				numbers.push((item : Float));
			}
			return Numbers(numbers);
		}
		refuse(where, '$key: expected a number, text, a bool, a list of numbers, a color or a reference');
		return null;
	}

	function readTyped(value:Dynamic, type:PropertyType, where:String, key:String):Null<SceneValue> {
		switch type {
			case Number(_, _):
				if (isNumber(value))
					return Number(value);
				refuse(where, '$key: expected a number');
			case Text:
				if (Std.isOfType(value, String))
					return Text(value);
				refuse(where, '$key: expected text');
			case Flag:
				if (Std.isOfType(value, Bool))
					return Flag(value);
				refuse(where, '$key: expected true or false');
			case Numbers(count):
				var numbers = readFloats(value, count, where, key);
				if (numbers != null)
					return Numbers(numbers);
			case Color:
				var color = Std.isOfType(value, String) ? parseColor(value) : null;
				if (color != null)
					return Color(color);
				refuse(where, '$key: expected a color, #RRGGBB or #RRGGBBAA');
			case Reference:
				if (Std.isOfType(value, String) && (value : String).length > 1 && (value : String).charAt(0) == "@")
					return Reference((value : String).substr(1));
				refuse(where, '$key: expected a reference, @name or @path');
		}
		return null;
	}

	function readFloats(value:Dynamic, count:Int, where:String, key:String):Null<Array<Float>> {
		if (Std.isOfType(value, Array)) {
			var list:Array<Dynamic> = value;
			if (list.length == count) {
				var numbers = [];
				for (item in list)
					if (isNumber(item))
						numbers.push((item : Float));
				if (numbers.length == count)
					return numbers;
			}
		}
		refuse(where, '$key: expected a list of $count numbers');
		return null;
	}

	function readBool(value:Dynamic, where:String, key:String):Null<Bool> {
		if (Std.isOfType(value, Bool))
			return value;
		refuse(where, '$key: expected true or false');
		return null;
	}

	function readFloat(value:Dynamic, where:String, key:String):Null<Float> {
		if (isNumber(value))
			return value;
		refuse(where, '$key: expected a number');
		return null;
	}

	function readText(value:Dynamic, where:String, key:String):Null<String> {
		if (Std.isOfType(value, String))
			return value;
		refuse(where, '$key: expected text');
		return null;
	}

	function readColor(value:Dynamic, where:String, key:String):Null<Int> {
		var color = Std.isOfType(value, String) ? parseColor(value) : null;
		if (color == null)
			refuse(where, '$key: expected a color, #RRGGBB or #RRGGBBAA');
		return color;
	}

	function readStage(value:Dynamic):Null<SceneStage> {
		if (!isObject(value)) {
			refuse("stage", "expected an object");
			return null;
		}
		var stage = new SceneStage();
		for (key in Reflect.fields(value)) {
			var item:Dynamic = Reflect.field(value, key);
			switch key {
				case "ambient":
					readSection(item, "stage ambient", ["color", "intensity"], (name, field) -> switch name {
						case "color": stage.ambientColor = readColor(field, "stage ambient", name);
						case _: stage.ambientIntensity = readFloat(field, "stage ambient", name);
					});
				case "environment":
					readSection(item, "stage environment", ["file", "intensity", "rotation"], (name, field) -> switch name {
						case "file": stage.environmentFile = readText(field, "stage environment", name);
						case "intensity": stage.environmentIntensity = readFloat(field, "stage environment", name);
						case _: stage.environmentRotation = readFloat(field, "stage environment", name);
					});
				case "background":
					readSection(item, "stage background", ["file", "blur"], (name, field) -> switch name {
						case "file": stage.backgroundFile = readText(field, "stage background", name);
						case _: stage.backgroundBlur = readFloat(field, "stage background", name);
					});
				case "tonemap":
					if (Std.isOfType(item, String) && SceneSchema.tonemaps.indexOf(item) >= 0)
						stage.tonemap = item;
					else
						refuse("stage", 'tonemap: expected ${SceneSchema.tonemaps.join(", ")}');
				case "exposure":
					stage.exposure = readFloat(item, "stage", key);
				case _:
					refuse("stage", 'unknown key $key');
			}
		}
		return stage;
	}

	// A section of the stage: an object whose keys are among keys, each read by read.
	function readSection(value:Dynamic, where:String, keys:Array<String>, read:(String, Dynamic) -> Void):Void {
		if (!isObject(value)) {
			refuse(where, "expected an object");
			return;
		}
		for (key in Reflect.fields(value))
			if (keys.indexOf(key) >= 0)
				read(key, Reflect.field(value, key));
			else
				refuse(where, 'unknown key $key');
	}

	function readMaterial(value:Dynamic, where:String):Null<SceneMaterial> {
		if (!isObject(value)) {
			refuse(where, "material: expected an object");
			return null;
		}
		var material = new SceneMaterial(), at = '$where material';
		for (key in Reflect.fields(value)) {
			var item:Dynamic = Reflect.field(value, key);
			switch key {
				case "baseColor":
					material.baseColor = readColor(item, at, key);
				case "metallic":
					material.metallic = readFloat(item, at, key);
				case "roughness":
					material.roughness = readFloat(item, at, key);
				case "texture":
					material.texture = readText(item, at, key);
				case "normalTexture":
					material.normalTexture = readText(item, at, key);
				case "normalScale":
					material.normalScale = readFloat(item, at, key);
				case "emissive":
					material.emissive = readColor(item, at, key);
				case "emissiveStrength":
					material.emissiveStrength = readFloat(item, at, key);
				case "doubleSided":
					material.doubleSided = readBool(item, at, key);
				case _:
					refuse(at, 'unknown key $key');
			}
		}
		return material;
	}

	/** "#RRGGBB" or "#RRGGBBAA" (either case) as 0xRRGGBBAA; null for anything else. */
	public static function parseColor(text:String):Null<Int> {
		if ((text.length != 7 && text.length != 9) || text.charAt(0) != "#")
			return null;
		var value = 0;
		for (i in 1...text.length) {
			var c = text.charCodeAt(i),
				digit = c >= 0x30
					&& c <= 0x39 ? c - 0x30 : c >= 0x61 && c <= 0x66 ? c - 0x61 + 10 : c >= 0x41 && c <= 0x46 ? c - 0x41 + 10 : -1;
			if (digit < 0)
				return null;
			value = (value << 4) | digit;
		}
		return text.length == 7 ? (value << 8) | 0xff : value;
	}

	static function isObject(value:Dynamic):Bool
		return value != null && Reflect.isObject(value) && !Std.isOfType(value, String) && !Std.isOfType(value, Array);

	static function isNumber(value:Dynamic):Bool
		return Std.isOfType(value, Float) && !Std.isOfType(value, Bool);

	// What a value is, for a message: its shape, never its content (a log line holds no braces or quotes from the file).
	static function describe(value:Dynamic):String {
		if (value == null)
			return "null";
		if (Std.isOfType(value, Bool))
			return "a bool";
		if (isNumber(value))
			return "a number";
		if (Std.isOfType(value, String))
			return '"$value"';
		if (Std.isOfType(value, Array))
			return "a list";
		return "an object";
	}
}

/** The canonical writer: every value in one place, every key in its fixed order, numbers formatted by integer arithmetic so the browser
	and native write the same bytes. */
private class SceneWriter {
	/** A writer. */
	public function new() {}

	/** file as canonical JSON text, with its trailing newline. */
	public function write(file:SceneFile):String {
		var entries = [entry("helix-scene", [Std.string(file.version)])];
		if (file.stage != null)
			entries.push(entry("stage", stage(file.stage)));
		entries.push(entry("nodes", array([for (n in file.nodes) node(n)])));
		return object(entries).join("\n") + "\n";
	}

	function stage(stage:SceneStage):Array<String> {
		var entries = [];
		var ambient = [];
		if (stage.ambientColor != null)
			ambient.push(entry("color", [color(stage.ambientColor)]));
		if (stage.ambientIntensity != null)
			ambient.push(entry("intensity", [number(stage.ambientIntensity)]));
		if (ambient.length > 0)
			entries.push(entry("ambient", object(ambient)));
		var environment = [];
		if (stage.environmentFile != null)
			environment.push(entry("file", [string(stage.environmentFile)]));
		if (stage.environmentIntensity != null)
			environment.push(entry("intensity", [number(stage.environmentIntensity)]));
		if (stage.environmentRotation != null)
			environment.push(entry("rotation", [number(stage.environmentRotation)]));
		if (environment.length > 0)
			entries.push(entry("environment", object(environment)));
		var background = [];
		if (stage.backgroundFile != null)
			background.push(entry("file", [string(stage.backgroundFile)]));
		if (stage.backgroundBlur != null)
			background.push(entry("blur", [number(stage.backgroundBlur)]));
		if (background.length > 0)
			entries.push(entry("background", object(background)));
		if (stage.tonemap != null)
			entries.push(entry("tonemap", [string(stage.tonemap)]));
		if (stage.exposure != null)
			entries.push(entry("exposure", [number(stage.exposure)]));
		return object(entries);
	}

	function node(node:SceneNode):Array<String> {
		var entries = [];
		var overriding = node.isOverride;
		if (node.scene != null)
			entries.push(entry("scene", [string(node.scene)]));
		else if (node.kind != null)
			entries.push(entry("kind", [string(node.kind)]));
		if (node.name != null)
			entries.push(entry("name", [string(node.name)]));
		if (node.file != null)
			entries.push(entry("file", [string(node.file)]));
		// A node's transform at identity is left out; an override's is what it changes, so it is written as given.
		if (node.position != null && (overriding || !isAll(node.position, 0)))
			entries.push(entry("position", [numbers(node.position)]));
		if (node.rotation != null && (overriding || !isAll(node.rotation, 0)))
			entries.push(entry("rotation", [numbers(node.rotation)]));
		if (node.scale != null && (overriding || !isAll(node.scale, 1)))
			entries.push(entry("scale", [numbers(node.scale)]));
		// A node's flag at its kind's own default is left out (a file or a prefab node's are a plain group's, true); an override's is
		// written whenever said, since its base is the file's.
		var schema = node.kind != null ? SceneSchema.kind(node.kind) : null;
		for (flag in [
			{key: "enabled", value: node.enabled, kinds: schema == null || schema.enabled},
			{key: "visible", value: node.visible, kinds: schema == null || schema.visible},
			{key: "pickable", value: node.pickable, kinds: schema == null || schema.pickable}
		])
			if (flag.value != null && (overriding || flag.value != flag.kinds))
				entries.push(entry(flag.key, [flag.value ? "true" : "false"]));
		if (schema != null) {
			for (property in schema.properties) {
				var held = node.properties.get(property.name);
				if (held != null && !same(held, property.defaultValue))
					entries.push(entry(property.name, [value(held)]));
			}
		} else if (overriding) {
			var written = new Map<String, Bool>();
			for (kind in SceneSchema.kinds)
				for (property in kind.properties) {
					var held = node.properties.get(property.name);
					if (held != null && !written.exists(property.name)) {
						written.set(property.name, true);
						entries.push(entry(property.name, [value(held)]));
					}
				}
		}
		if (node.material != null)
			entries.push(entry("material", material(node.material)));
		var paths = sorted([for (path in node.overrides.keys()) path]);
		if (paths.length > 0)
			entries.push(entry("overrides", object([for (path in paths) entry(path, this.node(node.overrides.get(path)))])));
		if (node.children.length > 0)
			entries.push(entry("children", array([for (child in node.children) this.node(child)])));
		if (node.behaviors.length > 0)
			entries.push(entry("behaviors", array([for (behavior in node.behaviors) this.behavior(behavior)])));
		if (count(node.props) > 0)
			entries.push(entry("props", values(node.props)));
		return object(entries);
	}

	function behavior(behavior:SceneBehavior):Array<String> {
		var entries = [entry("kind", [string(behavior.kind)])];
		if (count(behavior.props) > 0)
			entries.push(entry("props", values(behavior.props)));
		return object(entries);
	}

	function values(map:Map<String, SceneValue>):Array<String>
		return object([
			for (key in sorted([for (key in map.keys()) key]))
				entry(key, [value(map.get(key))])
		]);

	function material(material:SceneMaterial):Array<String> {
		var entries = [];
		if (material.baseColor != null)
			entries.push(entry("baseColor", [color(material.baseColor)]));
		if (material.metallic != null)
			entries.push(entry("metallic", [number(material.metallic)]));
		if (material.roughness != null)
			entries.push(entry("roughness", [number(material.roughness)]));
		if (material.texture != null)
			entries.push(entry("texture", [string(material.texture)]));
		if (material.normalTexture != null)
			entries.push(entry("normalTexture", [string(material.normalTexture)]));
		if (material.normalScale != null)
			entries.push(entry("normalScale", [number(material.normalScale)]));
		if (material.emissive != null)
			entries.push(entry("emissive", [color(material.emissive)]));
		if (material.emissiveStrength != null)
			entries.push(entry("emissiveStrength", [number(material.emissiveStrength)]));
		if (material.doubleSided != null)
			entries.push(entry("doubleSided", [material.doubleSided ? "true" : "false"]));
		return object(entries);
	}

	function value(value:SceneValue):String
		return switch value {
			case Number(v): number(v);
			case Text(v): string(v);
			case Flag(v): v ? "true" : "false";
			case Numbers(v): numbers(v);
			case Color(v): color(v);
			case Reference(v): string("@" + v);
		}

	// Whether two values are the same, so one at its default is left out.
	static function same(a:SceneValue, b:SceneValue):Bool
		return switch [a, b] {
			case [Number(x), Number(y)]: x == y;
			case [Text(x), Text(y)]: x == y;
			case [Flag(x), Flag(y)]: x == y;
			case [Color(x), Color(y)]: x == y;
			case [Reference(x), Reference(y)]: x == y;
			case [Numbers(x), Numbers(y)]:
				if (x.length != y.length)
					return false;
				for (i in 0...x.length)
					if (x[i] != y[i])
						return false;
				true;
			case _: false;
		}

	static function isAll(values:Array<Float>, k:Float):Bool {
		for (v in values)
			if (v != k)
				return false;
		return true;
	}

	static function count(map:Map<String, SceneValue>):Int {
		var n = 0;
		for (_ in map.keys())
			n++;
		return n;
	}

	static function sorted(keys:Array<String>):Array<String> {
		keys.sort((a, b) -> a < b ? -1 : a > b ? 1 : 0);
		return keys;
	}

	// A key with its value's lines: one for a scalar or a number list, the braces and their contents for an object or a list of objects.
	static function entry(key:String, lines:Array<String>):{key:String, lines:Array<String>}
		return {key: key, lines: lines};

	// An object's lines: "{", each entry indented with its key, a comma after all but the last, "}"; "{}" for none.
	static function object(entries:Array<{key:String, lines:Array<String>}>):Array<String> {
		if (entries.length == 0)
			return ["{}"];
		var lines = ["{"];
		for (i in 0...entries.length) {
			var value = entries[i].lines.copy();
			value[0] = string(entries[i].key) + ": " + value[0];
			if (i < entries.length - 1)
				value[value.length - 1] += ",";
			for (line in value)
				lines.push("  " + line);
		}
		lines.push("}");
		return lines;
	}

	// A list of objects' lines: "[", each item indented, a comma after all but the last, "]"; "[]" for none.
	static function array(items:Array<Array<String>>):Array<String> {
		if (items.length == 0)
			return ["[]"];
		var lines = ["["];
		for (i in 0...items.length) {
			var value = items[i].copy();
			if (i < items.length - 1)
				value[value.length - 1] += ",";
			for (line in value)
				lines.push("  " + line);
		}
		lines.push("]");
		return lines;
	}

	static function numbers(values:Array<Float>):String
		return "[" + [for (v in values) number(v)].join(", ") + "]";

	// "#rrggbb" when the alpha is ff, else "#rrggbbaa", quoted.
	static function color(rgba:Int):String {
		var text = "#" + hex(rgba >>> 24) + hex((rgba >> 16) & 0xff) + hex((rgba >> 8) & 0xff);
		if (rgba & 0xff != 0xff)
			text += hex(rgba & 0xff);
		return '"$text"';
	}

	static function hex(byte:Int):String
		return "0123456789abcdef".charAt(byte >> 4) + "0123456789abcdef".charAt(byte & 15);

	/** A number as every target writes it: an integer-valued one without a point, else with at most six decimals and no trailing zeros,
		by integer arithmetic on the rounded fraction (Std.string of a Float differs between targets). One that isn't finite is 0. */
	public static function number(value:Float):String {
		if (!Math.isFinite(value))
			return "0";
		var negative = value < 0, magnitude = negative ? -value : value;
		var whole = Math.ffloor(magnitude);
		var fraction = Math.round((magnitude - whole) * 1e6);
		if (fraction >= 1000000) {
			whole += 1;
			fraction = 0;
		}
		var text = wholeDigits(whole);
		if (fraction > 0) {
			var digits = Std.string(fraction);
			while (digits.length < 6)
				digits = "0" + digits;
			while (digits.charAt(digits.length - 1) == "0")
				digits = digits.substr(0, digits.length - 1);
			text += "." + digits;
		}
		return negative && text != "0" ? "-" + text : text;
	}

	// The digits of a non-negative integer-valued Float: through Int where it fits, else a digit at a time.
	static function wholeDigits(whole:Float):String {
		if (whole < 2147483648.)
			return Std.string(Std.int(whole));
		var digits = "";
		while (whole >= 1) {
			var tenth = Math.ffloor(whole / 10);
			var digit = Std.int(whole - tenth * 10);
			digits = Std.string(digit < 0 ? 0 : digit > 9 ? 9 : digit) + digits;
			whole = tenth;
		}
		return digits;
	}

	// text quoted, with JSON's escapes for the quote, the backslash and control characters; everything else as it is.
	static function string(text:String):String {
		var out = new StringBuf(), start = 0;
		out.add('"');
		for (i in 0...text.length) {
			var c = text.charCodeAt(i);
			var escaped = switch c {
				case 0x22: '\\"';
				case 0x5c: "\\\\";
				case 0x0a: "\\n";
				case 0x0d: "\\r";
				case 0x09: "\\t";
				case 0x08: "\\b";
				case 0x0c: "\\f";
				case _: c < 0x20 ? "\\u00" + hex(c) : null;
			}
			if (escaped != null) {
				out.add(text.substr(start, i - start));
				out.add(escaped);
				start = i + 1;
			}
		}
		out.add(text.substr(start));
		out.add('"');
		return out.toString();
	}
}
