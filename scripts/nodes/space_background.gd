class_name SpaceBackground
extends Node2D

const STAR_COUNT    := 2000
const WORLD_EXTENT  := 60000.0   # star field spans ±60k world-px
const NEBULA_COUNT  := 6

var _stars:  Array = []
var _nebulae: Array = []

func _ready() -> void:
	z_index = -100
	var rng := RandomNumberGenerator.new()
	rng.seed = 42

	for i in STAR_COUNT:
		_stars.append({
			"pos": Vector2(rng.randf_range(-WORLD_EXTENT, WORLD_EXTENT),
			               rng.randf_range(-WORLD_EXTENT, WORLD_EXTENT)),
			"r":   rng.randf_range(0.5, 1.8),
			"col": Color(rng.randf_range(0.85, 1.0),
			             rng.randf_range(0.85, 1.0),
			             1.0,
			             rng.randf_range(0.45, 1.0))
		})

	var nebula_colors := [
		Color(0.4, 0.2, 0.8, 0.025),   # violet
		Color(0.1, 0.4, 0.9, 0.020),   # blue
		Color(0.8, 0.3, 0.1, 0.018),   # orange-red
		Color(0.2, 0.7, 0.5, 0.022),   # teal
		Color(0.9, 0.6, 0.1, 0.015),   # amber
		Color(0.5, 0.1, 0.5, 0.020),   # purple
	]
	for i in NEBULA_COUNT:
		_nebulae.append({
			"pos": Vector2(rng.randf_range(-WORLD_EXTENT * 0.5, WORLD_EXTENT * 0.5),
			               rng.randf_range(-WORLD_EXTENT * 0.5, WORLD_EXTENT * 0.5)),
			"r":   rng.randf_range(3000.0, 8000.0),
			"col": nebula_colors[i % nebula_colors.size()]
		})

func _process(_d: float) -> void:
	queue_redraw()

func _draw() -> void:
	var cam: Camera2D = get_viewport().get_camera_2d()
	var cam_pos := cam.position if cam else Vector2.ZERO
	var zoom    := cam.zoom.x   if cam else 1.0
	var vp_size := get_viewport_rect().size

	# Solid background rectangle sized to cover viewport in world coords
	var half := vp_size / (2.0 * zoom)
	draw_rect(Rect2(cam_pos - half, half * 2.0), Color(0.01, 0.01, 0.035))

	# Nebula clouds (faint, drawn before stars)
	for n in _nebulae:
		draw_circle(n["pos"], n["r"], n["col"])

	# Background stars (scroll naturally with camera)
	for s in _stars:
		draw_circle(s["pos"], s["r"] / zoom, s["col"])
