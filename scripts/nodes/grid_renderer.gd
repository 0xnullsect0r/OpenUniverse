class_name GridRenderer
extends Node2D

func _ready() -> void:
	z_index = -50   # behind bodies, in front of stars

func _process(_d: float) -> void:
	if GameState.show_grid:
		queue_redraw()

func _draw() -> void:
	if not GameState.show_grid:
		return
	var cam := get_viewport().get_camera_2d() as CameraController
	if cam == null:
		return

	var zoom    := cam.zoom.x
	var ppau    := cam.pixels_per_au
	var vp      := get_viewport_rect().size
	var cam_pos := cam.position

	var au_visible := vp.x / (ppau * zoom)
	var grid_au    := _pick_spacing(au_visible)
	var grid_px    := grid_au * ppau

	var half    := vp / (2.0 * zoom)
	var x_start := floor((cam_pos.x - half.x) / grid_px) * grid_px
	var y_start := floor((cam_pos.y - half.y) / grid_px) * grid_px
	var x_end   := cam_pos.x + half.x + grid_px
	var y_end   := cam_pos.y + half.y + grid_px
	var line_w  := 1.0 / zoom

	var col_minor := Color(0.30, 0.40, 0.60, 0.12)
	var col_major := Color(0.45, 0.55, 0.80, 0.28)

	var x := x_start
	while x <= x_end:
		var c := col_major if abs(x) < grid_px * 0.5 else col_minor
		draw_line(Vector2(x, y_start), Vector2(x, y_end), c, line_w)
		x += grid_px

	var y := y_start
	while y <= y_end:
		var c := col_major if abs(y) < grid_px * 0.5 else col_minor
		draw_line(Vector2(x_start, y), Vector2(x_end, y), c, line_w)
		y += grid_px

func _pick_spacing(au_visible: float) -> float:
	for s in [1000.0, 500.0, 200.0, 100.0, 50.0, 10.0, 5.0, 1.0, 0.5, 0.1, 0.05, 0.01]:
		if au_visible / s < 20.0:
			return s
	return 0.01
