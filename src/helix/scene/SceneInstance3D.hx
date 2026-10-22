package helix.scene;

import haxe.ds.ObjectMap;
import helix.assets.Failure;
import helix.assets.IRequest;
import helix.behavior.Behavior;
import helix.behavior.BehaviorRegistry;
import helix.behavior.BehaviorSchema;
import helix.behavior.BehaviorPass;
import helix.render2d.Font2D;
import helix.render2d.Fonts2D;
import helix.render2d.Texture2D;
import helix.render2d.Textures2D;
import helix.render3d.EnvironmentMap3D;
import helix.render3d.Environments3D;
import helix.render3d.Model3D;
import helix.render3d.ModelFile3D;
import helix.render3d.Models3D;
import helix.render3d.Node3D;
import helix.render3d.Environment3D;
import helix.scene.SceneValue;

/** What instantiating a .scene3d file gives (SceneFile3D.instantiate): its root, a group named after the file under the node it was put in, holding
	every node the file made, the nodes by path, the behaviors it attached, the game's props by node, and whether every load has landed
	(ready). It remembers where each node came from (the file's own entry, a model file by path, a prefab by path) and the values the origin
	gave it, so SceneFile3D.capture writes back a file that instantiates to what the tree is now, a node from a file or a prefab as the
	reference plus what differs. destroy takes it all out again. */
class SceneInstance3D {
	/** The file's path, as it was loaded. */
	public var path(default, null):String;

	/** The node holding everything the file made: a group named after the file (its path without directory and extension), under the
		node it was instantiated in, lit by the file's environment section (its environment). */
	public var root(default, null):Node3D;

	/** The node the file was instantiated in, its root's parent then. */
	public var parent(default, null):Node3D;

	/** The behaviors it attached, in the order the file gave them, prefabs' included. */
	public var behaviors(default, null):Array<Behavior> = [];

	/** Whether every model, prefab, texture, font and environment the file names has landed or failed, and the behaviors are attached to
		the pass: false until then. The ready lambda given to instantiate follows at the pass's next update, once they have started. */
	public var ready(default, null):Bool = false;

	// What was given and what's kept.
	var file:SceneFile3D;
	var pass:BehaviorPass;
	var readyCallback:Null<Void->Void>;
	var waiter:Null<ReadyWaiter>;
	var destroyed = false;
	// Each node the file made, or that a file or a prefab made for it.
	@:allow(helix.scene)
	var records = new ObjectMap<Node3D, NodeRecord3D>();
	// The behaviors attached, each with its node and kind, and whether a prefab attached it (then the prefab's to capture, not this file's).
	@:allow(helix.scene)
	var attached:Array<{
		behavior:Behavior,
		node:Node3D,
		kind:String,
		inherited:Bool
	}> = [];
	// The loads under way, to cancel at destroy, and what landed through the caches, to release then.
	var requests:Array<IRequest> = [];
	var textures:Array<Texture2D> = [];
	var fonts:Array<Font2D> = [];
	var environments:Array<EnvironmentMap3D> = [];

	function new(file:SceneFile3D, path:String, parent:Node3D, behaviors:BehaviorPass, ?ready:Void->Void) {
		this.file = file;
		this.path = path;
		this.parent = parent;
		this.pass = behaviors;
		readyCallback = ready;
		root = new Node3D();
		root.name = baseName(path);
		parent.addChild(root);
	}

	// file, loaded from path, instantiated under parent with its behaviors on behaviors (SceneFile3D.instantiate).

	@:allow(helix.scene)
	static function make(file:SceneFile3D, path:String, parent:Node3D, behaviors:BehaviorPass, ?ready:Void->Void):SceneInstance3D {
		var instance = new SceneInstance3D(file, path, parent, behaviors, ready);
		new SceneBuilder(instance, file, path, instance.root, [path], false, () -> instance.settle()).build();
		return instance;
	}

	/** The file's name without directory and extension: "levels/track.scene3d" gives "track". */
	public static function baseName(path:String):String {
		var name = path.split("/").pop();
		var dot = name.lastIndexOf(".");
		return dot > 0 ? name.substr(0, dot) : name;
	}

	/** The node at path, slash-separated names from the root (never the root's own name), through nodes a file or a prefab made; null for
		none. The first of two siblings named alike. */
	public function node(path:String):Null<Node3D> {
		var at = root;
		for (name in path.split("/")) {
			var next:Null<Node3D> = null;
			for (i in 0...at.childCount) {
				var child = at.getChild(i);
				if (child.name == name) {
					next = child;
					break;
				}
			}
			if (next == null)
				return null;
			at = next;
		}
		return at;
	}

	/** Node's path from the root, as node takes it; null for the root itself or a node not under it. */
	public function pathOf(node:Node3D):Null<String> {
		var names = [], at = node;
		while (at != null && at != root) {
			names.unshift(at.name);
			at = at.parent;
		}
		return at == root && names.length > 0 ? names.join("/") : null;
	}

	/** The game's own values the file gave node ("props"), kept here, never on the node; null for a node the file didn't make. */
	public function props(node:Node3D):Null<Map<String, SceneValue>> {
		var record = records.get(node);
		return record == null ? null : record.props;
	}

