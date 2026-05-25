extends Control

const BAR_SCREEN_PX := 120.0   # fixed screen pixel width of bar
const BAR_Y         := -10.0

var _camera: CameraController = null

func _ready() -> void:
	custom_minimum_size = Vector2(200, 40)

func _process(_delta: float) -> void:
	if _camera == null:
		_camera = get_tree().get_first_node_in_group("main_camera")
	queue_redraw()

func _draw() -> void:
	if _camera == null:
		return

	# How many AU does BAR_SCREEN_PX represent?
	var au_per_bar := BAR_SCREEN_PX / (_camera.pixels_per_au * _camera.zoom.x)
	var label_str  := _format_distance(au_per_bar)

	# Draw bar
	var y := size.y + BAR_Y
	draw_line(Vector2(0, y), Vector2(BAR_SCREEN_PX, y), Color(1, 1, 1, 0.8), 2.0)
	draw_line(Vector2(0, y - 5), Vector2(0, y + 5), Color(1, 1, 1, 0.8), 2.0)
	draw_line(Vector2(BAR_SCREEN_PX, y - 5), Vector2(BAR_SCREEN_PX, y + 5), Color(1, 1, 1, 0.8), 2.0)

	# Label
	draw_string(ThemeDB.fallback_font, Vector2(BAR_SCREEN_PX * 0.5 - 20, y - 10),
		label_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(1, 1, 1, 0.85))

func _format_distance(au: float) -> String:
	if au < 0.001:
		return "%.0f km" % (au * PhysicsConstants.AU_IN_METERS / 1000.0)
	elif au < 1.0:
		return "%.3f AU" % au
	elif au < 1000.0:
		return "%.1f AU" % au
	elif au < 63241.0:
		return "%.2f ly" % (au / 63241.0)
	else:
		return "%.1f kly" % (au / 63241.0 / 1000.0)
