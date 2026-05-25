class_name TidalSolver
extends RefCounted

const TIDAL_RANGE_FACTOR     := 50.0  # tidal effects within N body radii
const TIDAL_HEATING_COEFF    := 0.00001
const SPAGHETTIFICATION_FACTOR := 3.0  # rs multiples at which it begins

func update(bodies: Array, dt_years: float) -> void:
	for i in range(bodies.size()):
		var a: CelestialBody = bodies[i]
		for j in range(bodies.size()):
			if i == j:
				continue
			var b: CelestialBody = bodies[j]
			_apply_tidal(a, b, dt_years)

func _apply_tidal(body: CelestialBody, attractor: CelestialBody, dt: float) -> void:
	var dist := body.position.distance_to(attractor.position)
	var r_body_au := body.get_visual_radius()

	# Tidal heating: dE/dt ∝ m_attr * r_body^5 / dist^6
	if dist < TIDAL_RANGE_FACTOR * r_body_au and r_body_au > 0.0:
		var tidal_heat := (
			TIDAL_HEATING_COEFF
			* attractor.mass
			* pow(r_body_au, 5.0)
			/ pow(max(dist, r_body_au), 6.0)
			* dt
		)
		body.surface_temperature += tidal_heat * PhysicsConstants.HEAT_FLOW_DIRECTION

	# Spaghettification near black holes / neutron stars
	if attractor.body_type in [CelestialBody.BodyType.BLACK_HOLE, CelestialBody.BodyType.NEUTRON_STAR]:
		var rs_au := attractor.schwarzschild_radius / (PhysicsConstants.AU_IN_METERS / 1000.0)
		if rs_au > 0.0 and dist < SPAGHETTIFICATION_FACTOR * rs_au:
			if not body.is_spaghettified:
				body.is_spaghettified = true
				EventBus.body_spaghettified.emit(body.id)
		else:
			body.is_spaghettified = false

	# Tidal locking: slowly align rotation period with orbital period
	if body.orbital_period > 0.0 and dist < 10.0 * r_body_au:
		var target_av := 2.0 * PI / max(body.orbital_period, 0.001)
		body.angular_velocity = lerp(body.angular_velocity, target_av, 0.0001 * dt)
