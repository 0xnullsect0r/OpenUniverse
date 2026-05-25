extends Node

# -------------------------------------------------------
# Test: RK4 integrator conserves energy in a 2-body orbit.
# Run from a test scene or GUT framework.
# -------------------------------------------------------

func run_tests() -> void:
	print("=== RK4 Tests ===")
	test_circular_orbit()
	test_reverse_damping()
	print("=== RK4 Tests complete ===")

func test_circular_orbit() -> void:
	# Earth-like orbit around 1 M_sun star should maintain ~1 AU distance
	PhysicsConstants.reverse_mode = false

	var star := PlanetBody.new()
	star.mass = 1.0
	star.position = Vector2.ZERO
	star.velocity = Vector2.ZERO
	star.is_pinned = true

	var planet := PlanetBody.new()
	planet.mass = 3e-6
	planet.position = Vector2(1.0, 0.0)
	# Circular orbit velocity
	var v := sqrt(PhysicsConstants.G_SIM * star.mass / 1.0)
	planet.velocity = Vector2(0.0, v)

	var rk4 := RK4Integrator.new()
	var bodies := [star, planet]

	# Integrate for 1 full orbit (~1 year)
	var dt := 0.001  # sim years
	var steps := 1000
	for _i in range(steps):
		var accel_fn := func(_pos, _vel) -> Vector2:
			var diff := star.position - planet.position
			var dist_sq := diff.length_squared() + PhysicsConstants.SOFTENING_AU * PhysicsConstants.SOFTENING_AU
			return diff.normalized() * PhysicsConstants.G_SIM * star.mass / dist_sq
		rk4.step(planet, dt, accel_fn)

	var final_dist := planet.position.distance_to(star.position)
	assert(abs(final_dist - 1.0) < 0.05,
		"Circular orbit: distance should be ~1 AU, got %.4f" % final_dist)
	print("  [PASS] Circular orbit distance: %.4f AU" % final_dist)

func test_reverse_damping() -> void:
	# In reverse mode, a body with initial velocity should slow down
	PhysicsConstants.reverse_mode = true

	var body := PlanetBody.new()
	body.mass = 1.0
	body.position = Vector2.ZERO
	body.velocity = Vector2(10.0, 0.0)

	var rk4 := RK4Integrator.new()
	var dt := 0.01
	for _i in range(100):
		var accel_fn := func(_pos, _vel) -> Vector2: return Vector2.ZERO
		rk4.step(body, dt, accel_fn)

	assert(body.velocity.length() < 5.0,
		"Reverse damping: speed should have decreased from 10 to <5, got %.4f" % body.velocity.length())
	print("  [PASS] Reverse damping: speed = %.4f AU/yr" % body.velocity.length())

	PhysicsConstants.reverse_mode = false