	/** Takes it out: its behaviors from the pass (stopping the started ones), its root from the node it was put in, and the textures, fonts and
		environments it loaded released to their caches (the last release frees each). Its model and scene files stay in their caches, which
		keep files until told to forget them. A load still under way is cancelled. */
	public function destroy():Void {
		if (destroyed)
			return;
		destroyed = true;
		for (request in requests)
			request.cancel();
		requests = [];
		for (a in attached)
			pass.remove(a.behavior);
		if (waiter != null)
			pass.remove(waiter);
		root.parent = null;
		for (texture in textures)
			Textures2D.release(texture);
		textures = [];
		for (font in fonts)
			Fonts2D.release(font);
		fonts = [];
		for (environment in environments)
			Environments3D.release(environment);
		environments = [];
	}

	// Keeps a load's request, to cancel at destroy.

	@:allow(helix.scene)
	function holdRequest(request:IRequest):Void
		requests.push(request);

	// Keeps a texture the file loaded, to release at destroy; false, releasing it now, once destroyed.

	@:allow(helix.scene)
	function holdTexture(texture:Texture2D):Bool {
		if (destroyed) {
			Textures2D.release(texture);
			return false;
		}
		textures.push(texture);
		return true;
	}

	// Keeps a font the file loaded through Fonts2D, to release at destroy; false, releasing it now, once destroyed.

	@:allow(helix.scene)
	function holdFont(font:Font2D):Bool {
		if (destroyed) {
			Fonts2D.release(font);
			return false;
		}
		fonts.push(font);
		return true;
	}

	// Keeps an environment the file loaded, to release at destroy; false, releasing it now, once destroyed.

	@:allow(helix.scene)
	function holdEnvironment(environment:EnvironmentMap3D):Bool {
		if (destroyed) {
			Environments3D.release(environment);
			return false;
		}
		environments.push(environment);
		return true;
	}

	// Everything landed and the behaviors attached: ready, and the lambda at the pass's next update.

	@:allow(helix.scene)
	function settle():Void {
		if (destroyed)
			return;
		ready = true;
		if (readyCallback != null) {
			waiter = new ReadyWaiter(readyCallback);
			pass.add(waiter, root);
		}
	}

	// Attaches behavior, made from the entry of kind kind, to node through the pass.

	@:allow(helix.scene)
	function attach(behavior:Behavior, node:Node3D, kind:String, inherited:Bool):Void {
		if (!pass.add(behavior, node))
			return;
		behaviors.push(behavior);
		attached.push({
			behavior: behavior,
			node: node,
			kind: kind,
			inherited: inherited
		});
	}

	// The file that instantiates to what the tree is now (SceneFile3D.capture).

	@:allow(helix.scene)
	function capture():SceneFile3D
		return new SceneCapture(this).capture();
}

/** Where a node of an instance came from. */
enum NodeOrigin3D {
	/** The file's own entry: made from it, or added under a file's or a prefab's node by an override's children. */
	Entry(entry:SceneNode3D);

	/** A model file (a Model3D entry's "file") made it: the file's path and the node's path inside it, from the entry's node. */
	FileNode(file:String, innerPath:String);

	/** A prefab (a "scene" entry) made it: the prefab's path and the node's path inside it, from the entry's node. */
	Prefab(scene:String, innerPath:String);
}

/** What an instance keeps of a node: its origin, the values the origin gave it (its snapshot, taken before any override), the game's
	props, and for an entry with a file or a prefab, whether its overrides have been applied (false while the file loads, or for one that
	failed: its overrides are then kept as written). */
class NodeRecord3D {
	/** The node. */
	public final node:Node3D;

	/** Its kind, as SceneSchema3D's tables name it; null for a class no table has. */
	public final kind:Null<String>;

	/** Where it came from. */
	public var origin:NodeOrigin3D;

	/** The entry's node whose file or prefab made it; null for an entry's own node. */
	public var owner:Null<Node3D>;

	/** The entry it was made from, when one was (a prefab's node keeps its prefab's entry); null for a model file's node. */
	public var entry:Null<SceneNode3D>;

	/** Its values as its origin gave them, before overrides. */
	public var snapshot:NodeSnapshot3D;

	/** The game's own values the file gave it; null for a node a file or a prefab made. */
	public var props:Null<Map<String, SceneValue>>;

	/** For an entry with a file or a prefab: whether its overrides were applied. */
	public var overridesApplied = false;

	/** A record of node from origin with snapshot. */
	public function new(node:Node3D, kind:Null<String>, origin:NodeOrigin3D, snapshot:NodeSnapshot3D) {
		this.node = node;
		this.kind = kind;
		this.origin = origin;
		this.snapshot = snapshot;
	}
}

/** A node's values as a file sees them: its transform, flags, its kind's properties and, for a Model3D, its material and its generated
	mesh. */
class NodeSnapshot3D {
	/** Its position, x, y, z. */
	public var position:Array<Float>;

	/** Its rotation, Euler x, y, z in radians as Node3D reads them back. */
	public var rotation:Array<Float>;

	/** Its scale, x, y, z. */
	public var scale:Array<Float>;

	/** Node.enabled. */
	public var enabled:Bool;

	/** Node.visible. */
	public var visible:Bool;

	/** Node.pickable. */
	public var pickable:Bool;

	/** Its kind's properties by name, those readable. */
	public var properties:Map<String, SceneValue> = new Map();

	/** A Model3D's material as read; null for another kind or a model of no parts. */
	public var material:Null<SceneMaterial3D>;

	/** A Model3D's generated mesh as read from its record (Mesh3D.shape), else the entry's mesh when given; null for another kind or a mesh of
		no record. */
	public var mesh:Null<SceneMesh3D>;

