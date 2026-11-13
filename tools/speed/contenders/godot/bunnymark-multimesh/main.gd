extends Node2D
# raylib's textures_bunnymark in Godot's fast path: one MultiMeshInstance2D, its instance buffer rewritten each frame.

const STRIDE := 12  # a 2D transform (8 floats) and a color (4 floats) per instance
var tex: Texture2D = preload("res://wabbit_alpha.png")
var mm := MultiMesh.new()
var mmi := MultiMeshInstance2D.new()
var pos: PackedVector2Array = PackedVector2Array()
var speeds: PackedVector2Array = PackedVector2Array()
var colors: PackedColorArray = PackedColorArray()
var buf: PackedFloat32Array = PackedFloat32Array()

var rng_state: int = 2463534242
var count: int = 1000
var ramp: bool = false
var increment_count: int = 0
var start_count: int = 0
var shot: String = ""
var target: String = "native"
var frame: int = -1
var last: float = 0.0
var window_start: float = 0.0
var first_frame_ms: float = 0.0
var max_count: int = 0
var done: bool = false
var deltas: PackedFloat64Array = PackedFloat64Array()

# xorshift32, the same in every contender, so every bunny starts the same.
func rnd(lo: int, hi: int) -> int:
	var x: int = rng_state
	x = (x ^ (x << 13)) & 0xFFFFFFFF
	x = x ^ (x >> 17)
	x = (x ^ (x << 5)) & 0xFFFFFFFF
	rng_state = x
	return lo + (x >> 8) % (hi - lo + 1)

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
		elif a.begins_with("--incrementCount="):
			increment_count = int(a.substr(17))
			ramp = increment_count > 0
		elif a.begins_with("--startCount="):
			start_count = int(a.substr(13))
		elif a.begins_with("--shot="):
			shot = a.substr(7)
	# incrementCount=N adds N bunnies each 60 frames, from startCount=M bunnies (N without it).
	if ramp:
		count = start_count if start_count > 0 else increment_count

func wall_ms() -> float:
	if OS.has_feature("web"):
		return float(JavaScriptBridge.eval("performance.now()", true))
	return Time.get_unix_time_from_system() * 1000.0

func mark_first_frame() -> void:
	await RenderingServer.frame_post_draw
	first_frame_ms = wall_ms()
	if shot != "":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(shot)

# Called at the start of each frame; returns false once the run is over.
func tick(contender: String, n: int) -> void:
	var now: float = Time.get_ticks_usec() / 1000.0
	if frame >= 0:
		deltas.append(now - last)
	last = now
	frame += 1
	if frame == 0:
		mark_first_frame()
	var nd: int = deltas.size()
	if not ramp:
		if nd == 720:
			var timed: PackedFloat64Array = deltas.slice(120)
			var sum: float = 0.0
			for d in timed:
				sum += d
			var sorted: PackedFloat64Array = timed.duplicate()
			sorted.sort()
			var mean: float = sum / 600.0
			print(JSON.stringify({"contender": contender, "target": target, "mode": "count", "count": count, "mean_ms": mean, "median_ms": sorted[300], "p95_ms": sorted[570], "fps": 1000.0 / mean, "first_frame_ms": first_frame_ms}))
			done = true
	elif nd >= 120 and (nd - 120) % 60 == 0:
		if nd > 120:
			var fps: float = 60.0 * 1000.0 / (now - window_start)
			if fps >= 59.0 and n < 2000000:
				max_count = n
				spawn(increment_count)
			else:
				print(JSON.stringify({"contender": contender, "target": target, "mode": "ramp", "max_count": max_count, "last_fps": fps, "first_frame_ms": first_frame_ms}))
				done = true
		window_start = now
	if done:
		get_tree().quit()

func spawn(n: int) -> void:
	for i in n:
		var px: int = rnd(0, 800 - 32)
		var py: int = rnd(40, 450 - 32)
		var sx: float = rnd(-250, 250) / 60.0
		var sy: float = rnd(-250, 250) / 60.0
		var r: int = rnd(50, 240)
		var g: int = rnd(80, 240)
		var b: int = rnd(100, 240)
		pos.append(Vector2(px, py))
		speeds.append(Vector2(sx, sy))
		colors.append(Color8(r, g, b, 255))
	var total: int = pos.size()
	mm.instance_count = total
	buf.resize(total * STRIDE)
	for i in total:
		var o: int = i * STRIDE
		var c: Color = colors[i]
		# Transform2D rows: (x.x, y.x, 0, origin.x), (x.y, y.y, 0, origin.y); the quad's y flipped, as a 3D mesh is y-up.
		buf[o] = 1.0; buf[o + 1] = 0.0; buf[o + 2] = 0.0
		buf[o + 4] = 0.0; buf[o + 5] = -1.0; buf[o + 6] = 0.0
		buf[o + 8] = c.r; buf[o + 9] = c.g; buf[o + 10] = c.b; buf[o + 11] = c.a

func _ready() -> void:
	read_options()
	var quad := QuadMesh.new()
	quad.size = Vector2(32, 32)
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.use_colors = true
	mm.mesh = quad
	mmi.multimesh = mm
	mmi.texture = tex
	add_child(mmi)
	spawn(count)

func _process(_delta: float) -> void:
	if done:
		return
	var w: float = tex.get_width()
	var h: float = tex.get_height()
	var size: Vector2 = get_viewport_rect().size
	var n: int = pos.size()
	for i in n:
		var p: Vector2 = pos[i]
		var v: Vector2 = speeds[i]
		p += v
		if p.x + w / 2 > size.x or p.x + w / 2 < 0:
			v.x *= -1
		if p.y + h / 2 > size.y or p.y + h / 2 - 40 < 0:
			v.y *= -1
		pos[i] = p
		speeds[i] = v
		var o: int = i * STRIDE
		buf[o + 3] = p.x + 16.0
		buf[o + 7] = p.y + 16.0
	mm.buffer = buf
	tick("godot-multimesh", n)
