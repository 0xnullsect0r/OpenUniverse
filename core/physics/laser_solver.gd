class_name LaserSolver
extends RefCounted

# -------------------------------------------------------
# Laser tool: heat or cool a target body, strip atmosphere,
# or apply radiation pressure push/pull.
#
# Called once per frame when the user has a laser tool active
# and is pointing at a body. The UI calls apply_laser().
# -------------------------------------------------------

const HEAT_RATE         := 50.0      # K per real second
const COOL_RATE         := 30.0      # K per real second
const PUSH_FORCE_AU     := 0.01      # AU/yr² per real second of push
const ATMO_STRIP_RATE   := 0.001     # bar per real second

# Apply laser to body. heat=true warms, heat=false cools.
# Returns the new temperature for UI display.
func apply_laser(target: CelestialBody, heat: bool, delta: float) -> float:
	if target == null:
		return 0.0

	var sign := 1.0 if heat else -1.0
	var rate := HEAT_RATE if heat else COOL_RATE

	target.surface_temperature += sign * rate * delta
	target.surface_temperature = max(target.surface_temperature, 2.7)
	target.user_modified = true

	# High-power heating can strip atmosphere
	if heat and target.surface_temperature > 5000.0:
		var strip := ATMO_STRIP_RATE * delta
		target.atmosphere_pressure = max(target.atmosphere_pressure - strip, 0.0)
		target.atm_co2      = max(target.atm_co2      - strip * 0.5, 0.0)
		target.atm_n2       = max(target.atm_n2       - strip * 0.3, 0.0)
		target.atm_o2       = max(target.atm_o2       - strip * 0.2, 0.0)
		EventBus.atmosphere_changed.emit(target.id)

	# Very high temp → start melting/vaporizing surface
	if heat and target.surface_temperature > 2000.0:
		target.surface_ice   = max(target.surface_ice   - 0.01 * delta, 0.0)
		target.surface_water = max(target.surface_water - 0.005 * delta, 0.0)
		target.surface_rock  = min(target.surface_rock  + 0.005 * delta, 1.0)

	target.update_derived_properties()
	return target.surface_temperature

# Apply radiation pressure (push body away from cursor)
func apply_push(target: CelestialBody, push_direction: Vector2, delta: float) -> void:
	if target == null or target.is_pinned:
		return
	var force := push_direction.normalized() * PUSH_FORCE_AU * delta
	target.velocity += force

# Apply pull toward cursor
func apply_pull(target: CelestialBody, pull_direction: Vector2, delta: float) -> void:
	if target == null or target.is_pinned:
		return
	var force := pull_direction.normalized() * PUSH_FORCE_AU * delta
	target.velocity -= force

# Add material to a body
static func add_water(body: CelestialBody, amount: float = 0.1) -> void:
	body.surface_water = clamp(body.surface_water + amount, 0.0, 1.0)
	body.surface_rock  = clamp(body.surface_rock  - amount, 0.0, 1.0)
	body.update_derived_properties()

static func add_co2(body: CelestialBody, amount: float = 0.1) -> void:
	body.atm_co2             = clamp(body.atm_co2 + amount, 0.0, 1.0)
	body.atmosphere_pressure = clamp(body.atmosphere_pressure + amount * 10.0, 0.0, 1000.0)
	body.update_derived_properties()
	EventBus.atmosphere_changed.emit(body.id)

static func add_ice(body: CelestialBody, amount: float = 0.1) -> void:
	body.surface_ice  = clamp(body.surface_ice + amount, 0.0, 1.0)
	body.surface_rock = clamp(body.surface_rock - amount, 0.0, 1.0)
	body.update_derived_properties()

static func strip_atmosphere(body: CelestialBody) -> void:
	body.atmosphere_pressure = 0.0
	body.atm_co2 = 0.0; body.atm_n2 = 0.0; body.atm_o2 = 0.0
	body.atm_methane = 0.0; body.atm_h2 = 0.0; body.atm_water_vapor = 0.0
	body.update_derived_properties()
	EventBus.atmosphere_changed.emit(body.id)

static func add_nitrogen(body: CelestialBody, amount: float = 0.1) -> void:
	body.atm_n2              = clamp(body.atm_n2 + amount, 0.0, 1.0)
	body.atmosphere_pressure = clamp(body.atmosphere_pressure + amount * 5.0, 0.0, 1000.0)
	body.update_derived_properties()

static func add_oxygen(body: CelestialBody, amount: float = 0.05) -> void:
	body.atm_o2              = clamp(body.atm_o2 + amount, 0.0, 1.0)
	body.atmosphere_pressure = clamp(body.atmosphere_pressure + amount * 2.0, 0.0, 1000.0)
	body.update_derived_properties()
