extends PanelContainer

# -------------------------------------------------------
# Universe Sandbox-style body inspector.
# Shows and edits all properties of the selected body.
# Organized into collapsible sections.
# -------------------------------------------------------

@onready var _name_edit:     LineEdit  = $ScrollContainer/VBox/IdentSection/NameEdit
@onready var _type_label:    Label     = $ScrollContainer/VBox/IdentSection/TypeLabel
@onready var _id_label:      Label     = $ScrollContainer/VBox/IdentSection/IdLabel

# Physical
@onready var _mass_spin:     SpinBox   = $ScrollContainer/VBox/PhysSection/MassRow/MassSpin
@onready var _radius_spin:   SpinBox   = $ScrollContainer/VBox/PhysSection/RadiusRow/RadiusSpin
@onready var _density_label: Label     = $ScrollContainer/VBox/PhysSection/DensityLabel
@onready var _gravity_label: Label     = $ScrollContainer/VBox/PhysSection/GravityLabel
@onready var _escape_label:  Label     = $ScrollContainer/VBox/PhysSection/EscapeLabel
@onready var _tilt_spin:     SpinBox   = $ScrollContainer/VBox/PhysSection/TiltRow/TiltSpin
@onready var _spin_spin:     SpinBox   = $ScrollContainer/VBox/PhysSection/SpinRow/SpinSpin

# Thermal
@onready var _temp_spin:     SpinBox   = $ScrollContainer/VBox/ThermalSection/TempRow/TempSpin
@onready var _lum_label:     Label     = $ScrollContainer/VBox/ThermalSection/LumLabel
@onready var _albedo_label:  Label     = $ScrollContainer/VBox/ThermalSection/AlbedoLabel
@onready var _stage_label:   Label     = $ScrollContainer/VBox/ThermalSection/StageLabel
@onready var _supernova_btn: Button    = $ScrollContainer/VBox/ThermalSection/SupernovaBtn

# Orbital
@onready var _vel_label:     Label     = $ScrollContainer/VBox/OrbitalSection/VelLabel
@onready var _orbit_label:   Label     = $ScrollContainer/VBox/OrbitalSection/OrbitLabel
@onready var _ecc_label:     Label     = $ScrollContainer/VBox/OrbitalSection/EccLabel
@onready var _peri_label:    Label     = $ScrollContainer/VBox/OrbitalSection/PeriLabel
@onready var _hill_label:    Label     = $ScrollContainer/VBox/OrbitalSection/HillLabel
@onready var _vel_x_spin:    SpinBox   = $ScrollContainer/VBox/OrbitalSection/VelEditRow/VelXSpin
@onready var _vel_y_spin:    SpinBox   = $ScrollContainer/VBox/OrbitalSection/VelEditRow/VelYSpin

# Atmosphere
@onready var _pressure_spin: SpinBox   = $ScrollContainer/VBox/AtmSection/PressureRow/PressureSpin
@onready var _co2_slider:    HSlider   = $ScrollContainer/VBox/AtmSection/CO2Row/CO2Slider
@onready var _n2_slider:     HSlider   = $ScrollContainer/VBox/AtmSection/N2Row/N2Slider
@onready var _o2_slider:     HSlider   = $ScrollContainer/VBox/AtmSection/O2Row/O2Slider
@onready var _methane_slider:HSlider   = $ScrollContainer/VBox/AtmSection/MethaneRow/MethaneSlider
@onready var _h2_slider:     HSlider   = $ScrollContainer/VBox/AtmSection/H2Row/H2Slider
@onready var _co2_label:     Label     = $ScrollContainer/VBox/AtmSection/CO2Row/CO2Label
@onready var _n2_label:      Label     = $ScrollContainer/VBox/AtmSection/N2Row/N2Label
@onready var _o2_label:      Label     = $ScrollContainer/VBox/AtmSection/O2Row/O2Label
@onready var _add_water_btn: Button    = $ScrollContainer/VBox/AtmSection/AddButtons/AddWaterBtn
@onready var _add_co2_btn:   Button    = $ScrollContainer/VBox/AtmSection/AddButtons/AddCO2Btn
@onready var _add_n2_btn:    Button    = $ScrollContainer/VBox/AtmSection/AddButtons/AddN2Btn
@onready var _add_o2_btn:    Button    = $ScrollContainer/VBox/AtmSection/AddButtons/AddO2Btn
@onready var _strip_atm_btn: Button    = $ScrollContainer/VBox/AtmSection/AddButtons/StripAtmBtn

