class_name SimulationController
extends Node

# -------------------------------------------------------
# All physics solvers — created once, reused every tick.
# -------------------------------------------------------
var _gravity:    GravitySolver    = GravitySolver.new()
var _thermal:    ThermalSolver    = ThermalSolver.new()
var _tidal:      TidalSolver      = TidalSolver.new()
var _collision:  CollisionSolver  = CollisionSolver.new()
var _evolution:  StellarEvolution = StellarEvolution.new()
var _rk4:        RK4Integrator    = RK4Integrator.new()
var _timeline:   Timeline         = Timeline.new()

var _tick_count: int = 0

# How many real seconds = 1 sim-year at 1× speed
const REAL_SEC_PER_SIM_YEAR := 1.0

func _ready() -> void:
	EventBus.reverse_mode_changed.connect(_on_reverse_mode_changed)
	EventBus.simulation_reset.connect(_on_reset)

func _physics_process(delta: float) -> void:
	if GameState.is_paused:
		return

	# dt in sim-years. Negative multiplier → rewind via timeline.
	var real_dt := delta * REAL_SEC_PER_SIM_YEAR
	var sim_dt  := real_dt * GameState.time_multiplier

	if sim_dt < 0.0:
		# Rewind: seek backward in timeline
		_timeline.seek(GameState.simulation_time + sim_dt)
		return

	var bodies := UniverseManager.get_all_bodies()
	if bodies.is_empty():
		return

	# ---- 1. Prepare gravity (build BH tree if needed) ----
	_gravity.prepare(bodies)

	# ---- 2. Integrate each body (RK4) ----
	for body in bodies:
		if body.is_pinned:
			continue
		var captured_body := body  # capture for closure
		var accel_fn := func(pos: Vector2, vel: Vector2) -> Vector2:
			var tmp_pos := captured_body.position
			captured_body.position = pos
			var acc := _gravity.compute_acceleration(captured_body, bodies)
			captured_body.position = tmp_pos
			return acc
		_rk4.step(body, sim_dt, accel_fn)

	# ---- 3. Stellar evolution ----
	for body in bodies:
		_evolution.advance(body, sim_dt)

	# ---- 4. Thermal update ----
	_thermal.update(bodies, sim_dt)

	# ---- 5. Tidal forces ----
	_tidal.update(bodies, sim_dt)

	# ---- 6. Collision detection ----
	_collision.update(bodies)

	# ---- 7. Hubble flow ----
	if PhysicsConstants.HUBBLE_SIGN != 1.0 or abs(PhysicsConstants.HUBBLE_SIGN) != 1.0:
		_apply_hubble(bodies, sim_dt)

	# ---- 8. White-hole emissions ----
	for body in bodies:
		if body.is_white_hole:
			_white_hole_emit(body, sim_dt)

	# ---- 9. Orbital parameter update ----
	_update_orbital_params(bodies)

	# ---- 10. Advance sim time ----
	GameState.simulation_time += sim_dt

	# ---- 11. Snapshot ----
	_tick_count += 1
	if _tick_count % PhysicsConstants.SNAPSHOT_INTERVAL == 0:
		_timeline.push_snapshot()

# -------------------------------------------------------
# Hubble flow: each body drifts at H × distance_from_center
# In reverse mode: HUBBLE_SIGN = -1 → contraction
# -------------------------------------------------------
const HUBBLE_H0 := 0.00000007  # AU/yr per AU  (very slow for visual interest)

func _apply_hubble(bodies: Array, dt: float) -> void:
	var center := Vector2.ZERO
	var total_mass := 0.0
	for b in bodies:
		center += b.position * b.mass
		total_mass += b.mass
	if total_mass > 0:
		center /= total_mass

	for body in bodies:
		var displacement := body.position - center
		body.position += displacement * HUBBLE_H0 * PhysicsConstants.HUBBLE_SIGN * dt

# -------------------------------------------------------
# White hole: periodically emit a small mass fragment outward
# -------------------------------------------------------
const WHITE_HOLE_EMIT_INTERVAL := 50  # ticks

func _white_hole_emit(body: CelestialBody, dt: float) -> void:
	if _tick_count % WHITE_HOLE_EMIT_INTERVAL != 0:
		return
	var emit_mass := body.hawking_luminosity * 0.001
	if emit_mass < 1e-20:
		return
	var rand_dir := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	var emit_pos := body.position + rand_dir * (body.get_visual_radius() * 1.5)
	var frag = UniverseManager.spawn_body(
		CelestialBody.BodyType.ASTEROID,
		emit_pos, rand_dir * 0.1 + body.velocity,
		{"mass": emit_mass, "surface_temperature": 1e6, "display_name": "WH Emission"}
	)
	frag.is_fragment = true
	EventBus.white_hole_emission.emit(body.id, emit_mass)

# -------------------------------------------------------
# Orbital parameters (semi-major axis, period) for inspector
# -------------------------------------------------------
func _update_orbital_params(bodies: Array) -> void:
	# Find the dominant attractor for each body
	for body in bodies:
		var best_parent: CelestialBody = null
		var best_dist := INF
		for other in bodies:
			if other == body:
				continue
			if other.mass < body.mass:
				continue
			var d := body.position.distance_to(other.position)
			if d < best_dist:
				best_dist = d
				best_parent = other
		if best_parent != null:
			body.orbital_parent_id = best_parent.id
			body.semi_major_axis   = best_dist
			body.orbital_period    = VectorMath.orbital_period(best_parent.mass, best_dist)
		else:
			body.orbital_parent_id = -1
			body.orbital_period    = 0.0

# -------------------------------------------------------
# Signals
# -------------------------------------------------------
func _on_reverse_mode_changed(_enabled: bool) -> void:
	_timeline.clear()

func _on_reset() -> void:
	_timeline.clear()
	_tick_count = 0

func get_timeline() -> Timeline:
	return _timeline
