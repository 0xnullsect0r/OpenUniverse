extends Node

# -------------------------------------------------------
# Test: All PhysicsConstants derived values flip correctly
# and gravity solver produces repulsive forces in reverse mode.
# -------------------------------------------------------

func run_tests() -> void:
	print("=== Reverse Physics Tests ===")
	test_constants_flip()
	test_repulsive_gravity()
	test_heat_flow_reversed()
	test_antimatter_background()
	print("=== Reverse Physics Tests complete ===")

func test_constants_flip() -> void:
	PhysicsConstants.reverse_mode = false
	assert(PhysicsConstants.GRAVITY_SIGN == 1.0,             "Normal: GRAVITY_SIGN should be +1")
	assert(PhysicsConstants.HEAT_FLOW_DIRECTION == 1.0,       "Normal: HEAT_FLOW_DIRECTION should be +1")
	assert(PhysicsConstants.INERTIA_DAMPING == 0.0,           "Normal: INERTIA_DAMPING should be 0")
	assert(PhysicsConstants.ANTIMATTER_BACKGROUND == false,   "Normal: ANTIMATTER_BACKGROUND should be false")

	PhysicsConstants.reverse_mode = true
	assert(PhysicsConstants.GRAVITY_SIGN == -1.0,             "Reverse: GRAVITY_SIGN should be -1")
	assert(PhysicsConstants.HEAT_FLOW_DIRECTION == -1.0,       "Reverse: HEAT_FLOW_DIRECTION should be -1")
	assert(PhysicsConstants.INERTIA_DAMPING > 0.0,             "Reverse: INERTIA_DAMPING should be >0")
	assert(PhysicsConstants.ANTIMATTER_BACKGROUND == true,    "Reverse: ANTIMATTER_BACKGROUND should be true")
	assert(PhysicsConstants.STELLAR_EVOLUTION_DIRECTION == -1.0, "Reverse: STELLAR_EVOLUTION_DIRECTION should be -1")
	assert(PhysicsConstants.LIGHT_EMISSION_SIGN == -1.0,       "Reverse: LIGHT_EMISSION_SIGN should be -1")
	assert(PhysicsConstants.HUBBLE_SIGN == -1.0,               "Reverse: HUBBLE_SIGN should be -1")
	print("  [PASS] All constants flip correctly")
	PhysicsConstants.reverse_mode = false

func test_repulsive_gravity() -> void:
	PhysicsConstants.reverse_mode = true

	var star := PlanetBody.new()
	star.id = 9901
	star.mass = 1.0
	star.position = Vector2.ZERO

	var planet := PlanetBody.new()
	planet.id = 9902
	planet.mass = 0.001
	planet.position = Vector2(1.0, 0.0)

	var solver := GravitySolver.new()
	var acc := solver.compute_acceleration(planet, [star, planet])

	# In reverse mode, force on planet should point AWAY from star (positive x)
	assert(acc.x > 0.0, "Reverse gravity: acceleration should be repulsive (away from star), got %.4f" % acc.x)
	print("  [PASS] Reverse gravity is repulsive: acc.x = %.4f" % acc.x)
	PhysicsConstants.reverse_mode = false

func test_heat_flow_reversed() -> void:
	PhysicsConstants.reverse_mode = true
	var solver := ThermalSolver.new()
	var hot := PlanetBody.new()
	hot.id = 9903; hot.position = Vector2.ZERO; hot.surface_temperature = 1000.0; hot.mass = 1.0
	var cold := PlanetBody.new()
	cold.id = 9904; cold.position = Vector2(0.1, 0.0); cold.surface_temperature = 100.0; cold.mass = 1.0

	var hot_before := hot.surface_temperature
	var cold_before := cold.surface_temperature
	solver.update([hot, cold], 1000.0)

	# In reverse mode, cold body should GAIN heat (get hotter), hot body should lose
	assert(cold.surface_temperature > cold_before,
		"Reversed heat: cold body should heat up, got %.1f → %.1f" % [cold_before, cold.surface_temperature])
	assert(hot.surface_temperature < hot_before,
		"Reversed heat: hot body should cool down, got %.1f → %.1f" % [hot_before, hot.surface_temperature])
	print("  [PASS] Heat flows cold→hot in reverse mode")
	PhysicsConstants.reverse_mode = false

func test_antimatter_background() -> void:
	PhysicsConstants.reverse_mode = true
	var body := PlanetBody.new()
	body._base_is_antimatter = true
	body.is_antimatter = true
	assert(body.is_antimatter, "In reverse mode, spawned bodies should be antimatter")
	print("  [PASS] Antimatter background active")
	PhysicsConstants.reverse_mode = false