	/** Node's values now: its transform and flags, every property of its kind that reads, and its material. Where read gives nothing yet (a
		texture still loading), entry's value for the property stands in, when given. */
	public function new(node:Node3D, ?entry:SceneNode3D) {
		position = [node.x, node.y, node.z];
		rotation = [node.rotationX, node.rotationY, node.rotationZ];
		scale = [node.scaleX, node.scaleY, node.scaleZ];
		enabled = node.enabled;
		visible = node.visible;
		pickable = node.pickable;
		var kind = SceneKinds3D.kindOf(node);
		var schema = kind == null ? null : SceneSchema3D.kind(kind);
		if (schema != null)
			for (property in schema.properties) {
				var value = SceneKinds3D.read(node, property.name);
				if (value == null && entry != null)
					value = entry.properties.get(property.name);
				if (value != null)
					properties.set(property.name, value);
			}
		var model = Std.downcast(node, Model3D);
		if (model != null) {
			mesh = model.mesh == null ? null : SceneKinds3D.readMesh(model.mesh);
			if (mesh == null && entry != null)
				mesh = entry.mesh;
			material = SceneKinds3D.readMaterial(model);
			if (material != null && entry != null && entry.material != null) {
				if (material.texture == null)
					material.texture = entry.material.texture;
				if (material.normalTexture == null)
					material.normalTexture = entry.material.normalTexture;
			}
		}
	}
}

/** Makes one file's tree for an instance: the top file under the instance's root, a prefab under its node (a nested builder, counting
	its loads toward the one above it). Every node is made at once; a model file or a prefab lands later, when its overrides apply. */
private class SceneBuilder {
	final instance:SceneInstance3D;
	final file:SceneFile3D;
	final path:String;
	// The node this file's nodes go under, and the paths of the files being instantiated above and including this one (a prefab naming one
	// of them is refused).
	final under:Node3D;
	final stack:Array<String>;
	// Whether this file is a prefab: its nodes are then the prefab's to capture, not the instance's own.
	final prefab:Bool;
	final done:Void->Void;
	// Loads outstanding, and whether the synchronous build is still running (so a load landing during it doesn't settle early).
	var pending = 0;
	var building = true;
	// The behaviors to attach once this file's nodes are all made: each entry, its node, the file whose names it resolves against.
	var queued:Array<{entry:SceneBehavior, node:Node3D}> = [];

	/** A builder of file (loaded from path) for instance, its nodes under under; stack holds the paths being instantiated above it and
		its own; prefab says its nodes are a prefab's; done runs once every node is made and every load has landed. */
	public function new(instance:SceneInstance3D, file:SceneFile3D, path:String, under:Node3D, stack:Array<String>, prefab:Bool, done:Void->Void) {
		this.instance = instance;
		this.file = file;
		this.path = path;
		this.under = under;
		this.stack = stack;
		this.prefab = prefab;
		this.done = done;
	}

	/** Makes the tree: the environment section first, on the node the file is made under (the instance's root, a prefab's node), then every
		node at once, the behaviors attached and done called once every load has landed (during this call when there is nothing to wait for). */
	public function build():Void {
		if (file.environment != null)
			applyEnvironment(file.environment);
		for (entry in file.nodes)
			makeNode(entry, under);
		building = false;
		if (pending == 0)
			finish();
	}

	// A problem logged under the instance's path (a prefab's too: what's wrong is where it was instantiated), naming the node by its path
	// from the instance's root.
	function log(nodePath:String, message:String):Void
		Failure.report(instance.path, nodePath == "" ? message : '$nodePath: $message', null);

	// One more load to wait for.
	function wait():Void
		pending++;

	// A load landed (or failed): the last one finishes the file.
	function landed():Void {
		pending--;
		if (pending == 0 && !building)
			finish();
	}

	// Every node made and every load landed: the behaviors attached, then whoever waits told.
	function finish():Void {
		for (q in queued)
			attachBehavior(q.entry, q.node);
		queued = [];
		done();
	}

	// The file's environment section as the light of under, the node it's made under: the ambient light at once, the map and the
	// background once their files land.
	function applyEnvironment(section:SceneEnvironment3D):Void {
		var environment = new Environment3D();
		under.environment = environment;
		if (!environment.setAmbient(section.ambientColor != null ? section.ambientColor : 0xffffffff,
			section.ambientIntensity != null ? section.ambientIntensity : 0))
			log("environment", "ambient refused");
		var intensity = section.mapIntensity != null ? section.mapIntensity : 1.,
			rotation = section.rotation != null ? section.rotation : 0.;
		if (section.mapFile != null) {
			wait();
			var file = section.mapFile;
			instance.holdRequest(Environments3D.load(file, map -> {
				if (instance.holdEnvironment(map) && !environment.setMap(map, intensity, rotation))
					log("environment", "map refused");
				landed();
			}, message -> {
				log("environment", 'map $file: $message');
				landed();
			}));
		} else if (!environment.setMap(null, intensity, rotation))
			log("environment", "map refused");
		var blur = section.backgroundBlur != null ? section.backgroundBlur : 0.;
		if (section.backgroundFile != null) {
			wait();
			var file = section.backgroundFile;
			instance.holdRequest(Environments3D.load(file, map -> {
				if (instance.holdEnvironment(map) && !environment.setBackground(map, blur))
					log("environment", "background refused");
				landed();
			}, message -> {
				log("environment", 'background $file: $message');
				landed();
			}));
		} else if (!environment.setBackground(null, blur))
			log("environment", "background refused");
	}

