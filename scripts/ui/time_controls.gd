extends HBoxContainer

@onready var _pause_btn:   Button  = $PauseBtn
@onready var _slower_btn:  Button  = $SlowerBtn
@onready var _faster_btn:  Button  = $FasterBtn
@onready var _rewind_btn:  Button  = $RewindBtn
@onready var _speed_label: Label   = $SpeedLabel
@onready var _scrubber:    HSlider = $Scrubber

var _sim_controller: SimulationController = null
var _scrubbing: bool = false

func _ready() -> void:
	_pause_btn.pressed.connect(GameState.toggle_pause)
	_slower_btn.pressed.connect(GameState.slower)
	_faster_btn.pressed.connect(GameState.faster)
	_rewind_btn.pressed.connect(_on_rewind_pressed)
	_scrubber.value_changed.connect(_on_scrubber_changed)
	_scrubber.drag_started.connect(func(): _scrubbing = true)
	_scrubber.drag_ended.connect(func(_changed): _scrubbing = false)

	EventBus.simulation_paused.connect(_on_pause_changed.bind(true))
	EventBus.simulation_resumed.connect(_on_pause_changed.bind(false))
	EventBus.time_speed_changed.connect(_on_speed_changed)

func _process(_delta: float) -> void:
	# Find the SimulationController if not cached
	if _sim_controller == null:
		_sim_controller = get_tree().get_first_node_in_group("sim_controller")

	# Update scrubber range from timeline
	if _sim_controller and not _scrubbing:
		var tl := _sim_controller.get_timeline()
		if tl.newest_time > tl.oldest_time:
			_scrubber.min_value = tl.oldest_time
			_scrubber.max_value = tl.newest_time
			_scrubber.set_value_no_signal(GameState.simulation_time)

func _on_pause_changed(paused: bool) -> void:
	_pause_btn.text = "▶" if paused else "⏸"

func _on_speed_changed(mult: float) -> void:
	if mult < 0:
		_speed_label.text = "◀ %.0fx" % abs(mult)
	else:
		_speed_label.text = "%.0fx" % mult

func _on_rewind_pressed() -> void:
	# Toggle rewind: negate the current multiplier
	GameState.time_multiplier = -abs(GameState.time_multiplier)

func _on_scrubber_changed(value: float) -> void:
	if _scrubbing and _sim_controller:
		GameState.is_paused = true
		_sim_controller.get_timeline().seek(value)
