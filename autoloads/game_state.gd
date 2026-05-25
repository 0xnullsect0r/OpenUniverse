extends Node

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

# Multiplier over real seconds → sim years per real second.
# Negative = rewind (playback through timeline buffer).
# Preset speeds in sim-years per real second:
# 0.01 = slow, 1 = 1yr/s, 10, 100, 1000, 10000
var time_multiplier: float = 1.0:
	set(value):
		time_multiplier = value
		EventBus.time_speed_changed.emit(value)

# Elapsed simulation time in years
var simulation_time: float = 0.0

# -------------------------------------------------------
# Selection
# -------------------------------------------------------
var selected_body_id: int = -1:
	set(value):
		var old_id := selected_body_id
		selected_body_id = value
		if value == -1:
			EventBus.body_deselected.emit()
		else:
			var body = UniverseManager.get_body(value)
			if body:
				EventBus.body_selected.emit(body)

var camera_follow_id: int = -1  # -1 = free camera

# -------------------------------------------------------
# Speed presets
# -------------------------------------------------------
const SPEED_PRESETS := [0.01, 0.1, 1.0, 10.0, 100.0, 1000.0, 10000.0]
var speed_preset_index: int = 2  # starts at 1.0

func set_speed_preset(index: int) -> void:
	speed_preset_index = clamp(index, 0, SPEED_PRESETS.size() - 1)
	time_multiplier = SPEED_PRESETS[speed_preset_index]

func faster() -> void:
	set_speed_preset(speed_preset_index + 1)

func slower() -> void:
	set_speed_preset(speed_preset_index - 1)

func toggle_pause() -> void:
	is_paused = !is_paused

func reset() -> void:
	simulation_time = 0.0
	is_paused = false
	time_multiplier = SPEED_PRESETS[2]
	speed_preset_index = 2
	selected_body_id = -1
	camera_follow_id = -1
