extends CanvasLayer

@onready var _body_count_label: Label   = $TopBar/BodyCount
@onready var _sim_time_label:   Label   = $TopBar/SimTime
@onready var _reversed_banner:  Label   = $TopBar/ReversedBanner
@onready var _speed_label:      Label   = $TopBar/SpeedLabel
@onready var _notification_bar: Label   = $NotificationBar

var _banner_tween: Tween
var _notification_timer: float = 0.0

func _ready() -> void:
	EventBus.reverse_mode_changed.connect(_on_reverse_mode_changed)
	EventBus.stellar_transition.connect(_on_stellar_transition)
	EventBus.collision_occurred.connect(_on_collision)
	EventBus.body_spaghettified.connect(_on_spaghettified)
	EventBus.habitability_changed.connect(_on_habitability)
	EventBus.time_speed_changed.connect(_on_speed_changed)
	_reversed_banner.visible = false
	_notification_bar.visible = false

func _process(delta: float) -> void:
	# Update live labels
	var body_count := UniverseManager.bodies.size()
	_body_count_label.text = "Bodies: %d" % body_count

	var sim_years := GameState.simulation_time
	if sim_years < 1000.0:
		_sim_time_label.text = "%.2f yr" % sim_years
	elif sim_years < 1_000_000.0:
		_sim_time_label.text = "%.2f kyr" % (sim_years / 1000.0)
	elif sim_years < 1_000_000_000.0:
		_sim_time_label.text = "%.2f Myr" % (sim_years / 1_000_000.0)
	else:
		_sim_time_label.text = "%.2f Gyr" % (sim_years / 1_000_000_000.0)

	# Notification fade
	if _notification_timer > 0.0:
		_notification_timer -= delta
		_notification_bar.modulate.a = min(_notification_timer, 1.0)
		if _notification_timer <= 0.0:
			_notification_bar.visible = false

func show_notification(text: String, duration: float = 3.0) -> void:
	_notification_bar.text = text
	_notification_bar.visible = true
	_notification_timer = duration

func _on_reverse_mode_changed(enabled: bool) -> void:
	_reversed_banner.visible = enabled
	if enabled:
		show_notification("⚠ REVERSED REALITY ACTIVE — All laws of physics are inverted", 5.0)
		_animate_banner()
	else:
		show_notification("Normal physics restored", 3.0)
		if _banner_tween:
			_banner_tween.kill()

func _animate_banner() -> void:
	if _banner_tween:
		_banner_tween.kill()
	_banner_tween = create_tween().set_loops()
	_banner_tween.tween_property(_reversed_banner, "modulate",
		Color(1.0, 0.2, 0.2, 1.0), 0.5)
	_banner_tween.tween_property(_reversed_banner, "modulate",
		Color(1.0, 0.6, 0.1, 1.0), 0.5)

func _on_stellar_transition(id: int, _old: int, new_stage: int) -> void:
	var body := UniverseManager.get_body(id)
	var name := body.display_name if body else "Unknown"
	var stage_name := CelestialBody.StellarStage.keys()[new_stage]
	show_notification("%s → %s" % [name, stage_name.replace("_", " ").capitalize()])

func _on_collision(id_a: int, id_b: int, _merged: int) -> void:
	var a := UniverseManager.get_body(id_a)
	var b := UniverseManager.get_body(id_b)
	if a and b:
		show_notification("Collision: %s + %s" % [a.display_name, b.display_name])

func _on_spaghettified(id: int) -> void:
	var body := UniverseManager.get_body(id)
	if body:
		show_notification("⚠ %s is being spaghettified!" % body.display_name)

func _on_habitability(id: int, habitable: bool) -> void:
	var body := UniverseManager.get_body(id)
	if body:
		var msg := "%s is now HABITABLE!" if habitable else "%s is no longer habitable"
		show_notification(msg % body.display_name)

func _on_speed_changed(mult: float) -> void:
	if mult < 0:
		_speed_label.text = "◀ REWIND"
	elif GameState.is_paused:
		_speed_label.text = "⏸ PAUSED"
	else:
		_speed_label.text = "%.0f× " % abs(mult)
