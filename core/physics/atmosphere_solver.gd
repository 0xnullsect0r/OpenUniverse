class_name AtmosphereSolver
extends RefCounted

# -------------------------------------------------------
# Simulates atmospheric evolution on planets:
# - CO₂ greenhouse warming / cooling feedbacks
# - Water vapor positive feedback
# - Ice-albedo feedback
# - Atmospheric escape (Jeans escape for light gases)
# - Volcanic outgassing (adds CO₂ over time)
# -------------------------------------------------------

const VOLCANIC_OUTGAS_RATE := 0.0000001  # CO₂ fraction added per year per unit mass
const JEANS_ESCAPE_H2_RATE := 0.00001    # H₂ lost per year for hot small planets
const ICE_MELT_TEMP        := 273.0
const ICE_FREEZE_TEMP      := 250.0
const OCEAN_EVAP_TEMP      := 340.0      # runaway evaporation threshold
const RUNAWAY_GREENHOUSE_TEMP := 400.0

func update(bodies: Array, dt_years: float) -> void:
	var stars := bodies.filter(func(b): return b.body_type == CelestialBody.BodyType.STAR)

	for body in bodies:
		if body.body_type not in [CelestialBody.BodyType.PLANET,
				CelestialBody.BodyType.MOON, CelestialBody.BodyType.GAS_GIANT]:
			continue

		_update_equilibrium_temperature(body, stars, dt_years)
		_update_ice_albedo_feedback(body, dt_years)
		_update_water_vapor_feedback(body, dt_years)
		_update_runaway_greenhouse(body, dt_years)
		_update_atmospheric_escape(body, dt_years)
		_update_volcanic_outgassing(body, dt_years)
		_clamp_atmosphere(body)
		body.update_derived_properties()

func _update_equilibrium_temperature(body: CelestialBody, stars: Array, dt: float) -> void:
	if stars.is_empty():
		return
	# Find closest star
	var nearest_star: CelestialBody = null
	var nearest_dist := INF
	for star in stars:
		var d := body.position.distance_to(star.position)
		if d < nearest_dist:
			nearest_dist = d
			nearest_star = star
	if nearest_star == null:
		return

	var lum := absf(nearest_star.luminosity)  # abs because reverse mode makes it negative
	var T_eq := ThermalSolver.equilibrium_temperature(
		lum, nearest_star.radius, nearest_dist, body.albedo, body.greenhouse_factor
	)
	# In reverse mode, heat flows cold→hot — so equilibrium is inverted
	T_eq = T_eq * PhysicsConstants.HEAT_FLOW_DIRECTION
	if T_eq < 0:
		T_eq = 10000.0 - abs(T_eq)  # Cursed reverse thermodynamics

	# Slowly relax toward equilibrium
	var relax_rate := 0.01 * dt
	body.surface_temperature = lerp(body.surface_temperature, abs(T_eq), clamp(relax_rate, 0.0, 0.5))
	body.surface_temperature = max(body.surface_temperature, 2.7)

func _update_ice_albedo_feedback(body: CelestialBody, dt: float) -> void:
	var rate := 0.001 * dt * PhysicsConstants.ENTROPY_DIRECTION
	if body.surface_temperature < ICE_FREEZE_TEMP:
		# Water freezes → more ice → higher albedo
		var freeze_amt := minf(body.surface_water * 0.1 * dt, 0.01)
		body.surface_water -= freeze_amt
		body.surface_ice   += freeze_amt
		body.surface_water  = max(body.surface_water, 0.0)
	elif body.surface_temperature > ICE_MELT_TEMP:
		# Ice melts → more water → lower albedo
		var melt_amt := minf(body.surface_ice * 0.05 * dt, 0.01)
		body.surface_ice   -= melt_amt
		body.surface_water += melt_amt
		body.surface_ice    = max(body.surface_ice, 0.0)

func _update_water_vapor_feedback(body: CelestialBody, dt: float) -> void:
	if body.atmosphere_pressure < 0.01:
		return
	# At higher temperatures, more water evaporates into atmosphere
	var evap_fraction := clampf((body.surface_temperature - 250.0) / 200.0, 0.0, 1.0) * 0.001 * dt
	var evap_amt := minf(body.surface_water * evap_fraction, 0.001)
	body.surface_water   -= evap_amt
	body.atm_water_vapor  = clamp(body.atm_water_vapor + evap_amt * 0.1, 0.0, 0.5)
	body.surface_water    = max(body.surface_water, 0.0)

func _update_runaway_greenhouse(body: CelestialBody, dt: float) -> void:
	if body.surface_temperature > OCEAN_EVAP_TEMP and body.surface_water > 0.0:
		# Venus-style runaway: all water evaporates into steam
		var evap := minf(body.surface_water, 0.05 * dt)
		body.surface_water    -= evap
		body.atm_water_vapor   = clamp(body.atm_water_vapor + evap, 0.0, 1.0)
		body.atmosphere_pressure += evap * 90.0  # massive pressure increase
		body.surface_water     = max(body.surface_water, 0.0)

func _update_atmospheric_escape(body: CelestialBody, dt: float) -> void:
	if body.atmosphere_pressure < 0.001:
		return
	# Light gases (H₂, He) escape more easily from low-gravity hot planets
	var escape_factor := body.surface_temperature / max(body.surface_gravity, 0.1)
	if body.atm_h2 > 0.0:
		var escaped := body.atm_h2 * JEANS_ESCAPE_H2_RATE * escape_factor * dt
		body.atm_h2            = max(body.atm_h2 - escaped, 0.0)
		body.atmosphere_pressure = max(body.atmosphere_pressure - escaped * 0.01, 0.0)

func _update_volcanic_outgassing(body: CelestialBody, dt: float) -> void:
	if body.body_type != CelestialBody.BodyType.PLANET:
		return
	# Volcanism adds CO₂ and N₂ over time, proportional to internal heat
	if body.surface_temperature > 300.0 and body.surface_rock > 0.1:
		var outgas_rate := VOLCANIC_OUTGAS_RATE * body.mass * dt
		body.atm_co2           = clamp(body.atm_co2 + outgas_rate * 0.7, 0.0, 1.0)
		body.atm_n2            = clamp(body.atm_n2  + outgas_rate * 0.3, 0.0, 1.0)
		body.atmosphere_pressure += outgas_rate * 0.001

func _clamp_atmosphere(body: CelestialBody) -> void:
	# Normalize gas fractions so they sum to 1 (if any atmosphere exists)
	var total := body.atm_n2 + body.atm_o2 + body.atm_co2 + body.atm_methane + body.atm_h2 + body.atm_water_vapor + body.atm_helium
	if total > 1.05:
		var f := 1.0 / total
		body.atm_n2 *= f; body.atm_o2 *= f; body.atm_co2 *= f
		body.atm_methane *= f; body.atm_h2 *= f; body.atm_water_vapor *= f
		body.atm_helium *= f
	body.atmosphere_pressure = max(body.atmosphere_pressure, 0.0)