	// A node from its entry under parent: made, placed, flagged, its properties and material applied, recorded, its children made, its
	// behaviors queued; a file or a prefab asked for. Null for a kind no table has (logged).
	function makeNode(entry:SceneNode3D, parent:Node3D):Null<Node3D> {
		var node:Node3D;
		var nodePath = pathIn(parent, entry.name);
		if (entry.scene != null || entry.file != null)
			node = new Node3D();
		else {
			node = SceneKinds3D.make(entry.kind);
			if (node == null) {
				log(nodePath, 'unknown kind ${entry.kind}');
				return null;
			}
		}
		node.name = entry.name;
		applyTransform(node, entry);
		applyFlags(node, entry);
		if (entry.file == null && entry.scene == null) {
			applyProperties(node, entry, nodePath);
			var model = Std.downcast(node, Model3D);
			if (model != null && entry.mesh != null) {
				var mesh = SceneKinds3D.makeMesh(entry.mesh);
				if (mesh != null)
					model.mesh = mesh;
				else
					log(nodePath, 'mesh ${entry.mesh.shape} refused');
			}
			if (model != null && entry.material != null)
				SceneKinds3D.applyMaterial(model, entry.material, instance);
		}
		parent.addChild(node);
		var record = new NodeRecord3D(node, entry.kind, Entry(entry), new NodeSnapshot3D(node, entry));
		record.entry = entry;
		record.props = entry.props;
		instance.records.set(node, record);
		// A node's behaviors before its children's: the file's order, a node above what's under it.
		for (behavior in entry.behaviors)
			queued.push({entry: behavior, node: node});
		for (child in entry.children)
			makeNode(child, node);
		if (entry.file != null)
			loadModel(entry, node, record);
		else if (entry.scene != null)
			loadPrefab(entry, node, record);
		return node;
	}

	// A node's path from the instance's root, for the log.
	function pathIn(parent:Node3D, name:String):String {
		var names = [name], at = parent;
		while (at != null && at != instance.root) {
			names.unshift(at.name);
			at = at.parent;
		}
		return names.join("/");
	}

	function applyTransform(node:Node3D, entry:SceneNode3D):Void {
		if (entry.position != null)
			node.setPosition(entry.position[0], entry.position[1], entry.position[2]);
		if (entry.rotation != null)
			node.setRotation(entry.rotation[0], entry.rotation[1], entry.rotation[2]);
		if (entry.scale != null)
			node.setScale(entry.scale[0], entry.scale[1], entry.scale[2]);
	}

	// The entry's flags on node: an entry's unsaid flag is its kind's own default (SceneSchema3D's table: a Text3D unpickable, as made in
	// code; a file or a prefab node a plain group's, all true); an override's unsaid flag changes nothing.
	function applyFlags(node:Node3D, entry:SceneNode3D):Void {
		if (entry.isOverride) {
			if (entry.enabled != null)
				node.enabled = entry.enabled;
			if (entry.visible != null)
				node.visible = entry.visible;
			if (entry.pickable != null)
				node.pickable = entry.pickable;
			return;
		}
		var kind = entry.kind == null ? null : SceneSchema3D.kind(entry.kind);
		node.enabled = entry.enabled != null ? entry.enabled : kind == null || kind.enabled;
		node.visible = entry.visible != null ? entry.visible : kind == null || kind.visible;
		node.pickable = entry.pickable != null ? entry.pickable : kind == null || kind.pickable;
	}

	// The entry's properties on node, in its kind's table order (an override's in the table of the node's own kind); one refused is logged.
	function applyProperties(node:Node3D, entry:SceneNode3D, nodePath:String):Void {
		var kind = SceneKinds3D.kindOf(node);
		var schema = kind == null ? null : SceneSchema3D.kind(kind);
		var applied = new Map<String, Bool>();
		if (schema != null)
			for (property in schema.properties) {
				var value = entry.properties.get(property.name);
				if (value == null)
					continue;
				applied.set(property.name, true);
				if (!SceneKinds3D.apply(node, property.name, value, instance))
					log(nodePath, '${property.name} refused');
			}
		for (name in entry.properties.keys())
			if (!applied.exists(name))
				log(nodePath, '$name is not a property of ${kind != null ? kind : "this node"}');
	}

	// The entry's glTF through Models3D: its nodes moved under node when it lands.
	function loadModel(entry:SceneNode3D, node:Node3D, record:NodeRecord3D):Void {
		wait();
		var nodePath = pathIn(node.parent, node.name);
		instance.holdRequest(Models3D.load(entry.file, file -> {
			placeModel(entry, node, record, file, nodePath);
			landed();
		}, message -> {
			log(nodePath, 'model ${entry.file}: $message');
			landed();
		}));
	}

	// The file's nodes under node (the placeholder becomes the file's root), the entry's Model3D properties and material on every model,
	// each node recorded as the file gave it, then the entry's overrides.
	function placeModel(entry:SceneNode3D, node:Node3D, record:NodeRecord3D, file:ModelFile3D, nodePath:String):Void {
		var made = file.instantiate();
		var moved = [for (i in 0...made.childCount) made.getChild(i)];
		for (child in moved)
			node.addChild(child);
		var models = [];
		for (child in moved)
			collect(child, models);
		for (model in models) {
			for (name in ["tint", "shadowCasting", "shadowReceiving"]) {
				var value = entry.properties.get(name);
				if (value != null && !SceneKinds3D.apply(model, name, value, instance))
					log(nodePath, '$name refused');
			}
			if (entry.material != null)
				SceneKinds3D.applyMaterial(model, entry.material, instance);
		}
		for (child in moved)
			recordFrom(child, node, entry.file, true);
		applyOverrides(entry, node, nodePath);
		record.overridesApplied = true;
	}

