class_name CollisionSolver
extends RefCounted

const MERGE_MASS_RATIO := 10.0  # larger/smaller > this → merge

var _pending_merges: Array = []
var _pending_fragments: Array = []

func update(bodies: Array) -> void:
	_pending_merges.clear()
	_pending_fragments.clear()

	var checked := {}
	for i in range(bodies.size()):
		var a: CelestialBody = bodies[i]
		for j in range(i + 1, bodies.size()):
			var b: CelestialBody = bodies[j]
			var key := str(min(a.id, b.id)) + "_" + str(max(a.id, b.id))
			if checked.has(key):
				continue
			checked[key] = true

			if _are_colliding(a, b):
				_resolve(a, b)

	# Process deferred merges / fragments via UniverseManager
	for merge_data in _pending_merges:
		_do_merge(merge_data[0], merge_data[1])
	for frag_data in _pending_fragments:
		_do_fragment(frag_data[0], frag_data[1])

func _are_colliding(a: CelestialBody, b: CelestialBody) -> bool:
	# Nebulae and galaxies don't collide normally
	if a.body_type in [CelestialBody.BodyType.NEBULA, CelestialBody.BodyType.GALAXY]:
		return false
	if b.body_type in [CelestialBody.BodyType.NEBULA, CelestialBody.BodyType.GALAXY]:
		return false
	var dist := a.position.distance_to(b.position)
	var min_dist := a.get_visual_radius() + b.get_visual_radius()
	return dist < min_dist

func _resolve(a: CelestialBody, b: CelestialBody) -> void:
	# Antimatter annihilation check
	if a.is_antimatter != b.is_antimatter:
		_annihilate(a, b)
		return

	var ratio := max(a.mass, b.mass) / max(min(a.mass, b.mass), 1e-30)
	if ratio >= MERGE_MASS_RATIO:
		var bigger  := a if a.mass > b.mass else b
		var smaller := b if a.mass > b.mass else a
		_pending_merges.append([bigger, smaller])
	else:
		_pending_fragments.append([a, b])

func _do_merge(big: CelestialBody, small: CelestialBody) -> void:
	# Conserve momentum; big absorbs small
	var total_mass := big.mass + small.mass
	big.velocity = (big.velocity * big.mass + small.velocity * small.mass) / total_mass
	big.mass = total_mass
	big.radius = pow(pow(big.radius, 3.0) + pow(small.radius, 3.0), 1.0 / 3.0)
	big.surface_temperature = (
		(big.surface_temperature * big.mass + small.surface_temperature * small.mass) / total_mass
	)
	big.update_derived_properties()
	EventBus.collision_occurred.emit(big.id, small.id, big.id)
	UniverseManager.destroy_body(small.id)

func _do_fragment(a: CelestialBody, b: CelestialBody) -> void:
	var total_mass     := a.mass + b.mass
	var total_momentum := a.velocity * a.mass + b.velocity * b.mass
	var avg_temp       := (a.surface_temperature + b.surface_temperature) * 0.5
	var avg_pos        := (a.position + b.position) * 0.5
	var n_frags        := randi_range(
		PhysicsConstants.FRAGMENT_COUNT_MIN,
		PhysicsConstants.FRAGMENT_COUNT_MAX
	)
	var frag_mass := total_mass / float(n_frags)

	EventBus.collision_occurred.emit(a.id, b.id, -1)
	UniverseManager.destroy_body(a.id)
	UniverseManager.destroy_body(b.id)

	for _i in range(n_frags):
		var rand_vel := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		rand_vel *= randf_range(0.1, 1.0)
		var frag_vel := total_momentum / total_mass + rand_vel * 0.5
		var frag_pos := avg_pos + Vector2(randf_range(-0.01, 0.01), randf_range(-0.01, 0.01))

		var frag = UniverseManager.spawn_body(
			CelestialBody.BodyType.ASTEROID,
			frag_pos, frag_vel,
			{"mass": frag_mass, "surface_temperature": avg_temp}
		)
		frag.is_fragment = true
		frag.parent_body_ids = [a.id, b.id]
		EventBus.fragment_spawned.emit(frag, [a.id, b.id])

func _annihilate(a: CelestialBody, b: CelestialBody) -> void:
	# Matter-antimatter annihilation: destroy both, radiate energy
	var energy_pos := (a.position + b.position) * 0.5
	# Spawn a brief high-temperature "gamma burst" fragment
	var burst = UniverseManager.spawn_body(
		CelestialBody.BodyType.ASTEROID,
		energy_pos, Vector2.ZERO,
		{"mass": 0.0, "surface_temperature": 1e9, "display_name": "Annihilation"}
	)
	burst.is_fragment = true
	EventBus.collision_occurred.emit(a.id, b.id, burst.id)
	UniverseManager.destroy_body(a.id)
	UniverseManager.destroy_body(b.id)