# Surface materials
@onready var _water_label:   Label     = $ScrollContainer/VBox/SurfaceSection/WaterLabel
@onready var _ice_label:     Label     = $ScrollContainer/VBox/SurfaceSection/IceLabel
@onready var _rock_label:    Label     = $ScrollContainer/VBox/SurfaceSection/RockLabel
@onready var _habitable_dot: ColorRect = $ScrollContainer/VBox/SurfaceSection/HabitRow/HabitDot
@onready var _greenhouse_label: Label  = $ScrollContainer/VBox/SurfaceSection/GreenhouseLabel

# State / actions
@onready var _entropy_label: Label     = $ScrollContainer/VBox/StateSection/EntropyLabel
@onready var _spagh_warn:    Label     = $ScrollContainer/VBox/StateSection/SpaghWarn
@onready var _bh_label:      Label     = $ScrollContainer/VBox/StateSection/BHLabel
@onready var _pin_button:    Button    = $ScrollContainer/VBox/ActionSection/PinButton
@onready var _delete_button: Button    = $ScrollContainer/VBox/ActionSection/DeleteButton
@onready var _follow_button: Button    = $ScrollContainer/VBox/ActionSection/FollowButton
@onready var _impact_button: Button    = $ScrollContainer/VBox/ActionSection/ImpactButton

var _current_id: int = -1
var _updating:   bool = false