	// The models at and under node, in drawing order.
	static function collect(node:Node3D, into:Array<Model3D>):Void {
		var model = Std.downcast(node, Model3D);
		if (model != null)
			into.push(model);
		for (i in 0...node.childCount)
			collect(node.getChild(i), into);
	}

	// Records node and everything under it as what a file (isFile) or a prefab at owner made, with its snapshot taken now.
	function recordFrom(node:Node3D, owner:Node3D, source:String, isFile:Bool):Void {
		var inner = pathUnder(node, owner);
		var record = instance.records.get(node);
		if (record == null) {
			record = new NodeRecord3D(node, SceneKinds3D.kindOf(node), isFile ? FileNode(source, inner) : Prefab(source, inner), new NodeSnapshot3D(node));
			instance.records.set(node, record);
		} else {
			record.origin = isFile ? FileNode(source, inner) : Prefab(source, inner);
			record.snapshot = new NodeSnapshot3D(node, record.entry);
			record.props = null;
		}
		record.owner = owner;
		for (i in 0...node.childCount)
			recordFrom(node.getChild(i), owner, source, isFile);
	}

	// node's path from owner, slash-separated names.
	static function pathUnder(node:Node3D, owner:Node3D):String {
		var names = [], at = node;
		while (at != null && at != owner) {
			names.unshift(at.name);
			at = at.parent;
		}
		return names.join("/");
	}

	// The entry's prefab through SceneFiles3D: instantiated under node when it lands, by a builder of its own, then the entry's overrides.
	function loadPrefab(entry:SceneNode3D, node:Node3D, record:NodeRecord3D):Void {
		wait();
		var nodePath = pathIn(node.parent, node.name);
		if (stack.indexOf(entry.scene) >= 0) {
			log(nodePath, 'prefab ${entry.scene} names itself, through ${stack.join(" > ")}');
			landed();
			return;
		}
		instance.holdRequest(SceneFiles3D.load(entry.scene, file -> {
			var inner = new SceneBuilder(instance, file, entry.scene, node, stack.concat([entry.scene]), true, () -> {
				for (i in 0...node.childCount)
					recordFrom(node.getChild(i), node, entry.scene, false);
				applyOverrides(entry, node, nodePath);
				record.overridesApplied = true;
				landed();
			});
			inner.build();
		}, message -> {
			log(nodePath, 'prefab ${entry.scene}: $message');
			landed();
		}));
	}

	// The entry's overrides by path from node: each on the node it names (one naming none is logged and skipped).
	function applyOverrides(entry:SceneNode3D, node:Node3D, nodePath:String):Void {
		for (path in entry.overrides.keys()) {
			var target = find(node, path);
			var targetPath = '$nodePath/$path';
			if (target == null) {
				log(targetPath, "an override names no node");
				continue;
			}
			var changes = entry.overrides.get(path);
			applyTransform(target, changes);
			applyFlags(target, changes);
			applyProperties(target, changes, targetPath);
			var model = Std.downcast(target, Model3D);
			if (changes.material != null) {
				if (model != null)
					SceneKinds3D.applyMaterial(model, changes.material, instance);
				else
					log(targetPath, "a material belongs to a Model3D");
			}
			for (behavior in changes.behaviors)
				queued.push({entry: behavior, node: target});
			for (child in changes.children)
				makeNode(child, target);
		}
	}

	// The node at path, slash-separated names, under from; null for none.
	static function find(from:Node3D, path:String):Null<Node3D> {
		var at = from;
		for (name in path.split("/")) {
			var next:Null<Node3D> = null;
			for (i in 0...at.childCount)
				if (at.getChild(i).name == name) {
					next = at.getChild(i);
					break;
				}
			if (next == null)
				return null;
			at = next;
		}
		return at;
	}

	// A behavior from its entry on node: made by the registry, each prop set from the file's value (a reference resolved to a node), then
	// attached through the instance. An unknown kind, or a prop refused, is logged.
	function attachBehavior(entry:SceneBehavior, node:Node3D):Void {
		var nodePath = pathIn(node.parent, node.name);
		var registered = BehaviorRegistry.find(entry.kind);
		if (registered == null) {
			log(nodePath, 'behavior ${entry.kind} is not registered');
			return;
		}
		var behavior = registered.make();
		for (name in entry.props.keys()) {
			var prop = propNamed(registered.schema, name);
			var value = entry.props.get(name);
			if (prop == null) {
				log(nodePath, '${entry.kind}.$name is not a prop');
				continue;
			}
			var converted:Dynamic = switch [prop.type, value] {
				case [IntProp, Number(v)]: Std.int(v);
				case [FloatProp, Number(v)]: v;
				case [BoolProp, Flag(f)]: f;
				case [StringProp, Text(t)]: t;
				case [FloatsProp, Numbers(list)]: list.copy();
				case [ColorProp, Color(c)]: c;
				case [ColorProp, Number(v)]: Std.int(v);
				case [NodeProp, Reference(target)]:
					var found = resolve(target);
					if (found == null)
						log(nodePath, '${entry.kind}.$name: @$target names no node');
					found;
				case _:
					log(nodePath, '${entry.kind}.$name: a value of the wrong shape');
					continue;
			}
			if (!registered.setProp(behavior, name, converted))
				log(nodePath, '${entry.kind}.$name refused');
		}
		instance.attach(behavior, node, entry.kind, prefab);
	}

	static function propNamed(schema:BehaviorSchema, name:String):Null<BehaviorProp> {
		for (prop in schema.props)
			if (prop.name == name)
				return prop;
		return null;
	}

