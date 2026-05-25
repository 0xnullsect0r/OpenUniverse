class_name ThermalSolver
extends RefCounted

const HEAT_EXCHANGE_RANGE_AU := 50.0  # bodies closer than this exchange heat
const HEAT_CONDUCTIVITY       := 0.0001  # fraction of temp difference per year

func update(bodies: Array, dt_years: float) -> void:
	for body in bodies:
		_update_stellar_luminosity(body, dt_years)
		_update_habitability(body)

	# Heat exchange between nearby bodies
	for i in range(bodies.size()):
		for j in range(i + 1, bodies.size()):
			var a: CelestialBody = bodies[i]
			var b: CelestialBody = bodies[j]
			var dist := a.position.distance_to(b.position)
			if dist < HEAT_EXCHANGE_RANGE_AU:
				_exchange_heat(a, b, dist, dt_years)

	# Entropy bookkeeping
	var dir := PhysicsConstants.ENTROPY_DIRECTION
	for body in bodies:
		body.entropy = max(0.0, body.entropy + dir * 0.00001 * dt_years)

func _update_stellar_luminosity(body: CelestialBody, dt: float) -> void:
	if body.body_type != CelestialBody.BodyType.STAR:
		return
	# L = R² × (T/T_sun)⁴
	body.luminosity = pow(body.radius, 2.0) * pow(body.surface_temperature / 5778.0, 4.0)
	# In reverse mode, luminosity is negative (absorbing)
	body.luminosity = PhysicsConstants.effective_luminosity(body.luminosity)

func _exchange_heat(a: CelestialBody, b: CelestialBody, dist: float, dt: float) -> void:
	var delta := PhysicsConstants.heat_delta(a.surface_temperature, b.surface_temperature)
	# Closer bodies exchange more heat; falls off with distance
	var rate := HEAT_CONDUCTIVITY * (1.0 - dist / HEAT_EXCHANGE_RANGE_AU) * dt
	var transfer := delta * rate

	# Mass-weighted: smaller body changes temp more
	var mass_total := a.mass + b.mass
	if mass_total < 1e-30:
		return
	a.surface_temperature -= transfer * (b.mass / mass_total)
	b.surface_temperature += transfer * (a.mass / mass_total)

	a.surface_temperature = max(a.surface_temperature, 2.7)
	b.surface_temperature = max(b.surface_temperature, 2.7)

func _update_habitability(body: CelestialBody) -> void:
	if body.body_type not in [CelestialBody.BodyType.PLANET, CelestialBody.BodyType.MOON]:
		return
	var was_habitable := body.is_habitable
	body.is_habitable = (
		body.surface_temperature >= 273.0 and
		body.surface_temperature <= 373.0 and
		body.atmosphere_pressure >= 0.1
	)
	if body.is_habitable != was_habitable:
		EventBus.habitability_changed.emit(body.id, body.is_habitable)

# Compute equilibrium temperature of a planet around a star
static func equilibrium_temperature(star_lum: float, star_radius_rsun: float,
		distance_au: float, albedo: float, greenhouse: float) -> float:
	# T_eq = T_star × √(R_star / 2d) × (1 - albedo)^0.25
	var T_star := 5778.0 * pow(star_lum, 0.25) / pow(star_radius_rsun, 0.5)
	var R_star_au := star_radius_rsun * PhysicsConstants.SOLAR_RADIUS_AU
	var T_eq := T_star * sqrt(R_star_au / (2.0 * max(distance_au, 0.001)))
	T_eq *= pow(1.0 - albedo, 0.25) * greenhouse
	return max(T_eq, 2.7)
