import haxe.io.Bytes;
import helix.scene.SceneFile;
import helix.scene.SceneSchema;
import helix.scene.SceneValue;

/** The .scene file (helix.scene.SceneFile): a sample with the stage section and every kind parses, writes, parses and writes the same
	bytes; a small sample writes the pinned canonical form (key order, defaults left out, colors, numbers); each refusal returns null; and
	every kind's table reads and writes every property. */
class SceneFileTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function parse(text:String, ?path:String):Null<SceneFile>
		return SceneFile.parse(Bytes.ofString(text), path != null ? path : "test.scene");

	static function refused(text:String, message:String):Void
		check(parse(text, "refused.scene") == null, message);

	// Whether two values are the same, a list by its numbers (an enum's equals compares a list by reference).
	static function same(a:Null<SceneValue>, b:SceneValue):Bool {
		if (a == null)
			return false;
		return switch [a, b] {
			case [Numbers(x), Numbers(y)]: x.length == y.length && [for (i in 0...x.length) x[i] == y[i]].indexOf(false) < 0;
			case _: a.equals(b);
		}
	}

	static function main():Void {
		roundTrip();
		canonical();
		refusals();
		schema();
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}

	// The stage section, every kind, a file node with overrides (a property, a child added, a behavior attached), a prefab node, an inline
	// material, a behavior with every value type and a reference, and node props: parse, write, parse, write gives equal bytes.
	static function roundTrip():Void {
		var text = '{
			"helix-scene": 1,
			"stage": {
				"ambient": {"color": "#ffffff", "intensity": 0.25},
				"environment": {"file": "sky/sky.hdr", "intensity": 0.7, "rotation": 0},
				"background": {"file": "sky/sky.hdr", "blur": 0},
				"tonemap": "neutral",
				"exposure": 0
			},
			"nodes": [
				{"kind": "Node3D", "name": "world", "enabled": false, "children": [
					{"kind": "DirectionalLight", "name": "sun", "rotation": [-0.6, 0.7, 0], "color": "#fff4e0", "intensity": 3.5,
						"shadowCasting": true, "shadowDistance": 35, "shadowMapSize": 1024, "shadowStrength": 0.8, "shadowColor": "#102040"},
					{"kind": "PointLight", "name": "lamp", "position": [1, 2, 3], "range": 10, "intensity": 2},
					{"kind": "SpotLight", "name": "spot", "range": 20, "innerCone": 0.2, "outerCone": 0.5, "shadowCasting": true},
					{"kind": "Camera3D", "name": "chase", "position": [0, 3, -8], "fovY": 0.9, "near": 0.5, "far": 500, "minAspect": 1.777778,
						"behaviors": [{"kind": "ChaseCamera", "props": {"target": "@car", "speed": 1.5, "label": "go", "on": false,
							"offset": [0, 1.5, -6], "tint": "#ff000080"}}]},
					{"kind": "Sprite3D", "name": "glow", "texture": "fx/glow.png", "tint": "#ffffff80", "regionX": 8, "regionY": 8,
						"regionWidth": 16, "regionHeight": 16, "spriteWidth": 2, "spriteHeight": 2, "pivotX": 0, "pivotY": 1,
						"facing": "upright", "alphaMode": "add", "alphaCutoff": 0.25, "pickable": false},
					{"kind": "Text3D", "name": "label", "text": "Start \\"here\\"\\n", "textSize": 0.8, "color": "#80ff80", "font": "fonts/ui.fnt",
						"pivotY": 0, "facing": "free"},
					{"kind": "Particles3D", "name": "dust", "position": [0, 0.1, 0], "visible": false},
					{"kind": "Model", "name": "track", "file": "track/track.glb", "scale": [2, 2, 2], "shadowReceiving": false, "overrides": {
						"road": {"shadowCasting": false, "visible": false, "pickable": true},
						"road/line": {"tint": "#808080", "position": [0, 0, 0], "material": {"baseColor": "#2040c0"}},
						"gates/gate_0": {"children": [{"kind": "Node3D", "name": "checkpoint", "position": [0, 2, 0],
							"behaviors": [{"kind": "Checkpoint", "props": {"index": 0}}]}], "behaviors": [{"kind": "Gate"}]}
					}},
					{"kind": "Model", "name": "cone_1", "file": "props/cone.glb", "position": [12, 0, -3], "tint": "#ff8800", "shadowCasting": false,
						"material": {"baseColor": "#ff8800", "metallic": 0.1, "roughness": 0.3, "texture": "props/cone.png",
							"normalTexture": "props/cone_n.png", "normalScale": 0.5, "emissive": "#ff0000", "emissiveStrength": 2, "doubleSided": true},
						"props": {"team": 2, "role": "obstacle", "path": [1, 2, 3], "hot": true, "color": "#ff0000", "leader": "@cone_1"}},
					{"scene": "prefabs/car.scene", "name": "car", "position": [0, 0.5, 12],
						"overrides": {"body": {"material": {"baseColor": "#2040c0"}}}, "behaviors": [{"kind": "Car", "props": {"topSpeed": 60}}]}
				]}
			]
		}';
		var file = parse(text, "levels/track.scene");
		check(file != null && file.version == 1 && file.nodes.length == 1, "The sample parses: version 1, one root node");
		var stage = file.stage;
		check(stage != null
			&& stage.ambientColor == 0xffffffff
			&& stage.ambientIntensity == 0.25
			&& stage.environmentFile == "sky/sky.hdr"
			&& stage.environmentIntensity == 0.7
			&& stage.environmentRotation == 0
			&& stage.backgroundFile == "sky/sky.hdr"
			&& stage.backgroundBlur == 0
			&& stage.tonemap == "neutral"
			&& stage.exposure == 0,
			"The stage section, every value");
		var world = file.nodes[0];
		check(world.kind == "Node3D" && world.name == "world" && world.enabled == false && world.visible == null && world.children.length == 10,
			"The root group: its flag, the unsaid one null, its ten children");
		var sun = world.children[0];
		check(sun.kind == "DirectionalLight"
			&& sun.rotation.length == 3
			&& sun.rotation[0] == -0.6
			&& sun.position == null
			&& same(sun.properties.get("intensity"), Number(3.5))
			&& same(sun.properties.get("color"), Color(0xfff4e0ff))
			&& same(sun.properties.get("shadowColor"), Color(0x102040ff))
			&& same(sun.properties.get("shadowCasting"), Flag(true)),
			"A light's properties: a color with alpha ff, a number, a flag");
		var chase = world.children[3];
		check(chase.behaviors.length == 1 && chase.behaviors[0].kind == "ChaseCamera", "A behavior by kind");
		var props = chase.behaviors[0].props;
		check(same(props.get("target"), Reference("car"))
			&& same(props.get("speed"), Number(1.5))
			&& same(props.get("label"), Text("go"))
			&& same(props.get("on"), Flag(false))
			&& same(props.get("offset"), Numbers([0, 1.5, -6]))
			&& same(props.get("tint"), Color(0xff000080)),
			"A behavior's props of every value type, the reference without its @");
		var glow = world.children[4];
		check(glow.pickable == false
			&& same(glow.properties.get("facing"), Text("upright"))
			&& same(glow.properties.get("alphaMode"), Text("add")),
			"A sprite's named choices as text");
		var track = world.children[7];
		check(track.file == "track/track.glb"
			&& track.scale[0] == 2
			&& same(track.properties.get("shadowReceiving"), Flag(false)), "A file node");
		var road = track.overrides.get("road"),
			line = track.overrides.get("road/line"),
			gate = track.overrides.get("gates/gate_0");
		check(road != null
			&& road.isOverride
			&& same(road.properties.get("shadowCasting"), Flag(false))
			&& road.visible == false
			&& road.pickable == true
			&& road.enabled == null,
			"An override's property and flags, a true one kept");
		check(line != null
			&& line.material != null
			&& line.material.baseColor == 0x2040c0ff
			&& line.material.roughness == null
			&& same(line.properties.get("tint"), Color(0x808080ff)),
			"An override's material says only what it changes");
		check(gate != null
			&& gate.children.length == 1
			&& gate.children[0].name == "checkpoint"
			&& gate.children[0].behaviors.length == 1
			&& gate.behaviors.length == 1
			&& gate.behaviors[0].kind == "Gate",
			"An override adds a child and a behavior");
		var cone = world.children[8];
		check(cone.material != null
			&& cone.material.metallic == 0.1
			&& cone.material.doubleSided == true
			&& cone.material.normalTexture == "props/cone_n.png"
			&& cone.material.emissive == 0xff0000ff
			&& cone.material.emissiveStrength == 2,
			"An inline material");
		check(same(cone.props.get("team"), Number(2))
			&& same(cone.props.get("leader"), Reference("cone_1"))
			&& same(cone.props.get("color"), Color(0xff0000ff))
			&& same(cone.props.get("path"), Numbers([1, 2, 3])),
			"A node's own props");
		var car = world.children[9];
		check(car.kind == null
			&& car.scene == "prefabs/car.scene"
			&& car.overrides.get("body").material.baseColor == 0x2040c0ff
			&& same(car.behaviors[0].props.get("topSpeed"), Number(60)),
			"A prefab node");
		var written = file.write();
		var again = SceneFile.parse(written, "again.scene");
		check(again != null, "What was written parses");
		check(again.write().compare(written) == 0, "Parse, write, parse, write gives equal bytes");
		check(written.toString().indexOf('"text": "Start \\"here\\"\\n"') >= 0, "Text is escaped as JSON");
		check(written.toString().indexOf('"pickable": true') >= 0, "An override's true flag is written");
	}

	// A small sample in any key order, with values at their defaults, writes the pinned canonical form.
	static function canonical():Void {
		var text = '{"nodes": [
			{"name": "sun", "intensity": 1, "shadowCasting": true, "color": "#fff4e0ff", "rotation": [-0.6, 0.7, 0], "kind": "DirectionalLight",
				"position": [0, 0, 0], "enabled": true},
			{"name": "group", "kind": "Node3D", "visible": false, "scale": [1, 1, 1], "children": [
				{"kind": "Model", "name": "cone", "file": "props/cone.glb", "position": [1, 0.5, 0.3333333333], "rotation": [-2.25, 0, 0],
					"tint": "#ffffff", "material": {"roughness": 0.3, "baseColor": "#ff880080"}, "props": {"team": 2, "name": "x"},
					"behaviors": [{"kind": "Spin", "props": {"speed": 1}}]}]}],
			"stage": {"tonemap": "aces", "ambient": {"intensity": 0.25, "color": "#ffffff"}}, "helix-scene": 1}';
		var expected = [
			'{',
			'  "helix-scene": 1,',
			'  "stage": {',
			'    "ambient": {',
			'      "color": "#ffffff",',
			'      "intensity": 0.25',
			'    },',
			'    "tonemap": "aces"',
			'  },',
			'  "nodes": [',
			'    {',
			'      "kind": "DirectionalLight",',
			'      "name": "sun",',
			'      "rotation": [-0.6, 0.7, 0],',
			'      "color": "#fff4e0",',
			'      "shadowCasting": true',
			'    },',
			'    {',
			'      "kind": "Node3D",',
			'      "name": "group",',
			'      "visible": false,',
			'      "children": [',
			'        {',
			'          "kind": "Model",',
			'          "name": "cone",',
			'          "file": "props/cone.glb",',
			'          "position": [1, 0.5, 0.333333],',
			'          "rotation": [-2.25, 0, 0],',
			'          "material": {',
			'            "baseColor": "#ff880080",',
			'            "roughness": 0.3',
			'          },',
			'          "behaviors": [',
			'            {',
			'              "kind": "Spin",',
			'              "props": {',
			'                "speed": 1',
			'              }',
			'            }',
			'          ],',
			'          "props": {',
			'            "name": "x",',
			'            "team": 2',
			'          }',
			'        }',
			'      ]',
			'    }',
			'  ]',
			'}'
		].join("\n") + "\n";
		var file = parse(text);
		check(file != null, "The small sample parses");
		var written = file.write().toString();
		check(written == expected,
			"The canonical form: fixed key order, a property at its default (intensity, tint) and an identity transform and a true flag left out, " +
			"a color with alpha ff as #RRGGBB, numbers 1, 0.5, 0.333333 and -2.25, props sorted, a trailing newline");
		var empty = new SceneFile();
		check(empty.write().toString() == '{\n  "helix-scene": 1,\n  "nodes": []\n}\n', "An empty file: no stage, no nodes");
		check(SceneFile.parse(empty.write()) != null, "An empty file reads back");
	}

	// Each refusal returns null.
	static function refusals():Void {
		var sun = '{"kind": "DirectionalLight", "name": "sun"}';
		refused('{"nodes": [$sun]}', "No version");
		refused('{"helix-scene": 2, "nodes": [$sun]}', "Another version");
		refused('{"helix-scene": "1", "nodes": [$sun]}', "A version that isn't a number");
		refused('[1, 2]', "Not an object");
		refused('not json', "Not JSON");
		refused('{"helix-scene": 1, "nodes": [{"kind": "DirectionalLight"}]}', "A node without a name");
		refused('{"helix-scene": 1, "nodes": [{"kind": "DirectionalLight", "name": ""}]}', "A node with an empty name");
		refused('{"helix-scene": 1, "nodes": [$sun, $sun]}', "Two siblings with one name");
		refused('{"helix-scene": 1, "nodes": [{"kind": "Node3D", "name": "g", "children": [$sun, $sun]}]}', "Two children with one name");
		refused('{"helix-scene": 1, "nodes": [{"kind": "Node3D", "scene": "a.scene", "name": "x"}]}', "A node with both kind and scene");
		refused('{"helix-scene": 1, "nodes": [{"name": "x"}]}', "A node with neither kind nor scene");
		refused('{"helix-scene": 1, "nodes": [{"kind": "Blob", "name": "x"}]}', "An unknown kind");
		refused('{"helix-scene": 1, "nodes": [{"kind": "DirectionalLight", "name": "x", "colour": "#ffffff"}]}', "An unknown key on a node");
		refused('{"helix-scene": 1, "nodes": [{"kind": "DirectionalLight", "name": "x", "range": 5}]}', "Another kind's property");
		refused('{"helix-scene": 1, "nodes": [{"scene": "a.scene", "name": "x", "intensity": 5}]}', "A property on a prefab node");
		refused('{"helix-scene": 1, "nodes": [{"kind": "DirectionalLight", "name": "x", "intensity": "bright"}]}', "A number that is text");
		refused('{"helix-scene": 1, "nodes": [{"kind": "DirectionalLight", "name": "x", "position": [1, 2]}]}', "A position of two numbers");
		refused('{"helix-scene": 1, "nodes": [{"kind": "DirectionalLight", "name": "x", "color": "red"}]}', "A color that isn't hex");
		refused('{"helix-scene": 1, "nodes": [{"kind": "DirectionalLight", "name": "x", "color": "#ff"}]}', "A color too short");
		refused('{"helix-scene": 1, "nodes": [{"kind": "DirectionalLight", "name": "x", "visible": 1}]}', "A flag that is a number");
		refused('{"helix-scene": 1, "nodes": [{"kind": "DirectionalLight", "name": "x", "shadowCasting": "yes"}]}', "A flag that is text");
		refused('{"helix-scene": 1, "nodes": [{"kind": "Model", "name": "x", "file": "a.glb", "overrides": {"": {"visible": false}}}]}',
			"An override with an empty path");
		refused('{"helix-scene": 1, "nodes": [{"kind": "Model", "name": "x", "file": "a.glb", "overrides": {"a": {"name": "b"}}}]}', "An override with a name");
		refused('{"helix-scene": 1, "nodes": [{"kind": "Model", "name": "x", "file": "a.glb", "overrides": {"a": {"kind": "Node3D"}}}]}',
			"An override with a kind");
		refused('{"helix-scene": 1, "nodes": [{"kind": "Model", "name": "x", "file": "a.glb", "overrides": {"a": {"colour": "#ffffff"}}}]}',
			"An override with a key no kind has");
		refused('{"helix-scene": 1, "nodes": [{"kind": "Node3D", "name": "x", "overrides": {"a": {"visible": false}}}]}',
			"Overrides on a node with no file and no scene");
		refused('{"helix-scene": 1, "nodes": [{"kind": "DirectionalLight", "name": "x", "file": "a.glb"}]}', "A file on a light");
		refused('{"helix-scene": 1, "nodes": [{"kind": "Camera3D", "name": "x", "material": {"roughness": 1}}]}', "A material on a camera");
		refused('{"helix-scene": 1, "nodes": [{"kind": "Model", "name": "x", "material": {"shiny": 1}}]}', "A material with an unknown key");
		refused('{"helix-scene": 1, "nodes": [{"kind": "Model", "name": "x", "behaviors": [{"props": {"a": 1}}]}]}', "A behavior without a kind");
		refused('{"helix-scene": 1, "nodes": [{"kind": "Model", "name": "x", "behaviors": [{"kind": "A", "props": {"a": {"b": 1}}}]}]}',
			"A behavior prop that is an object");
		refused('{"helix-scene": 1, "nodes": [{"kind": "Model", "name": "x", "props": {"a": [1, "b"]}}]}', "A prop list holding text");
		refused('{"helix-scene": 1, "stage": {"fog": 1}, "nodes": []}', "A stage with an unknown key");
		refused('{"helix-scene": 1, "stage": {"ambient": {"colour": "#ffffff"}}, "nodes": []}', "A stage section with an unknown key");
		refused('{"helix-scene": 1, "stage": {"tonemap": "filmic"}, "nodes": []}', "A tonemap the stage hasn't");
		refused('{"helix-scene": 1, "nodes": [], "extra": 1}', "An unknown key at the root");
		check(parse('{"helix-scene": 1}') != null && parse('{"helix-scene": 1}').nodes.length == 0, "Nodes may be absent");
	}

	// Every kind's table reads and writes every property: each set away from its default survives a parse, a write and a parse.
	static function schema():Void {
		check(SceneSchema.kinds.length == 9
			&& SceneSchema.kind("SpotLight").property("outerCone") != null
			&& SceneSchema.kind("Blob") == null,
			"The kinds by name");
		check(SceneSchema.property("tint") != null && SceneSchema.property("colour") == null, "A property on any kind");
		for (kind in SceneSchema.kinds) {
			var keys = [];
			for (property in kind.properties)
				keys.push('"${property.name}": ' + away(property));
			var text = '{"helix-scene": 1, "nodes": [{"kind": "${kind.name}", "name": "n"' + (keys.length > 0 ? ", " + keys.join(", ") : "") + "}]}";
			var file = parse(text, kind.name + ".scene");
			check(file != null, 'Every ${kind.name} property reads');
			var written = file.write();
			var again = SceneFile.parse(written, kind.name + ".scene");
			check(again != null && again.write().compare(written) == 0, 'Every ${kind.name} property writes and reads back');
			for (property in kind.properties)
				check(again.nodes[0].properties.get(property.name) != null
					&& !same(again.nodes[0].properties.get(property.name), property.defaultValue),
					'${kind.name}.${property.name} is kept away from its default');
			var bare = parse('{"helix-scene": 1, "nodes": [{"kind": "${kind.name}", "name": "n"}]}');
			check(bare != null && !bare.nodes[0].properties.keys().hasNext(), 'A bare ${kind.name} has no properties set');
		}
	}

	// A JSON value for property that isn't its default, by its type.
	static function away(property:PropertySchema):String {
		return switch [property.type, property.defaultValue] {
			case [Number(_, _), Number(v)]: Std.string(Std.int(v) + 1);
			case [Text, _]: '"elsewhere"';
			case [Flag, Flag(v)]: v ? "false" : "true";
			case [Numbers(count), _]: "[" + [for (i in 0...count) Std.string(i + 1)].join(", ") + "]";
			case [Color, _]: '"#12345678"';
			case [Reference, _]: '"@n"';
			case _: throw 'The table of ${property.name} has a type its default doesn\'t match';
		}
	}
}