	// A reference's node: by name among this file's nodes (two of that name logged, the first taken), then as a path from this file's top;
	// for a prefab, then the same over the whole instance.
	function resolve(target:String):Null<Node3D> {
		var found = byName(under, target);
		if (found == null)
			found = find(under, target);
		if (found == null && prefab) {
			found = byName(instance.root, target);
			if (found == null)
				found = find(instance.root, target);
		}
		return found;
	}

	// The one node named name under top (depth first); two logged, the first taken.
	function byName(top:Node3D, name:String):Null<Node3D> {
		var found = [];
		collectNamed(top, name, found);
		if (found.length > 1)
			log("", '@$name names ${found.length} nodes; the first is taken');
		return found.length > 0 ? found[0] : null;
	}

	static function collectNamed(node:Node3D, name:String, into:Array<Node3D>):Void {
		for (i in 0...node.childCount) {
			var child = node.getChild(i);
			if (child.name == name)
				into.push(child);
			collectNamed(child, name, into);
		}
	}
}

/** The behavior that tells an instance's ready lambda: added to the pass after the file's behaviors once everything landed, so its start,
	at the pass's next update, comes after theirs; done at once. Made with an argument, so the registry doesn't list it. */
private class ReadyWaiter extends Behavior {
	final ready:Void->Void;

	/** Tells ready when it starts. */
	public function new(ready:Void->Void) {
		super();
		this.ready = ready;
	}

	override public function start():Void {
		done = true;
		ready();
	}
}

/** Writes an instance back as a file: the environment from its root's, each of the instance's own nodes from the live node, a node from a file
	or a prefab as the reference plus an override for every node under it whose values differ from what the file or prefab gave, and a
	node a game added as its class with its properties. */
private class SceneCapture {
	final instance:SceneInstance3D;
	final file = new SceneFile3D();
	// Names used more than once in the instance: a reference to such a node is written as its path.
	var names = new Map<String, Int>();
	var warnedCodeModel = false;

	/** A capture of instance. */
	public function new(instance:SceneInstance3D)
		this.instance = instance;

	/** The file that instantiates to what the instance is now. */
	public function capture():SceneFile3D {
		countNames(instance.root);
		file.environment = captureEnvironment(instance.root.environment);
		for (i in 0...instance.root.childCount) {
			var entry = captureNode(instance.root.getChild(i));
			if (entry != null)
				file.nodes.push(entry);
		}
		return file;
	}

	function countNames(node:Node3D):Void {
		for (i in 0...node.childCount) {
			var child = node.getChild(i);
			names.set(child.name, (names.exists(child.name) ? names.get(child.name) : 0) + 1);
			countNames(child);
		}
	}

	// The environment's values that aren't the defaults; null for no environment, or one that's all defaults.
	function captureEnvironment(environment:Null<Environment3D>):Null<SceneEnvironment3D> {
		if (environment == null)
			return null;
		var section = new SceneEnvironment3D(), any = false;
		if (environment.ambientColor != 0xffffffff || environment.ambientIntensity != 0) {
			section.ambientColor = environment.ambientColor;
			section.ambientIntensity = environment.ambientIntensity;
			any = true;
		}
		if (environment.map != null) {
			section.mapFile = environment.map.path;
			any = true;
		}
		if (environment.mapIntensity != 1) {
			section.mapIntensity = environment.mapIntensity;
			any = true;
		}
		if (environment.rotation != 0) {
			section.rotation = environment.rotation;
			any = true;
		}
		if (environment.background != null) {
			section.backgroundFile = environment.background.path;
			any = true;
		}
		if (environment.backgroundBlur != 0) {
			section.backgroundBlur = environment.backgroundBlur;
			any = true;
		}
		return any ? section : null;
	}

	// node as an entry: from its record when the file made it, else from its class.
	function captureNode(node:Node3D):Null<SceneNode3D> {
		var record = instance.records.get(node);
		var source = record == null ? null : switch record.origin {
			case Entry(entry): entry;
			case _: null;
		}
		if (source != null && (source.file != null || source.scene != null))
			return captureReference(node, record, source);
		var entry = new SceneNode3D();
		entry.name = node.name;
		if (source != null)
			entry.kind = source.kind;
		else {
			entry.kind = SceneKinds3D.kindOf(node);
			if (entry.kind == null) {
				Failure.report(instance.path, '${instance.pathOf(node)}: a node of a class no table has is left out', null);
				return null;
			}
		}
		var model = Std.downcast(node, Model3D);
		if (model != null && model.mesh != null) {
			entry.mesh = SceneKinds3D.readMesh(model.mesh);
			// The file's own mesh entry while the mesh is still what it made, so an untouched one is written as it was.
			if (entry.mesh != null
				&& source != null
				&& source.mesh != null
				&& record != null
				&& sameMesh(entry.mesh, record.snapshot.mesh))
				entry.mesh = source.mesh;
			if (entry.mesh == null && source == null && !warnedCodeModel) {
				warnedCodeModel = true;
				Failure.report(instance.path,
					'${instance.pathOf(node)}: a Model3D whose mesh has no record of what made it has no file or mesh; it loads back as an empty Model3D',
					null);
			}
		}
		writeTransform(entry, node);
		writeFlags(entry, node);
		var schema = SceneSchema3D.kind(entry.kind);
		if (schema != null)
			for (property in schema.properties) {
				var value = SceneKinds3D.read(node, property.name);
				if (value == null && record != null)
					value = record.snapshot.properties.get(property.name);
				if (value != null)
					entry.properties.set(property.name, value);
			}
		if (model != null && (source == null || source.material != null)) {
			var material = SceneKinds3D.readMaterial(model);
			if (material != null) {
				if (record != null)
					fillTextures(material, record.snapshot.material);
				entry.material = diffMaterial(material, null);
			}
		}
		for (i in 0...node.childCount) {
			var child = captureNode(node.getChild(i));
			if (child != null)
				entry.children.push(child);
		}
		entry.behaviors = captureBehaviors(node);
		if (record != null && record.props != null)
			entry.props = record.props;
		return entry;
	}