func _ready() -> void:
	EventBus.body_selected.connect(_on_body_selected)
	EventBus.body_deselected.connect(_on_body_deselected)

	_mass_spin.value_changed.connect(_on_mass_changed)
	_radius_spin.value_changed.connect(_on_radius_changed)
	_temp_spin.value_changed.connect(_on_temp_changed)
	_tilt_spin.value_changed.connect(_on_tilt_changed)
	_spin_spin.value_changed.connect(_on_spin_changed)
	_pressure_spin.value_changed.connect(_on_pressure_changed)
	_co2_slider.value_changed.connect(_on_co2_changed)
	_n2_slider.value_changed.connect(_on_n2_changed)
	_o2_slider.value_changed.connect(_on_o2_changed)
	_methane_slider.value_changed.connect(_on_methane_changed)
	_h2_slider.value_changed.connect(_on_h2_changed)
	_vel_x_spin.value_changed.connect(_on_vel_x_changed)
	_vel_y_spin.value_changed.connect(_on_vel_y_changed)
	_name_edit.text_submitted.connect(_on_name_submitted)

	_pin_button.pressed.connect(_on_pin_pressed)
	_delete_button.pressed.connect(_on_delete_pressed)
	_follow_button.pressed.connect(_on_follow_pressed)
	_add_water_btn.pressed.connect(_on_add_water)
	_add_co2_btn.pressed.connect(_on_add_co2)
	_add_n2_btn.pressed.connect(_on_add_n2)
	_add_o2_btn.pressed.connect(_on_add_o2)
	_strip_atm_btn.pressed.connect(_on_strip_atmosphere)
	_supernova_btn.pressed.connect(_on_trigger_supernova)
	_impact_button.pressed.connect(_on_impact_asteroid)

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

	# Identity
	_name_edit.text  = body.display_name
	_type_label.text = body.get_type_name().replace("_", " ").capitalize()
	_id_label.text   = "ID: %d" % body.id

	# Physical
	_mass_spin.value   = body.mass
	_radius_spin.value = body.radius
	_density_label.text = "Density: %.2f g/cm³" % body.density
	_gravity_label.text = "Surface g: %.2f m/s²" % body.surface_gravity
	_escape_label.text  = "Escape v: %.3f AU/yr" % body.escape_velocity_au
	_tilt_spin.value    = body.axial_tilt
	_spin_spin.value    = body.angular_velocity

	# Thermal
	_temp_spin.value = body.surface_temperature
	_albedo_label.text = "Albedo: %.2f  |  Greenhouse: ×%.2f" % [body.albedo, body.greenhouse_factor]
	if body.is_stellar():
		_stage_label.text    = "Stage: %s  |  L: %.3f L☉  (H: %.0f%%)" % [
			body.get_stage_name().replace("_"," ").capitalize(), body.luminosity, body.hydrogen_fraction * 100.0]
		_stage_label.visible = true
		_supernova_btn.visible = (body.body_type == CelestialBody.BodyType.STAR and body.mass > 8.0)
	else:
		_stage_label.visible   = false
		_supernova_btn.visible = false

	# Orbital
	var spd := body.velocity.length()
	_vel_label.text = "Speed: %.4f AU/yr  (%.2f km/s)" % [spd, spd * PhysicsConstants.AU_IN_METERS / PhysicsConstants.YEAR_IN_SEC / 1000.0]
	if body.orbital_period > 0.0:
		var yr := body.orbital_period
		var period_str := "%.3f yr" % yr if yr < 1000.0 else "%.1f kyr" % (yr / 1000.0)
		_orbit_label.text = "Period: %s  |  SMA: %.4f AU" % [period_str, body.semi_major_axis]
		_ecc_label.text   = "Ecc: %.3f  |  Peri: %.4f  Apo: %.4f AU" % [body.eccentricity, body.periapsis, body.apoapsis]
		_hill_label.text  = "Hill sphere: %.4f AU" % body.hill_sphere
	else:
		_orbit_label.text = "Free body (no orbit)"
		_ecc_label.text   = ""
		_hill_label.text  = ""
	_vel_x_spin.set_value_no_signal(body.velocity.x)
	_vel_y_spin.set_value_no_signal(body.velocity.y)
	_peri_label.text = "Vx: %.4f  Vy: %.4f AU/yr" % [body.velocity.x, body.velocity.y]

	# Atmosphere
	_pressure_spin.set_value_no_signal(body.atmosphere_pressure)
	_co2_slider.set_value_no_signal(body.atm_co2)
	_n2_slider.set_value_no_signal(body.atm_n2)
	_o2_slider.set_value_no_signal(body.atm_o2)
	_methane_slider.set_value_no_signal(body.atm_methane)
	_h2_slider.set_value_no_signal(body.atm_h2)
	_co2_label.text = "CO₂: %.1f%%" % (body.atm_co2 * 100.0)
	_n2_label.text  = "N₂:  %.1f%%" % (body.atm_n2  * 100.0)
	_o2_label.text  = "O₂:  %.1f%%" % (body.atm_o2  * 100.0)

	# Surface
	_water_label.text     = "Water: %.1f%%   Ice: %.1f%%   Rock: %.1f%%   Iron: %.1f%%" % [
		body.surface_water * 100.0, body.surface_ice * 100.0,
		body.surface_rock * 100.0,  body.surface_iron * 100.0]
	_habitable_dot.color  = Color(0.1, 0.9, 0.2) if body.is_habitable else Color(0.8, 0.2, 0.2)
	_greenhouse_label.text = "Greenhouse factor: ×%.2f" % body.greenhouse_factor
	_ice_label.text = "Axial tilt: %.1f°  |  Spin: %.3f rad/yr" % [body.axial_tilt, body.angular_velocity]

	# State
	var entropy_dir := "↑ (disorder↑)" if PhysicsConstants.ENTROPY_DIRECTION > 0 else "↓ (order↑)"
	_entropy_label.text = "Entropy: %.3f %s" % [body.entropy, entropy_dir]
	_spagh_warn.visible = body.is_spaghettified

	# Black hole info
	if body.body_type == CelestialBody.BodyType.BLACK_HOLE:
		var wh := "WHITE HOLE ↑" if body.is_white_hole else "Black Hole ↓"
		_bh_label.text    = "%s  |  r_s: %.2f km  |  Ṁ: %.2e M☉/yr" % [wh, body.schwarzschild_radius, body.accretion_rate]
		_bh_label.visible = true
	else:
		_bh_label.visible = false

	_pin_button.text = "Unpin" if body.is_pinned else "Pin"
	_updating = false

# -------------------------------------------------------
# Change handlers
# -------------------------------------------------------
func _on_name_submitted(text: String) -> void:
	var body := UniverseManager.get_body(_current_id)
	if body: body.display_name = text

func _on_mass_changed(v: float) -> void:
	if _updating: return
	var body := UniverseManager.get_body(_current_id)
	if body: body.mass = v; body.user_modified = true; body.update_derived_properties()

func _on_radius_changed(v: float) -> void:
	if _updating: return
	var body := UniverseManager.get_body(_current_id)
	if body: body.radius = v; body.user_modified = true; body.update_derived_properties()

