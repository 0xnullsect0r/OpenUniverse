extends Node

# -------------------------------------------------------
# Test: Barnes-Hut force matches direct O(n²) within theta tolerance.
# -------------------------------------------------------

func run_tests() -> void:
	print("=== Barnes-Hut Tests ===")
	test_force_matches_direct()
	test_single_body()
	print("=== Barnes-Hut Tests complete ===")

func test_force_matches_direct() -> void:
	PhysicsConstants.reverse_mode = false
	var bodies := []
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in range(50):
		var b := PlanetBody.new()
		b.id = i + 1
		b.mass = rng.randf_range(0.001, 2.0)
		b.position = Vector2(rng.randf_range(-100, 100), rng.randf_range(-100, 100))
		bodies.append(b)

	var target: CelestialBody = bodies[0]

	# Direct sum
	var direct := Vector2.ZERO
	for other in bodies:
		if other == target:
			continue
		var diff := other.position - target.position
		var dist_sq := diff.length_squared() + PhysicsConstants.SOFTENING_AU * PhysicsConstants.SOFTENING_AU
		direct += diff.normalized() * PhysicsConstants.G_SIM * other.mass / dist_sq

	# Barnes-Hut
	var bh := BarnesHutTree.new()
	bh.build(bodies)
	var bh_acc := bh.compute_acceleration(target)

	var error := (bh_acc - direct).length() / max(direct.length(), 1e-10)
	assert(error < 0.15,
		"BH vs direct error too large: %.4f (>15%%)" % error)
	print("  [PASS] BH force error vs direct: %.2f%%" % (error * 100.0))

func test_single_body() -> void:
	var bodies := [PlanetBody.new()]
	bodies[0].mass = 1.0
	bodies[0].position = Vector2.ZERO
	var bh := BarnesHutTree.new()
	bh.build(bodies)
	var acc := bh.compute_acceleration(bodies[0])
	assert(acc == Vector2.ZERO, "Single body should produce zero self-force")
	print("  [PASS] Single body self-force = zero")
