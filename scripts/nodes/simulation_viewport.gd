class_name SimulationViewport
extends SubViewportContainer

@onready var _body_container: Node2D = $SubViewport/BodyContainer
@onready var _camera: CameraController = $SubViewport/Camera2D

var _body_nodes: Dictionary = {}   # body_id -> BodyNode

const BODY_NODE_SCENE := preload("res://scenes/simulation/body_node.tscn")

func _ready() -> void:
	EventBus.body_spawned.connect(_on_body_spawned)
	EventBus.body_destroyed.connect(_on_body_destroyed)
	EventBus.simulation_reset.connect(_on_reset)

	# Handle left-click for selection and spawning
	mouse_filter = Control.MOUSE_FILTER_STOP

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var sim_pos := _camera.screen_to_au(event.position)

		# Check if spawning a new body
		if UniverseManager.pending_spawn_type >= 0:
			UniverseManager.spawn_body(UniverseManager.pending_spawn_type, sim_pos)
			UniverseManager.pending_spawn_type = -1
			return

		# Try to select a body
		_try_select(sim_pos)

func _process(_delta: float) -> void:
	# Sync body node positions from simulation data
	for body_id in _body_nodes:
		var body := UniverseManager.get_body(body_id)
		var node: BodyNode = _body_nodes[body_id]
		if body == null or not is_instance_valid(node):
			continue
		node.global_position = _camera.au_to_screen(body.position)

func _on_body_spawned(body: CelestialBody) -> void:
	var node: BodyNode = BODY_NODE_SCENE.instantiate()
	_body_container.add_child(node)
	node.setup(body.id)
	_body_nodes[body.id] = node

func _on_body_destroyed(id: int) -> void:
	if _body_nodes.has(id):
		var node: BodyNode = _body_nodes[id]
		if is_instance_valid(node):
			node.queue_free()
		_body_nodes.erase(id)

func _on_reset() -> void:
	for node in _body_nodes.values():
		if is_instance_valid(node):
			node.queue_free()
	_body_nodes.clear()

func _try_select(sim_pos: Vector2) -> void:
	var bodies := UniverseManager.get_all_bodies()
	var best_body: CelestialBody = null
	var best_dist := INF
	for body in bodies:
		var d := sim_pos.distance_to(body.position)
		var threshold := maxf(body.get_visual_radius() * 3.0, 0.05)
		if d < threshold and d < best_dist:
			best_dist = d
			best_body = body

	# Deselect old
	if GameState.selected_body_id >= 0:
		var old := UniverseManager.get_body(GameState.selected_body_id)
		if old:
			old.is_selected = false

	if best_body:
		best_body.is_selected = true
		GameState.selected_body_id = best_body.id
	else:
		GameState.selected_body_id = -1

func get_camera() -> CameraController:
	return _camera