	// An entry with a file or a prefab: the reference, its own values from the entry, its live transform and flags, then the overrides:
	// as written while the file hasn't landed, else one for each node under it that differs from what the file gave; the nodes added
	// under its own node are its children.
	function captureReference(node:Node3D, record:NodeRecord3D, source:SceneNode3D):SceneNode3D {
		var entry = new SceneNode3D();
		entry.name = node.name;
		entry.kind = source.kind;
		entry.scene = source.scene;
		entry.file = source.file;
		writeTransform(entry, node);
		writeFlags(entry, node);
		for (name in source.properties.keys())
			entry.properties.set(name, source.properties.get(name));
		entry.material = source.material;
		if (record.props != null)
			entry.props = record.props;
		entry.behaviors = captureBehaviors(node);
		if (!record.overridesApplied) {
			for (path in source.overrides.keys())
				entry.overrides.set(path, source.overrides.get(path));
			for (i in 0...node.childCount) {
				var child = captureNode(node.getChild(i));
				if (child != null)
					entry.children.push(child);
			}
			return entry;
		}
		for (i in 0...node.childCount)
			captureUnder(node.getChild(i), node, entry);
		return entry;
	}

	// A node under a reference node: one the file or prefab made becomes an override where it differs, and its own children go on; any
	// other is a child added under owner (at its top) or under the file's node (in that node's override).
	function captureUnder(node:Node3D, owner:Node3D, reference:SceneNode3D):Void {
		var record = instance.records.get(node);
		var fromSource = record != null && record.owner == owner && switch record.origin {
			case Entry(_): false;
			case _: true;
		} if (!fromSource) {
			var child = captureNode(node);
			if (child == null)
				return;
			var parent = instance.records.get(node.parent);
			if (node.parent == owner || parent == null || parent.owner != owner)
				reference.children.push(child);
			else
				overrideFor(reference, innerPath(node.parent, owner)).children.push(child);
			return;
	}
		var changes = diff(node, record);
		var behaviors = captureBehaviors(node);
		if (behaviors.length > 0) {
			if (changes == null)
				changes = new SceneNode3D();
			changes.behaviors = behaviors;
		}
		if (changes != null) {
			var at = overrideFor(reference, innerPath(node, owner));
			merge(at, changes);
		}
		for (i in 0...node.childCount)
			captureUnder(node.getChild(i), owner, reference);
	}

	// The override at path on reference, made when there is none yet.
	function overrideFor(reference:SceneNode3D, path:String):SceneNode3D {
		var found = reference.overrides.get(path);
		if (found == null) {
			found = new SceneNode3D();
			reference.overrides.set(path, found);
		}
		return found;
	}

	// from's values onto into (an override made for added children before its node's diff was taken).
	static function merge(into:SceneNode3D, from:SceneNode3D):Void {
		into.position = from.position;
		into.rotation = from.rotation;
		into.scale = from.scale;
		into.enabled = from.enabled;
		into.visible = from.visible;
		into.pickable = from.pickable;
		for (name in from.properties.keys())
			into.properties.set(name, from.properties.get(name));
		into.material = from.material;
		into.behaviors = from.behaviors;
		into.children = into.children.concat(from.children);
	}

	static function innerPath(node:Node3D, owner:Node3D):String {
		var names = [], at = node;
		while (at != null && at != owner) {
			names.unshift(at.name);
			at = at.parent;
		}
		return names.join("/");
	}

	// What differs on node from its snapshot, as an override; null for nothing.
	function diff(node:Node3D, record:NodeRecord3D):Null<SceneNode3D> {
		var snapshot = record.snapshot, changes = new SceneNode3D(), any = false;
		var position = [node.x, node.y, node.z],
			rotation = [node.rotationX, node.rotationY, node.rotationZ],
			scale = [node.scaleX, node.scaleY, node.scaleZ];
		if (!sameNumbers(position, snapshot.position)) {
			changes.position = position;
			any = true;
		}
		if (!sameNumbers(rotation, snapshot.rotation)) {
			changes.rotation = rotation;
			any = true;
		}
		if (!sameNumbers(scale, snapshot.scale)) {
			changes.scale = scale;
			any = true;
		}
		if (node.enabled != snapshot.enabled) {
			changes.enabled = node.enabled;
			any = true;
		}
		if (node.visible != snapshot.visible) {
			changes.visible = node.visible;
			any = true;
		}
		if (node.pickable != snapshot.pickable) {
			changes.pickable = node.pickable;
			any = true;
		}
		var schema = record.kind == null ? null : SceneSchema3D.kind(record.kind);
		if (schema != null)
			for (property in schema.properties) {
				var value = SceneKinds3D.read(node, property.name);
				if (value == null)
					continue;
				var was = snapshot.properties.get(property.name);
				if (was == null || !same(value, was)) {
					changes.properties.set(property.name, value);
					any = true;
				}
			}
		var model = Std.downcast(node, Model3D);
		if (model != null) {
			var material = SceneKinds3D.readMaterial(model);
			if (material != null) {
				fillTextures(material, snapshot.material);
				var changed = diffMaterial(material, snapshot.material);
				if (changed != null) {
					changes.material = changed;
					any = true;
				}
			}
		}
		return any ? changes : null;
	}