func _on_temp_changed(v: float) -> void:
	if _updating: return
	var body := UniverseManager.get_body(_current_id)
	if body: body.surface_temperature = v; body.user_modified = true; body.update_derived_properties()

func _on_tilt_changed(v: float) -> void:
	if _updating: return
	var body := UniverseManager.get_body(_current_id)
	if body: body.axial_tilt = v; body.user_modified = true

func _on_spin_changed(v: float) -> void:
	if _updating: return
	var body := UniverseManager.get_body(_current_id)
	if body: body.angular_velocity = v; body.user_modified = true

func _on_pressure_changed(v: float) -> void:
	if _updating: return
	var body := UniverseManager.get_body(_current_id)
	if body: body.atmosphere_pressure = v; body.user_modified = true; body.update_derived_properties()

func _on_co2_changed(v: float) -> void:
	if _updating: return
	var body := UniverseManager.get_body(_current_id)
	if body: body.atm_co2 = v; body.user_modified = true; body.update_derived_properties()

func _on_n2_changed(v: float) -> void:
	if _updating: return
	var body := UniverseManager.get_body(_current_id)
	if body: body.atm_n2 = v; body.user_modified = true; body.update_derived_properties()

func _on_o2_changed(v: float) -> void:
	if _updating: return
	var body := UniverseManager.get_body(_current_id)
	if body: body.atm_o2 = v; body.user_modified = true; body.update_derived_properties()

func _on_methane_changed(v: float) -> void:
	if _updating: return
	var body := UniverseManager.get_body(_current_id)
	if body: body.atm_methane = v; body.user_modified = true; body.update_derived_properties()

func _on_h2_changed(v: float) -> void:
	if _updating: return
	var body := UniverseManager.get_body(_current_id)
	if body: body.atm_h2 = v; body.user_modified = true; body.update_derived_properties()

func _on_vel_x_changed(v: float) -> void:
	if _updating: return
	var body := UniverseManager.get_body(_current_id)
	if body: body.velocity.x = v; body.user_modified = true

func _on_vel_y_changed(v: float) -> void:
	if _updating: return
	var body := UniverseManager.get_body(_current_id)
	if body: body.velocity.y = v; body.user_modified = true

# -------------------------------------------------------
# Action buttons
# -------------------------------------------------------
func _on_pin_pressed() -> void:
	var body := UniverseManager.get_body(_current_id)
	if body: body.is_pinned = !body.is_pinned

func _on_delete_pressed() -> void:
	if _current_id >= 0: UniverseManager.destroy_body(_current_id)

func _on_follow_pressed() -> void:
	GameState.camera_follow_id = _current_id

func _on_add_water() -> void:
	var body := UniverseManager.get_body(_current_id)
	if body: LaserSolver.add_water(body)

func _on_add_co2() -> void:
	var body := UniverseManager.get_body(_current_id)
	if body: LaserSolver.add_co2(body)

func _on_add_n2() -> void:
	var body := UniverseManager.get_body(_current_id)
	if body: LaserSolver.add_nitrogen(body)

func _on_add_o2() -> void:
	var body := UniverseManager.get_body(_current_id)
	if body: LaserSolver.add_oxygen(body)

func _on_strip_atmosphere() -> void:
	var body := UniverseManager.get_body(_current_id)
	if body: LaserSolver.strip_atmosphere(body)

func _on_trigger_supernova() -> void:
	var body := UniverseManager.get_body(_current_id)
	if body == null: return
	# Force the star into supernova by draining all hydrogen
	body.hydrogen_fraction = 0.0
	body.stellar_stage = CelestialBody.StellarStage.RED_GIANT
	body.radius = body.mass * 50.0
	body.surface_temperature = 3500.0
	EventBus.supernova_flash.emit(body.position, body.mass)

func _on_impact_asteroid() -> void:
	# Spawn a fast asteroid aimed at the selected body
	var body := UniverseManager.get_body(_current_id)
	if body == null: return
	var offset := Vector2(randf_range(-5.0, 5.0), randf_range(-5.0, 5.0))
	var spawn_pos := body.position + offset * 5.0
	var vel := (body.position - spawn_pos).normalized() * 3.0 + body.velocity
	var asteroid = UniverseManager.spawn_body(CelestialBody.BodyType.ASTEROID, spawn_pos, vel,
		{"mass": body.mass * 0.001, "display_name": "Impactor"})
	asteroid.surface_temperature = 400.0
