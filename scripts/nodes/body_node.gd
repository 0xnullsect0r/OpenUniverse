class_name BodyNode
extends Node2D

var body_id: int = -1
var _trail: Line2D
var _last_trail_pos: Vector2 = Vector2.ZERO
const TRAIL_SPACING := 0.5  # AU moved before adding a new trail point

# Glow / selection ring drawn via _draw()
var _draw_radius: float = 5.0  # screen pixels

func setup(id: int) -> void:
	body_id = id
	_trail = Line2D.new()
	_trail.width = 1.0
	_trail.default_color = Color(1, 1, 1, 0.3)
	add_child(_trail)
	EventBus.reverse_mode_changed.connect(_on_reverse_mode_changed)

func _process(_delta: float) -> void:
	var body := UniverseManager.get_body(body_id)
	if body == null:
		queue_free()
		return

	# Position is set by simulation_viewport which converts AU→screen pixels
	# This node's position is already set by SimulationViewport each frame.

	# Update draw radius
	var viewport_node := get_viewport()
	if viewport_node:
		var vp_size := viewport_node.get_visible_rect().size
		# Scale visual radius relative to viewport
		var cam: Camera2D = get_viewport().get_camera_2d()
		var zoom := cam.zoom.x if cam else 1.0
		var vis_radius_au := body.get_visual_radius()
		_draw_radius = max(vis_radius_au * zoom * 200.0, 3.0)

	# Update trail
	var body_screen_pos := global_position
	if _last_trail_pos.distance_to(body_screen_pos) > TRAIL_SPACING * 50.0:
		_update_trail(body, body_screen_pos)
		_last_trail_pos = body_screen_pos

	queue_redraw()

func _draw() -> void:
	var body := UniverseManager.get_body(body_id)
	if body == null:
		return

	var col := _get_display_color(body)

	# Main body circle
	draw_circle(Vector2.ZERO, _draw_radius, col)

	# Glow ring
	draw_arc(Vector2.ZERO, _draw_radius * 1.15, 0.0, TAU, 32, col * Color(1, 1, 1, 0.3), 2.0)

	# Selection ring
	if body.is_selected:
		draw_arc(Vector2.ZERO, _draw_radius * 1.6, 0.0, TAU, 64, Color(0.2, 0.8, 1.0, 0.9), 2.0)
		draw_arc(Vector2.ZERO, _draw_radius * 1.7, 0.0, TAU, 64, Color(0.2, 0.8, 1.0, 0.3), 1.0)

	# Pinned indicator
	if body.is_pinned:
		draw_arc(Vector2.ZERO, _draw_radius * 1.4, 0.0, TAU, 8, Color(1.0, 0.8, 0.0, 0.8), 2.0)

	# Spaghettification: elongate along vector to nearest massive body
	if body.is_spaghettified:
		draw_rect(Rect2(-_draw_radius * 0.3, -_draw_radius * 2.0, _draw_radius * 0.6, _draw_radius * 4.0),
			col * Color(1, 1, 1, 0.6))

	# Habitable indicator
	if body.is_habitable:
		draw_circle(Vector2(_draw_radius + 6.0, 0.0), 3.0, Color(0.2, 1.0, 0.3, 0.9))

	# Antimatter exotic matter highlight (regular matter in antimatter universe)
	if PhysicsConstants.ANTIMATTER_BACKGROUND and not body.is_antimatter:
		draw_arc(Vector2.ZERO, _draw_radius * 1.25, 0.0, TAU, 32, Color(1.0, 0.3, 0.1, 0.8), 3.0)

func _get_display_color(body: CelestialBody) -> Color:
	var base := body.get_color()
	# In reverse mode, dark stars are very dark
	if body.stellar_stage == CelestialBody.StellarStage.DARK_STAR:
		return Color(0.05, 0.03, 0.08)
	# White holes glow bright
	if body.is_white_hole:
		return Color(1.0, 0.95, 0.5, 1.0)
	# Antimatter background: regular matter is dim red-orange rim
	if PhysicsConstants.ANTIMATTER_BACKGROUND and not body.is_antimatter:
		return base.blend(Color(1.0, 0.4, 0.1, 0.4))
	return base

func _update_trail(body: CelestialBody, screen_pos: Vector2) -> void:
	# LOD: skip trails for non-selected bodies when there are many bodies
	var count := UniverseManager.bodies.size()
	if count > PhysicsConstants.TRAIL_LOD_THRESHOLD and not body.is_selected:
		_trail.clear_points()
		return

	_trail.add_point(screen_pos)

	var max_pts := PhysicsConstants.TRAIL_MAX_POINTS
	if count > 100:
		max_pts = 80
	while _trail.get_point_count() > max_pts:
		_trail.remove_point(0)

	# Trail color based on mode and body type
	var trail_col: Color
	if PhysicsConstants.reverse_mode:
		trail_col = Color(0.8, 0.2, 0.5, 0.4)   # magenta-purple in reverse
	else:
		trail_col = body.get_color() * Color(1, 1, 1, 0.35)
	_trail.default_color = trail_col

func _on_reverse_mode_changed(_enabled: bool) -> void:
	_trail.clear_points()
	queue_redraw()
