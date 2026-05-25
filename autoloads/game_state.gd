extends Node

# -------------------------------------------------------
# Tool selection
# -------------------------------------------------------
enum Tool { SELECT, LASER_HEAT, LASER_COOL, PUSH, PULL }
var active_tool: int = Tool.SELECT

# -------------------------------------------------------
# Time control
# -------------------------------------------------------
var is_paused: bool = false:
	set(value):
		is_paused = value
		if value:
			EventBus.simulation_paused.emit()
		else:
			EventBus.simulation_resumed.emit()

var time_multiplier: float = 1.0:
	set(value):
		time_multiplier = value
		EventBus.time_speed_changed.emit(value)

var simulation_time: float = 0.0
var step_one_frame:  bool  = false  # step a single physics tick then re-pause

# -------------------------------------------------------
# Selection
# -------------------------------------------------------
var selected_body_id: int = -1:
	set(value):
		selected_body_id = value
		if value == -1:
			EventBus.body_deselected.emit()
		else:
			var body = UniverseManager.get_body(value)
			if body:
				EventBus.body_selected.emit(body)

var camera_follow_id: int = -1

# Multi-select
var multi_selected_ids: Array = []

func multi_select(id: int) -> void:
	if id in multi_selected_ids:
		multi_selected_ids.erase(id)
		var body := UniverseManager.get_body(id)
		if body: body.is_multi_selected = false
	else:
		multi_selected_ids.append(id)
		var body := UniverseManager.get_body(id)
		if body: body.is_multi_selected = true

func clear_multi_select() -> void:
	for id in multi_selected_ids:
		var body := UniverseManager.get_body(id)
		if body: body.is_multi_selected = false
	multi_selected_ids.clear()

# -------------------------------------------------------
# Viewport overlay toggles
# -------------------------------------------------------
var show_orbits:           bool = true
var show_velocity_vectors: bool = false
var show_habitable_zones:  bool = true
var show_names:            bool = true
var show_grid:             bool = false
var show_hill_spheres:     bool = false

enum ViewMode { NORMAL, TEMPERATURE_MAP, DAYLIGHT_VIEW }
var view_mode: int = ViewMode.NORMAL

# -------------------------------------------------------
# Speed presets
# -------------------------------------------------------
const SPEED_PRESETS := [0.001, 0.01, 0.1, 1.0, 10.0, 100.0, 1000.0, 10000.0, 1_000_000.0]
var speed_preset_index: int = 3  # starts at 1.0

func set_speed_preset(index: int) -> void:
	speed_preset_index = clamp(index, 0, SPEED_PRESETS.size() - 1)
	time_multiplier = SPEED_PRESETS[speed_preset_index]

func faster() -> void:
	set_speed_preset(speed_preset_index + 1)

func slower() -> void:
	set_speed_preset(speed_preset_index - 1)

func toggle_pause() -> void:
	is_paused = !is_paused

func step_frame() -> void:
	is_paused = true
	step_one_frame = true

func reset() -> void:
	simulation_time = 0.0
	is_paused = false
	time_multiplier = SPEED_PRESETS[3]
	speed_preset_index = 3
	selected_body_id = -1
	camera_follow_id = -1
	clear_multi_select()
	active_tool = Tool.SELECT

func get_speed_label() -> String:
	var m := abs(time_multiplier)
	if m < 1.0:
		return "%.3f×" % m
	elif m < 1000.0:
		return "%.0f×" % m
	elif m < 1_000_000.0:
		return "%.1fk×" % (m / 1000.0)
	else:
		return "%.1fM×" % (m / 1_000_000.0)
