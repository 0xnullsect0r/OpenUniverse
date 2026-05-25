class_name VectorMath
extends RefCounted

static func softened_distance_sq(a: Vector2, b: Vector2, epsilon: float) -> float:
	var d := a.distance_squared_to(b)
	return d + epsilon * epsilon

static func softened_distance(a: Vector2, b: Vector2, epsilon: float) -> float:
	return sqrt(softened_distance_sq(a, b, epsilon))

static func unit_direction(from: Vector2, to: Vector2) -> Vector2:
	var d := to - from
	var l := d.length()
	if l < 1e-30:
		return Vector2.ZERO
	return d / l

static func cross2(a: Vector2, b: Vector2) -> float:
	return a.x * b.y - a.y * b.x

static func rotate_vector(v: Vector2, angle_rad: float) -> Vector2:
	var c := cos(angle_rad)
	var s := sin(angle_rad)
	return Vector2(v.x * c - v.y * s, v.x * s + v.y * c)

static func orbital_velocity(central_mass: float, distance_au: float) -> float:
	return sqrt(abs(PhysicsConstants.gravitational_constant()) * central_mass / max(distance_au, 1e-10))

static func orbital_period(central_mass: float, semi_major_axis_au: float) -> float:
	return 2.0 * PI * sqrt(pow(semi_major_axis_au, 3.0) / max(abs(PhysicsConstants.gravitational_constant()) * central_mass, 1e-30))

static func bounding_box(positions: Array) -> Rect2:
	if positions.is_empty():
		return Rect2(0, 0, 1, 1)
	var mn := Vector2(INF, INF)
	var mx := Vector2(-INF, -INF)
	for p in positions:
		mn.x = min(mn.x, p.x)
		mn.y = min(mn.y, p.y)
		mx.x = max(mx.x, p.x)
		mx.y = max(mx.y, p.y)
	var padding := (mx - mn).length() * 0.05 + 0.01
	return Rect2(mn - Vector2(padding, padding), (mx - mn) + Vector2(padding * 2.0, padding * 2.0))
