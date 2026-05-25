class_name GravitySolver
extends RefCounted

var _bh_tree: BarnesHutTree = BarnesHutTree.new()

# Called once per tick before integration.
func prepare(bodies: Array) -> void:
	if bodies.size() > PhysicsConstants.DIRECT_SUM_THRESHOLD:
		_bh_tree.build(bodies)

# Returns gravitational acceleration on `body` from all others.
func compute_acceleration(body: CelestialBody, bodies: Array) -> Vector2:
	if body.body_type == CelestialBody.BodyType.NEBULA or body.body_type == CelestialBody.BodyType.GALAXY:
		# Treat nebulae/galaxies as background mass — skip expensive integration
		return Vector2.ZERO

	if bodies.size() <= PhysicsConstants.DIRECT_SUM_THRESHOLD:
		return _direct_sum(body, bodies)
	else:
		return _bh_tree.compute_acceleration(body)

func _direct_sum(body: CelestialBody, bodies: Array) -> Vector2:
	var acc := Vector2.ZERO
	var G := PhysicsConstants.gravitational_constant()
	var eps := PhysicsConstants.SOFTENING_AU
	for other in bodies:
		if other == body:
			continue
		var diff := other.position - body.position
		var dist_sq := diff.length_squared() + eps * eps
		var dist := sqrt(dist_sq)
		acc += diff / dist * (G * other.mass / dist_sq)

	# White-hole extra repulsion: emit an additional outward impulse
	if body.is_white_hole:
		for other in bodies:
			if other == body:
				continue
			var dir := (body.position - other.position).normalized()
			acc += dir * body.hawking_luminosity * 0.001

	return acc
