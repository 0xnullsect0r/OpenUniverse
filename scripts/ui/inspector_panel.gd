extends PanelContainer

@onready var _name_label:    Label         = $VBox/NameLabel
@onready var _type_label:    Label         = $VBox/TypeLabel
@onready var _mass_spin:     SpinBox       = $VBox/MassRow/MassSpin
@onready var _radius_spin:   SpinBox       = $VBox/RadiusRow/RadiusSpin
@onready var _temp_spin:     SpinBox       = $VBox/TempRow/TempSpin
@onready var _vel_label:     Label         = $VBox/VelLabel
@onready var _orbit_label:   Label         = $VBox/OrbitLabel
@onready var _stage_label:   Label         = $VBox/StageLabel
@onready var _lum_label:     Label         = $VBox/LumLabel
@onready var _entropy_label: Label         = $VBox/EntropyLabel
@onready var _habitable_dot: ColorRect     = $VBox/HabitableRow/HabitableDot
@onready var _spagh_warn:    Label         = $VBox/SpaghWarn
@onready var _pin_button:    Button        = $VBox/PinButton
@onready var _delete_button: Button        = $VBox/DeleteButton
@onready var _follow_button: Button        = $VBox/FollowButton

var _current_id: int = -1
var _updating: bool = false

func _ready() -> void:
	EventBus.body_selected.connect(_on_body_selected)
	EventBus.body_deselected.connect(_on_body_deselected)
	_mass_spin.value_changed.connect(_on_mass_changed)
	_radius_spin.value_changed.connect(_on_radius_changed)
	_temp_spin.value_changed.connect(_on_temp_changed)
	_pin_button.pressed.connect(_on_pin_pressed)
	_delete_button.pressed.connect(_on_delete_pressed)
	_follow_button.pressed.connect(_on_follow_pressed)
	visible = false

func _process(_delta: float) -> void:
	if _current_id < 0 or not visible:
		return
	_refresh()

func _on_body_selected(body: CelestialBody) -> void:
	_current_id = body.id
	visible = true
	_refresh()

func _on_body_deselected() -> void:
	_current_id = -1
	visible = false

func _refresh() -> void:
	var body := UniverseManager.get_body(_current_id)
	if body == null:
		visible = false
		return

	_updating = true
	_name_label.text = body.display_name
	_type_label.text = body.get_type_name().replace("_", " ").capitalize()

	_mass_spin.value   = body.mass
	_radius_spin.value = body.radius
	_temp_spin.value   = body.surface_temperature

	var spd := body.velocity.length()
	_vel_label.text = "Velocity: %.4f AU/yr" % spd

	if body.orbital_period > 0.0:
		_orbit_label.text = "Period: %.3f yr  |  SMA: %.4f AU" % [body.orbital_period, body.semi_major_axis]
	else:
		_orbit_label.text = "No orbit"

	if body.is_stellar():
		_stage_label.text  = "Stage: " + body.get_stage_name().replace("_", " ").capitalize()
		_lum_label.text    = "Luminosity: %.4f L☉  (H: %.0f%%)" % [body.luminosity, body.hydrogen_fraction * 100.0]
		_stage_label.visible = true
		_lum_label.visible   = true
	else:
		_stage_label.visible = false
		_lum_label.visible   = false

	# Entropy
	var entropy_dir := "↑" if PhysicsConstants.ENTROPY_DIRECTION > 0 else "↓"
	_entropy_label.text = "Entropy: %.3f %s" % [body.entropy, entropy_dir]

	# Habitability
	_habitable_dot.color = Color(0.1, 0.9, 0.2) if body.is_habitable else Color(0.8, 0.2, 0.2)

	# Spaghettification warning
	_spagh_warn.visible = body.is_spaghettified

	# Black hole extras
	if body.body_type == CelestialBody.BodyType.BLACK_HOLE:
		var bh_extra := "\nSchwarzschild r: %.2f km" % body.schwarzschild_radius
		if body.is_white_hole:
			bh_extra += "\n[WHITE HOLE — emitting]"
		_stage_label.text += bh_extra
		_stage_label.visible = true

	_pin_button.text = "Unpin" if body.is_pinned else "Pin"
	_updating = false

func _on_mass_changed(value: float) -> void:
	if _updating: return
	var body := UniverseManager.get_body(_current_id)
	if body:
		body.mass = value
		body.user_modified = true
		body.update_derived_properties()

func _on_radius_changed(value: float) -> void:
	if _updating: return
	var body := UniverseManager.get_body(_current_id)
	if body:
		body.radius = value
		body.user_modified = true
		body.update_derived_properties()

func _on_temp_changed(value: float) -> void:
	if _updating: return
	var body := UniverseManager.get_body(_current_id)
	if body:
		body.surface_temperature = value
		body.user_modified = true
		body.update_derived_properties()

func _on_pin_pressed() -> void:
	var body := UniverseManager.get_body(_current_id)
	if body:
		body.is_pinned = !body.is_pinned

func _on_delete_pressed() -> void:
	if _current_id >= 0:
		UniverseManager.destroy_body(_current_id)

func _on_follow_pressed() -> void:
	GameState.camera_follow_id = _current_id
