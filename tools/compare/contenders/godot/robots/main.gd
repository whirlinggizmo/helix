extends Node3D
# N instances of robot.glb, each AnimationPlayer playing Robot_Dance at its own offset (the other contenders' (frame+1+i*5) % 201 at 60 fps).

var count: int = 100
var target: String = "native"
var frame: int = -1
var last: float = 0.0
var done: bool = false
var deltas: PackedFloat64Array = PackedFloat64Array()
var players: Array = []

func read_options() -> void:
	var args: PackedStringArray
	if OS.has_feature("web"):
		target = "page"
		var q: String = str(JavaScriptBridge.eval("location.search", true))
		args = PackedStringArray()
		for part in q.trim_prefix("?").split("&"):
			args.append("--" + part)
	else:
		target = "native-" + RenderingServer.get_current_rendering_method()
		args = OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--count="):
			count = int(a.substr(8))

func _ready() -> void:
	read_options()
	var scene: PackedScene = load("res://robot.glb")
	var cols: int = int(ceil(sqrt(float(count))))
	var w: float = cols * 4.0
	var cam := Camera3D.new()
	cam.fov = 45.0
	add_child(cam)
	cam.position = Vector3(0, 0.9 * w, 0.9 * w)
	cam.look_at_from_position(cam.position, Vector3(0, 1.5, 0), Vector3.UP)
	cam.far = 1000.0
	var light := DirectionalLight3D.new()
	add_child(light)
	light.rotation_degrees = Vector3(-50, 30, 0)
	var verts := 0
	for i in count:
		var r: Node3D = scene.instantiate()
		add_child(r)
		r.position = Vector3(((i % cols) - (cols - 1) / 2.0) * 4.0, 0, (int(i / cols) - (cols - 1) / 2.0) * 4.0)
		var ap: AnimationPlayer = r.find_child("AnimationPlayer", true, false)
		ap.get_animation("Robot_Dance").loop_mode = Animation.LOOP_LINEAR
		ap.play("Robot_Dance")
		ap.seek(fmod((i * 5) / 60.0, ap.get_animation("Robot_Dance").length), true)
		players.append(ap)

func _process(_delta: float) -> void:
	if done:
		return
	var now: float = Time.get_ticks_usec() / 1000.0
	if frame >= 0:
		deltas.append(now - last)
	last = now
	frame += 1
	if deltas.size() == 720:
		var timed: PackedFloat64Array = deltas.slice(120)
		var sum: float = 0.0
		for d in timed:
			sum += d
		var sorted: PackedFloat64Array = timed.duplicate()
		sorted.sort()
		print(JSON.stringify({"contender": "godot-robots", "target": target, "count": count, "mean_ms": sum / 600.0, "p95_ms": sorted[570]}))
		done = true
		get_tree().quit()
