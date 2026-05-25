class_name CameraController
extends Camera2D

# Zoom range: AU per screen pixel (inverse of visual zoom)
const ZOOM_MIN   := 0.0001   # very zoomed in (planet surface)
const ZOOM_MAX   := 5000.0   # galaxy scale
const ZOOM_SPEED := 0.15

var _dragging:    bool    = false
var _drag_start:  Vector2 = Vector2.ZERO
var _cam_start:   Vector2 = Vector2.ZERO
var zoom_au_per_px: float = 1.0   # AU per screen pixel; used by scale indicator

func _ready() -> void:
	zoom = Vector2.ONE
	position = Vector2.ZERO

func _process(delta: float) -> void:
	if GameState.camera_follow_id >= 0:
		var body := UniverseManager.get_body(GameState.camera_follow_id)
		if body:
			# Smooth follow
			var target_screen := au_to_screen(body.position)
			position = lerp(position, target_screen, 10.0 * delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_scroll(event)
	elif event is InputEventMouseMotion:
		_handle_drag(event)

func _handle_scroll(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		_zoom_by(-ZOOM_SPEED, event.position)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		_zoom_by(ZOOM_SPEED, event.position)
	elif event.button_index == MOUSE_BUTTON_MIDDLE:
		_dragging = event.pressed
		_drag_start = event.position
		_cam_start  = position
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			# Stop following on right click drag start
			GameState.camera_follow_id = -1

func _handle_drag(event: InputEventMouseMotion) -> void:
	if _dragging:
		var delta := event.position - _drag_start
		position = _cam_start - delta / zoom.x

func _zoom_by(factor: float, pivot_screen: Vector2) -> void:
	var old_zoom := zoom.x
	var new_zoom := clamp(old_zoom * (1.0 - factor), 0.001, 1000.0)

	# Zoom toward mouse cursor
	var world_before := (pivot_screen - get_viewport().get_visible_rect().size * 0.5) / old_zoom + position
	zoom = Vector2(new_zoom, new_zoom)
	var world_after := (pivot_screen - get_viewport().get_visible_rect().size * 0.5) / new_zoom + position
	position += world_before - world_after

	zoom_au_per_px = 1.0 / new_zoom

# -------------------------------------------------------
# Coordinate conversion: simulation AU ↔ screen pixels
# sim_to_screen: multiplied by pixels_per_au
# -------------------------------------------------------
var pixels_per_au: float = 200.0  # at zoom 1×: 200 px = 1 AU

func au_to_screen(pos_au: Vector2) -> Vector2:
	return pos_au * pixels_per_au

func screen_to_au(screen_pos: Vector2) -> Vector2:
	var world := (screen_pos - get_viewport().get_visible_rect().size * 0.5) / zoom.x + position
	return world / pixels_per_au

func center_on_body(id: int) -> void:
	GameState.camera_follow_id = id

func focus_all() -> void:
	GameState.camera_follow_id = -1
	var bodies := UniverseManager.get_all_bodies()
	if bodies.is_empty():
		return
	var positions := bodies.map(func(b): return au_to_screen(b.position))
	var bbox := VectorMath.bounding_box(positions)
	position = bbox.get_center()
	var vp := get_viewport().get_visible_rect().size
	var scale_x := vp.x / max(bbox.size.x, 1.0) * 0.8
	var scale_y := vp.y / max(bbox.size.y, 1.0) * 0.8
	zoom = Vector2.ONE * min(scale_x, scale_y)
