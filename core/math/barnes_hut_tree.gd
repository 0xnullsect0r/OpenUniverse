class_name BarnesHutTree
extends RefCounted

# -------------------------------------------------------
# Barnes-Hut quadtree for O(n log n) N-body gravity.
# Each internal node stores total mass and center of mass
# of all descendants. Traverse with theta criterion.
# -------------------------------------------------------

const THETA := 0.5  # accuracy/speed tradeoff (PhysicsConstants.BARNES_HUT_THETA)

class BHNode:
	var bounds: Rect2
	var total_mass: float  = 0.0
	var center_of_mass: Vector2 = Vector2.ZERO
	var body: CelestialBody = null  # non-null only in leaf nodes
	var children: Array = []        # 4 BHNode or null
	var is_leaf: bool = true

	func _init(b: Rect2) -> void:
		bounds = b
		children.resize(4)

var _root: BHNode = null

# -------------------------------------------------------
# Build from an array of CelestialBody
# -------------------------------------------------------
func build(bodies: Array) -> void:
	if bodies.is_empty():
		_root = null
		return
	var positions := []
	for b in bodies:
		positions.append(b.position)
	var bbox := VectorMath.bounding_box(positions)
	# Make it square
	var size := maxf(bbox.size.x, bbox.size.y)
	bbox = Rect2(bbox.position, Vector2(size, size))

	_root = BHNode.new(bbox)
	for body in bodies:
		_insert(_root, body, 0)

func _insert(node: BHNode, body: CelestialBody, depth: int) -> void:
	if depth > 50:
		return  # safety cap

	# Update mass and CoM
	var total := node.total_mass + body.mass
	if total > 0:
		node.center_of_mass = (node.center_of_mass * node.total_mass + body.position * body.mass) / total
	node.total_mass = total

	if node.is_leaf:
		if node.body == null:
			node.body = body
		else:
			# Split: promote existing body into child, then insert both
			node.is_leaf = false
			_ensure_children(node)
			_insert_to_child(node, node.body, depth + 1)
			node.body = null
			_insert_to_child(node, body, depth + 1)
	else:
		_insert_to_child(node, body, depth + 1)

func _ensure_children(node: BHNode) -> void:
	var hx := node.bounds.size.x * 0.5
	var hy := node.bounds.size.y * 0.5
	var ox := node.bounds.position.x
	var oy := node.bounds.position.y
	node.children[0] = BHNode.new(Rect2(ox,      oy,      hx, hy))  # NW
	node.children[1] = BHNode.new(Rect2(ox + hx, oy,      hx, hy))  # NE
	node.children[2] = BHNode.new(Rect2(ox,      oy + hy, hx, hy))  # SW
	node.children[3] = BHNode.new(Rect2(ox + hx, oy + hy, hx, hy))  # SE

func _insert_to_child(node: BHNode, body: CelestialBody, depth: int) -> void:
	var quad := _quadrant(node.bounds, body.position)
	_insert(node.children[quad], body, depth)

func _quadrant(bounds: Rect2, pos: Vector2) -> int:
	var mid := bounds.position + bounds.size * 0.5
	var east := pos.x >= mid.x
	var south := pos.y >= mid.y
	if not east and not south: return 0  # NW
	if east and not south:     return 1  # NE
	if not east and south:     return 2  # SW
	return 3                             # SE

# -------------------------------------------------------
# Compute gravitational acceleration on body
# -------------------------------------------------------
func compute_acceleration(body: CelestialBody) -> Vector2:
	if _root == null:
		return Vector2.ZERO
	return _traverse(_root, body)

func _traverse(node: BHNode, body: CelestialBody) -> Vector2:
	if node == null or node.total_mass < 1e-30:
		return Vector2.ZERO

	if node.is_leaf:
		if node.body == null or node.body == body:
			return Vector2.ZERO
		return _force_on(body, node.center_of_mass, node.total_mass)

	var d := body.position.distance_to(node.center_of_mass)
	var s := node.bounds.size.x
	if d > 0.0 and (s / d) < THETA:
		return _force_on(body, node.center_of_mass, node.total_mass)

	var acc := Vector2.ZERO
	for child in node.children:
		if child != null:
			acc += _traverse(child, body)
	return acc

func _force_on(body: CelestialBody, other_pos: Vector2, other_mass: float) -> Vector2:
	var diff := other_pos - body.position
	var dist_sq := diff.length_squared() + PhysicsConstants.SOFTENING_AU * PhysicsConstants.SOFTENING_AU
	var dist := sqrt(dist_sq)
	# F = G * m_other / r²  (per unit mass of body) × direction
	# GRAVITY_SIGN flips between attractive and repulsive
	var magnitude := PhysicsConstants.gravitational_constant() * other_mass / dist_sq
	return (diff / dist) * magnitude
