class_name RK4Integrator
extends RefCounted

# Integrates one body's position and velocity over dt (sim years).
# accel_fn: Callable(pos: Vector2, vel: Vector2) -> Vector2
# Modifies body.position and body.velocity in place.
func step(body: CelestialBody, dt: float, accel_fn: Callable) -> void:
	if body.is_pinned:
		return

	var p0 := body.position
	var v0 := body.velocity

	var k1v := accel_fn.call(p0, v0)
	var k1p := v0

	var k2v := accel_fn.call(p0 + k1p * (dt * 0.5), v0 + k1v * (dt * 0.5))
	var k2p := v0 + k1v * (dt * 0.5)

	var k3v := accel_fn.call(p0 + k2p * (dt * 0.5), v0 + k2v * (dt * 0.5))
	var k3p := v0 + k2v * (dt * 0.5)

	var k4v := accel_fn.call(p0 + k3p * dt, v0 + k3v * dt)
	var k4p := v0 + k3v * dt

	body.velocity = v0 + (k1v + k2v * 2.0 + k3v * 2.0 + k4v) * (dt / 6.0)
	body.position = p0 + (k1p + k2p * 2.0 + k3p * 2.0 + k4p) * (dt / 6.0)

	# Inertia damping (reverse mode): objects in motion decelerate
	if PhysicsConstants.INERTIA_DAMPING > 0.0:
		body.velocity *= (1.0 - PhysicsConstants.INERTIA_DAMPING * abs(dt))

	# Vacuum fluctuations (reverse mode): objects at rest get random kicks
	if PhysicsConstants.VACUUM_FLUCTUATION_STRENGTH > 0.0:
		var rand_dir := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		body.velocity += rand_dir * PhysicsConstants.VACUUM_FLUCTUATION_STRENGTH * abs(dt) * 100.0