	// A texture that can't be read now (not yet loaded) is taken as the snapshot's, so a load under way isn't a change.
	static function fillTextures(material:SceneMaterial3D, snapshot:Null<SceneMaterial3D>):Void {
		if (snapshot == null)
			return;
		if (material.texture == null)
			material.texture = snapshot.texture;
		if (material.normalTexture == null)
			material.normalTexture = snapshot.normalTexture;
	}

	// What differs in material from base (Material3D's defaults for null); null for nothing.
	static function diffMaterial(material:SceneMaterial3D, base:Null<SceneMaterial3D>):Null<SceneMaterial3D> {
		if (base == null) {
			base = new SceneMaterial3D();
			base.baseColor = 0xffffffff;
			base.metallic = 0;
			base.roughness = .5;
			base.normalScale = 1;
			base.emissive = 0xff000000;
			base.emissiveStrength = 1;
			base.doubleSided = false;
		}
		var changed = new SceneMaterial3D(), any = false;
		if (material.baseColor != base.baseColor) {
			changed.baseColor = material.baseColor;
			any = true;
		}
		if (material.metallic != base.metallic) {
			changed.metallic = material.metallic;
			any = true;
		}
		if (material.roughness != base.roughness) {
			changed.roughness = material.roughness;
			any = true;
		}
		if (material.texture != base.texture) {
			changed.texture = material.texture;
			any = true;
		}
		if (material.normalTexture != base.normalTexture) {
			changed.normalTexture = material.normalTexture;
			any = true;
		}
		if (material.normalScale != base.normalScale) {
			changed.normalScale = material.normalScale;
			any = true;
		}
		if (material.emissive != base.emissive) {
			changed.emissive = material.emissive;
			any = true;
		}
		if (material.emissiveStrength != base.emissiveStrength) {
			changed.emissiveStrength = material.emissiveStrength;
			any = true;
		}
		if (material.doubleSided != base.doubleSided) {
			changed.doubleSided = material.doubleSided;
			any = true;
		}
		return any ? changed : null;
	}

	// The behaviors this file attached to node (a prefab's own are the prefab's), each with the props away from its schema's defaults.
	function captureBehaviors(node:Node3D):Array<SceneBehavior> {
		var written = [];
		for (a in instance.attached) {
			if (a.node != node || a.inherited)
				continue;
			var registered = BehaviorRegistry.find(a.kind);
			var entry = new SceneBehavior(a.kind);
			if (registered != null)
				for (prop in registered.schema.props) {
					var value:Dynamic = registered.getProp(a.behavior, prop.name);
					var converted = convert(prop, value);
					if (converted != null && !sameDynamic(prop, value, prop.value))
						entry.props.set(prop.name, converted);
				}
			written.push(entry);
		}
		return written;
	}

	// node's flags as they are, each said: the writer leaves out one at the kind's own default (a Text3D's pickable false).
	static function writeFlags(entry:SceneNode3D, node:Node3D):Void {
		entry.enabled = node.enabled;
		entry.visible = node.visible;
		entry.pickable = node.pickable;
	}

	// A prop's value as a file's; null for one the file can't say (a reference to no node, or to one outside the instance).
	function convert(prop:BehaviorProp, value:Dynamic):Null<SceneValue> {
		return switch prop.type {
			case IntProp | FloatProp: Number(value);
			case BoolProp: Flag(value);
			case StringProp: Text(value);
			case FloatsProp: Numbers((value : Array<Float>).copy());
			case ColorProp: Color(value);
			case NodeProp:
				if (value == null) null; else {
					var node:Node3D = value, path = instance.pathOf(node);
					path == null ? null : Reference(names.get(node.name) == 1 ? node.name : path);
				}
		}
	}

	static function sameDynamic(prop:BehaviorProp, a:Dynamic, b:Dynamic):Bool {
		return switch prop.type {
			case FloatsProp:
				if (a == null || b == null) a == b; else sameNumbers(a, b);
			case _: a == b;
		}
	}

	// Whether two mesh entries name one shape with the same arguments, an unsaid one at the generator's default.
	static function sameMesh(a:SceneMesh3D, b:Null<SceneMesh3D>):Bool {
		if (b == null || a.shape != b.shape)
			return false;
		var schema = SceneSchema3D.shape(a.shape);
		if (schema == null)
			return false;
		for (argument in schema.arguments) {
			var x = a.arguments.exists(argument.name) ? a.arguments.get(argument.name) : argument.defaultValue,
				y = b.arguments.exists(argument.name) ? b.arguments.get(argument.name) : argument.defaultValue;
			if (x != y)
				return false;
		}
		return true;
	}

	static function same(a:SceneValue, b:SceneValue):Bool
		return switch [a, b] {
			case [Numbers(x), Numbers(y)]: sameNumbers(x, y);
			case _: a.equals(b);
		}

	static function sameNumbers(a:Array<Float>, b:Array<Float>):Bool {
		if (a.length != b.length)
			return false;
		for (i in 0...a.length)
			if (a[i] != b[i])
				return false;
		return true;
	}

	static function writeTransform(entry:SceneNode3D, node:Node3D):Void {
		entry.position = [node.x, node.y, node.z];
		entry.rotation = [node.rotationX, node.rotationY, node.rotationZ];
		entry.scale = [node.scaleX, node.scaleY, node.scaleZ];
	}
}
