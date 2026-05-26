extends Node

# -------------------------------------------------------
# Body registry — the single source of truth for all
# celestial body data. Physics solvers and UI both read
# from here. BodyNodes in the scene tree hold only a
# reference (body_id) and mirror position for rendering.
# -------------------------------------------------------

var bodies: Dictionary = {}  # int id -> CelestialBody
var _next_id: int = 1

# Body type to spawn when user clicks in the viewport
var pending_spawn_type: int = -1  # BodyType enum value, -1 = none

# -------------------------------------------------------
# Body management
# -------------------------------------------------------
func spawn_body(type: int, position: Vector2, velocity: Vector2 = Vector2.ZERO, params: Dictionary = {}) -> Object:
	var body = BodyFactory.create(type, params)
	body.id = _next_id
	_next_id += 1
	body.position = position
	body.velocity = velocity
	if PhysicsConstants.ANTIMATTER_BACKGROUND:
		body.is_antimatter = true
	bodies[body.id] = body
	EventBus.body_spawned.emit(body)
	return body

func destroy_body(id: int) -> void:
	if not bodies.has(id):
		return
	bodies.erase(id)
	if GameState.selected_body_id == id:
		GameState.selected_body_id = -1
	if GameState.camera_follow_id == id:
		GameState.camera_follow_id = -1
	EventBus.body_destroyed.emit(id)

func get_body(id: int) -> Object:
	return bodies.get(id, null)

func get_all_bodies() -> Array:
	return bodies.values()

func clear_all() -> void:
	var ids := bodies.keys().duplicate()
	for id in ids:
		destroy_body(id)
	_next_id = 1

# -------------------------------------------------------
# Scenario loading
# -------------------------------------------------------
func load_scenario(path: String) -> void:
	clear_all()
	GameState.reset()
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Cannot open scenario: " + path)
		return
	var json_text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(json_text)
	if parsed == null:
		push_error("Invalid JSON in scenario: " + path)
		return
	_apply_scenario_data(parsed)
	EventBus.scenario_loaded.emit(parsed.get("name", "Unknown"))

func _apply_scenario_data(data: Dictionary) -> void:
	for bd in data.get("bodies", []):
		var type_name: String = bd.get("type", "PLANET")
		var type_int: int = _type_name_to_int(type_name)
		var pos := Vector2(
			float(bd.get("position", [0.0, 0.0])[0]),
			float(bd.get("position", [0.0, 0.0])[1])
		)
		var vel := Vector2(
			float(bd.get("velocity", [0.0, 0.0])[0]),
			float(bd.get("velocity", [0.0, 0.0])[1])
		)
		var body = spawn_body(type_int, pos, vel, bd)
		# Core properties
		if bd.has("name"):               body.display_name         = bd["name"]
		if bd.has("mass"):               body.mass                 = float(bd["mass"])
		if bd.has("radius"):             body.radius               = float(bd["radius"])
		if bd.has("surface_temperature"): body.surface_temperature = float(bd["surface_temperature"])
		if bd.has("age_myr"):            body.age                  = float(bd["age_myr"])
		if bd.has("luminosity"):         body.luminosity           = float(bd["luminosity"])
		if bd.has("greenhouse_factor"):  body.greenhouse_factor    = float(bd["greenhouse_factor"])
		if bd.has("atmosphere_pressure"): body.atmosphere_pressure = float(bd["atmosphere_pressure"])
		if bd.has("spectral_class"):     body.spectral_class       = _spectral_class_to_int(bd["spectral_class"])
		if bd.has("axial_tilt"):         body.axial_tilt           = float(bd["axial_tilt"])
		# Atmosphere composition
		if bd.has("atm_n2"):         body.atm_n2         = float(bd["atm_n2"])
		if bd.has("atm_o2"):         body.atm_o2         = float(bd["atm_o2"])
		if bd.has("atm_co2"):        body.atm_co2        = float(bd["atm_co2"])
		if bd.has("atm_methane"):    body.atm_methane    = float(bd["atm_methane"])
		if bd.has("atm_h2"):         body.atm_h2         = float(bd["atm_h2"])
		if bd.has("atm_water_vapor"):body.atm_water_vapor = float(bd["atm_water_vapor"])
		# Surface materials
		if bd.has("surface_water"):  body.surface_water  = float(bd["surface_water"])
		if bd.has("surface_ice"):    body.surface_ice    = float(bd["surface_ice"])
		if bd.has("surface_rock"):   body.surface_rock   = float(bd["surface_rock"])
		if bd.has("surface_iron"):   body.surface_iron   = float(bd["surface_iron"])
		# Rings
		if bd.has("has_rings"):      body.has_rings      = bool(bd["has_rings"])
		body.update_derived_properties()

# -------------------------------------------------------
# Reverse mode hook — swap black holes ↔ white holes
# -------------------------------------------------------
func _ready() -> void:
	EventBus.reverse_mode_changed.connect(_on_reverse_mode_changed)

func _on_reverse_mode_changed(enabled: bool) -> void:
	for body in bodies.values():
		if body.body_type == body.BodyType.BLACK_HOLE:
			body.is_white_hole = enabled
			body.accretion_rate = -abs(body.accretion_rate) if enabled else abs(body.accretion_rate)
		body.is_antimatter = enabled or body._base_is_antimatter

# -------------------------------------------------------
# Snapshot support for timeline
# -------------------------------------------------------
func take_snapshot() -> Array:
	var snap := []
	for body in bodies.values():
		snap.append({
			"id":       body.id,
			"pos":      [body.position.x, body.position.y],
			"vel":      [body.velocity.x, body.velocity.y],
			"mass":     body.mass,
			"temp":     body.surface_temperature,
			"h_frac":   body.hydrogen_fraction,
			"stage":    body.stellar_stage,
			"age":      body.age,
			"lum":      body.luminosity,
		})
	return snap

func restore_snapshot(snap: Array) -> void:
	for entry in snap:
		var body = bodies.get(entry["id"])
		if body == null:
			continue
		body.position           = Vector2(entry["pos"][0], entry["pos"][1])
		body.velocity           = Vector2(entry["vel"][0], entry["vel"][1])
		body.mass               = entry["mass"]
		body.surface_temperature= entry["temp"]
		body.hydrogen_fraction  = entry["h_frac"]
		body.stellar_stage      = entry["stage"]
		body.age                = entry["age"]
		body.luminosity         = entry["lum"]

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
func _type_name_to_int(name: String) -> int:
	# Matches BodyType enum in CelestialBody
	var map := {
		"STAR": 0, "PLANET": 1, "MOON": 2, "ASTEROID": 3, "COMET": 4,
		"GAS_GIANT": 5, "NEUTRON_STAR": 6, "WHITE_DWARF": 7,
		"BLACK_HOLE": 8, "NEBULA": 9, "GALAXY": 10
	}
	return map.get(name.to_upper(), 1)

func _spectral_class_to_int(s: String) -> int:
	var map := {"O": 0, "B": 1, "A": 2, "F": 3, "G": 4, "K": 5, "M": 6}
	return map.get(s.to_upper(), 4)
