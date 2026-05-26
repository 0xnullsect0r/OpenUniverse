extends CanvasLayer

@onready var _body_count_label: Label   = $TopBar/BodyCount
@onready var _sim_time_label:   Label   = $TopBar/SimTime
@onready var _reversed_banner:  Label   = $TopBar/ReversedBanner
@onready var _speed_label:      Label   = $TopBar/SpeedLabel
@onready var _tool_label:       Label   = $TopBar/ToolLabel
@onready var _notification_bar: Label   = $NotificationBar
@onready var _supernova_flash:  ColorRect = $SupernovaFlash

var _banner_tween: Tween
var _notification_timer: float = 0.0
var _supernova_timer: float = 0.0

func _ready() -> void:
	EventBus.reverse_mode_changed.connect(_on_reverse_mode_changed)
	EventBus.stellar_transition.connect(_on_stellar_transition)
	EventBus.collision_occurred.connect(_on_collision)
	EventBus.body_spaghettified.connect(_on_spaghettified)
	EventBus.habitability_changed.connect(_on_habitability)
	EventBus.time_speed_changed.connect(_on_speed_changed)
	EventBus.supernova_flash.connect(_on_supernova_flash)
	_reversed_banner.visible = false
	_notification_bar.visible = false
	if _supernova_flash:
		_supernova_flash.visible = false
		_supernova_flash.color = Color(1.0, 0.8, 0.3, 0.0)

func _process(delta: float) -> void:
	# Body count
	var body_count := UniverseManager.bodies.size()
	_body_count_label.text = "Bodies: %d" % body_count

	# Simulation time
	var sim_years := GameState.simulation_time
	if sim_years < 1000.0:
		_sim_time_label.text = "%.2f yr" % sim_years
	elif sim_years < 1_000_000.0:
		_sim_time_label.text = "%.2f kyr" % (sim_years / 1000.0)
	elif sim_years < 1_000_000_000.0:
		_sim_time_label.text = "%.2f Myr" % (sim_years / 1_000_000.0)
	else:
		_sim_time_label.text = "%.2f Gyr" % (sim_years / 1_000_000_000.0)

	# Speed display with paused indicator
	var mult := GameState.time_multiplier
	if GameState.is_paused:
		_speed_label.text = "⏸ PAUSED"
	elif mult < 0:
		_speed_label.text = "◀ REWIND  " + GameState.get_speed_label()
	else:
		_speed_label.text = "▶ " + GameState.get_speed_label()

	# Active tool indicator
	var tool_names := ["⬆ Select", "🔥 Laser Heat", "❄ Laser Cool", "→ Push", "← Pull"]
	var ti := GameState.active_tool
	_tool_label.text = tool_names[ti] if ti < tool_names.size() else ""
	_tool_label.modulate = Color(1.0, 0.7, 0.3) if ti != GameState.Tool.SELECT else Color(1, 1, 1, 0.7)

	# Notification fade
	if _notification_timer > 0.0:
		_notification_timer -= delta
		_notification_bar.modulate.a = min(_notification_timer, 1.0)
		if _notification_timer <= 0.0:
			_notification_bar.visible = false

	# Supernova flash fade
	if _supernova_timer > 0.0 and _supernova_flash:
		_supernova_timer -= delta
		var alpha := clampf(_supernova_timer / 2.0, 0.0, 0.85)
		_supernova_flash.color.a = alpha
		if _supernova_timer <= 0.0:
			_supernova_flash.visible = false

func show_notification(text: String, duration: float = 3.0) -> void:
	_notification_bar.text = text
	_notification_bar.visible = true
	_notification_timer = duration
	_notification_bar.modulate.a = 1.0

func _on_reverse_mode_changed(enabled: bool) -> void:
	_reversed_banner.visible = enabled
	if enabled:
		show_notification("⚠ REVERSED REALITY ACTIVE — All laws of physics are inverted", 6.0)
		_animate_banner()
	else:
		show_notification("Normal physics restored", 3.0)
		if _banner_tween:
			_banner_tween.kill()

func _animate_banner() -> void:
	if _banner_tween: _banner_tween.kill()
	_banner_tween = create_tween().set_loops()
	_banner_tween.tween_property(_reversed_banner, "modulate", Color(1.0, 0.15, 0.1, 1.0), 0.4)
	_banner_tween.tween_property(_reversed_banner, "modulate", Color(1.0, 0.55, 0.05, 1.0), 0.4)

func _on_stellar_transition(id: int, old_stage: int, new_stage: int) -> void:
	var body := UniverseManager.get_body(id)
	var name := body.display_name if body else "Unknown"
	var old_s := CelestialBody.StellarStage.keys()[old_stage].replace("_", " ").capitalize()
	var new_s := CelestialBody.StellarStage.keys()[new_stage].replace("_", " ").capitalize()
	show_notification("★ %s: %s → %s" % [name, old_s, new_s], 5.0)

func _on_collision(id_a: int, id_b: int, _merged: int) -> void:
	var a := UniverseManager.get_body(id_a)
	var b := UniverseManager.get_body(id_b)
	if a and b:
		show_notification("💥 Collision: %s + %s" % [a.display_name, b.display_name])

func _on_spaghettified(id: int) -> void:
	var body := UniverseManager.get_body(id)
	if body: show_notification("⚠ %s is being spaghettified!" % body.display_name, 4.0)

func _on_habitability(id: int, habitable: bool) -> void:
	var body := UniverseManager.get_body(id)
	if body:
		var icon := "🌱" if habitable else "💀"
		show_notification("%s %s is %shabitable" % [icon, body.display_name, "" if habitable else "no longer "])

func _on_speed_changed(_mult: float) -> void:
	pass  # Handled in _process

func _on_supernova_flash(position: Vector2, mass: float) -> void:
	if _supernova_flash == null:
		return
	_supernova_flash.visible = true
	_supernova_flash.color = Color(1.0, 0.85, 0.4, 0.85)
	_supernova_timer = 2.5
	show_notification("💥 SUPERNOVA! Mass: %.1f M☉" % mass, 5.0)
