class_name BodyNode
extends Node2D

var body_id: int = -1
var _trail: Line2D
var _name_label: Label
var _last_trail_pos: Vector2 = Vector2.ZERO

# Draw state (updated in _process, used in _draw)
var _draw_radius:   float = 5.0
var _body_color:    Color = Color.WHITE
var _atm_color:     Color = Color.TRANSPARENT
var _atm_thickness: float = 0.0
var _impact_glow:   float = 0.0  # 0..1

func setup(id: int) -> void:
	body_id = id
	_trail = Line2D.new()
	_trail.width = 1.5
	_trail.joint_mode = Line2D.LINE_JOINT_ROUND
	add_child(_trail)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 11)
	_name_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name_label)

	EventBus.reverse_mode_changed.connect(_on_reverse_mode_changed)
	EventBus.impact_flash.connect(_on_impact_flash)

func _process(delta: float) -> void:
	var body := UniverseManager.get_body(body_id)
	if body == null:
		queue_free()
		return

	# Decay impact glow
	if body.impact_timer > 0.0:
		body.impact_timer = max(body.impact_timer - delta, 0.0)
	_impact_glow = clamp(body.impact_timer / 5.0, 0.0, 1.0)

	# Compute screen-space draw radius from simulation radius
	var cam: Camera2D = get_viewport().get_camera_2d()
	var zoom := cam.zoom.x if cam else 1.0
	var cam_ctrl := cam as CameraController
	var ppau := cam_ctrl.pixels_per_au if cam_ctrl else 200.0
	var vis_radius_au := body.get_visual_radius()
	_draw_radius = max(vis_radius_au * ppau * zoom, 3.0)

	# Cache colors for _draw
	_body_color = _get_display_color(body)
	_atm_color     = body.get_atmosphere_color()
	_atm_thickness = body.get_atmosphere_thickness()

	# Update trail
	var screen_pos := global_position
	if _last_trail_pos.distance_to(screen_pos) > 30.0:
		_update_trail(body, screen_pos)
		_last_trail_pos = screen_pos

	# Name label
	_name_label.text = body.display_name if GameState.show_names else ""
	_name_label.position = Vector2(_draw_radius + 4.0, -8.0)
	_name_label.visible = GameState.show_names

	queue_redraw()

func _draw() -> void:
	var body := UniverseManager.get_body(body_id)
	if body == null:
		return

	var col := _body_color

	# ---- Ring system (draw behind body) ----
	if body.has_rings:
		_draw_rings(body)

	# ---- Atmosphere glow ----
	if _atm_thickness > 0.0 and body.atmosphere_pressure > 0.1:
		_draw_atmosphere(body)

	# ---- Daylight / temperature view modes ----
	if GameState.view_mode == GameState.ViewMode.TEMPERATURE_MAP:
		col = body.get_temperature_color()
	elif GameState.view_mode == GameState.ViewMode.DAYLIGHT_VIEW:
		col = _get_daylight_color(body)

	# ---- Main body ----
	draw_circle(Vector2.ZERO, _draw_radius, col)

	# ---- Surface detail overlays ----
	_draw_surface_details(body, col)

	# ---- Hot body glow (molten / freshly impacted) ----
	if body.surface_temperature > 800.0 or _impact_glow > 0.1:
		_draw_heat_glow(body)

	# ---- Supernova glow (main sequence→remnant transition) ----
	if body.stellar_stage == CelestialBody.StellarStage.PROTOSTAR:
		_draw_protostar_haze(body)

	# ---- Accretion disc ----
	if body.has_accretion_disc:
		_draw_accretion_disc(body)

	# ---- Multi-select highlight ----
	if body.is_multi_selected:
		draw_arc(Vector2.ZERO, _draw_radius * 1.5, 0.0, TAU, 64, Color(0.9, 0.6, 0.1, 0.8), 2.0)

	# ---- Selection ring ----
	if body.is_selected:
		draw_arc(Vector2.ZERO, _draw_radius * 1.65, 0.0, TAU, 64, Color(0.15, 0.75, 1.0, 0.95), 2.5)
		draw_arc(Vector2.ZERO, _draw_radius * 1.75, 0.0, TAU, 64, Color(0.15, 0.75, 1.0, 0.25), 1.0)

	# ---- Pinned indicator ----
	if body.is_pinned:
		draw_arc(Vector2.ZERO, _draw_radius * 1.3, 0.0, TAU, 8, Color(1.0, 0.8, 0.0, 0.9), 2.5)

	# ---- Spaghettification ----
	if body.is_spaghettified:
		draw_rect(Rect2(-_draw_radius * 0.25, -_draw_radius * 2.5, _draw_radius * 0.5, _draw_radius * 5.0),
			col * Color(1, 1, 1, 0.7))

	# ---- Habitable zone green dot ----
	if body.is_habitable:
		draw_circle(Vector2(_draw_radius + 7.0, 0.0), 3.5, Color(0.1, 0.95, 0.3, 1.0))

	# ---- Antimatter highlight ----
	if PhysicsConstants.ANTIMATTER_BACKGROUND and not body.is_antimatter:
		draw_arc(Vector2.ZERO, _draw_radius * 1.2, 0.0, TAU, 32, Color(1.0, 0.25, 0.05, 0.85), 3.0)

	# ---- Hill sphere ----
	if GameState.show_hill_spheres and body.hill_sphere > 0.0:
		var cam_ctrl := get_viewport().get_camera_2d() as CameraController
		var ppau := cam_ctrl.pixels_per_au if cam_ctrl else 200.0
		var zoom := get_viewport().get_camera_2d().zoom.x
		var hs_px := body.hill_sphere * ppau * zoom
		draw_arc(Vector2.ZERO, hs_px, 0.0, TAU, 64, Color(0.8, 0.8, 0.2, 0.2), 1.0)

	# ---- Velocity vector ----
	if GameState.show_velocity_vectors and body.velocity.length() > 0.001:
		_draw_velocity_vector(body)

	# ---- Orbit ellipse ----
	if GameState.show_orbits and body.orbital_period > 0.0 and body.orbital_parent_id >= 0:
		_draw_orbit_ellipse(body)

	# ---- Habitable zone ring (around stars) ----
	if GameState.show_habitable_zones and body.body_type == CelestialBody.BodyType.STAR:
		_draw_habitable_zone(body)

# -------------------------------------------------------
# Drawing subroutines
# -------------------------------------------------------
func _draw_rings(body: CelestialBody) -> void:
	var r_inner := _draw_radius * body.ring_inner_radius
	var r_outer := _draw_radius * body.ring_outer_radius
	var rc := body.ring_color
	# Draw concentric arcs to simulate ring depth
	var steps := 8
	for i in range(steps):
		var t := float(i) / steps
		var r := lerp(r_inner, r_outer, t)
		var alpha := rc.a * (1.0 - abs(t - 0.5) * 1.2)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(rc.r, rc.g, rc.b, alpha), 2.5)

func _draw_atmosphere(body: CelestialBody) -> void:
	var n := 6
	for i in range(n):
		var t   := float(i) / n
		var r   := _draw_radius * (1.0 + _atm_thickness * (t + 0.5))
		var a   := _atm_color.a * (1.0 - t) * 0.7
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(_atm_color.r, _atm_color.g, _atm_color.b, a), 3.0)

func _draw_surface_details(body: CelestialBody, base_col: Color) -> void:
	# Ice caps at poles (top and bottom of circle)
	if body.surface_ice > 0.05:
		var ice_r := _draw_radius * clamp(body.surface_ice * 1.5, 0.1, 0.5)
		draw_circle(Vector2(0.0, -_draw_radius * 0.65), ice_r, Color(0.92, 0.95, 1.0, 0.9))
		draw_circle(Vector2(0.0,  _draw_radius * 0.65), ice_r * 0.85, Color(0.92, 0.95, 1.0, 0.9))

	# Ocean glint (slightly darker blue band)
	if body.surface_water > 0.3 and body.surface_temperature < 370.0:
		draw_arc(Vector2.ZERO, _draw_radius * 0.6, 0.3, 1.4, 24, Color(0.2, 0.4, 0.85, 0.3), _draw_radius * 0.35)

	# Gas giant cloud bands
	if body.body_type == CelestialBody.BodyType.GAS_GIANT:
		for i in range(4):
			var t := float(i) / 4.0 - 0.5
			var band_y := t * _draw_radius
			var band_col := base_col.lightened(0.15 * (1 - abs(t) * 2))
			draw_line(Vector2(-_draw_radius, band_y), Vector2(_draw_radius, band_y),
				band_col * Color(1,1,1,0.35), _draw_radius * 0.12)

func _draw_heat_glow(body: CelestialBody) -> void:
	var temp_glow := clamp((body.surface_temperature - 800.0) / 10000.0, 0.0, 1.0)
	var impact_g  := _impact_glow
	var intensity := max(temp_glow, impact_g)
	if intensity < 0.01:
		return

	# Inner bright core for freshly impacted / very hot
	if impact_g > 0.1:
		var flash_col := Color(1.0, 0.9 - impact_g * 0.5, 0.1 * (1.0 - impact_g), impact_g * 0.8)
		draw_circle(Vector2.ZERO, _draw_radius * (1.0 + impact_g * 0.3), flash_col)

	# Radiative glow rings (PBR-inspired: only the hot part emits)
	var glow_col := Color(1.0, 0.4 + temp_glow * 0.4, 0.05, intensity * 0.6)
	for i in range(5):
		var r := _draw_radius * (1.05 + float(i) * 0.15)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, glow_col * Color(1,1,1, 0.4 / (i + 1)), 3.0)

func _draw_protostar_haze(body: CelestialBody) -> void:
	var haze_col := Color(0.8, 0.5, 0.2, 0.2)
	for i in range(3):
		draw_arc(Vector2.ZERO, _draw_radius * (1.5 + i * 0.5), 0.0, TAU, 32,
			haze_col * Color(1,1,1, 0.3/(i+1)), 4.0)

func _draw_accretion_disc(body: CelestialBody) -> void:
	var is_wh := body.is_white_hole
	var disc_col := Color(1.0, 0.55, 0.1) if not is_wh else Color(0.3, 0.8, 1.0)
	var inner_r := _draw_radius * 1.8
	var outer_r := _draw_radius * 4.5
	for i in range(10):
		var t := float(i) / 10.0
		var r := lerp(inner_r, outer_r, t)
		var alpha := disc_col.a * (1.0 - t) * 0.7
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(disc_col.r, disc_col.g, disc_col.b, alpha), 2.0)

	# Relativistic jets for black holes / neutron stars
	if body.body_type in [CelestialBody.BodyType.BLACK_HOLE, CelestialBody.BodyType.NEUTRON_STAR]:
		var jet_dir := -1.0 if is_wh else 1.0
		var jet_col := Color(0.5, 0.7, 1.0, 0.6)
		draw_line(Vector2.ZERO, Vector2(0, -_draw_radius * 6.0 * jet_dir), jet_col, 2.0)
		draw_line(Vector2.ZERO, Vector2(0,  _draw_radius * 6.0 * jet_dir), jet_col, 2.0)

func _draw_velocity_vector(body: CelestialBody) -> void:
	var cam_ctrl := get_viewport().get_camera_2d() as CameraController
	var ppau := cam_ctrl.pixels_per_au if cam_ctrl else 200.0
	var zoom := get_viewport().get_camera_2d().zoom.x
	var vel_screen := body.velocity * ppau * zoom * 0.05
	var arrow_end := vel_screen
	draw_line(Vector2.ZERO, arrow_end, Color(0.2, 1.0, 0.5, 0.85), 1.5)
	# Arrowhead
	var perp := Vector2(-arrow_end.y, arrow_end.x).normalized() * 5.0
	var tip  := arrow_end
	draw_line(tip, tip - arrow_end.normalized() * 8.0 + perp, Color(0.2, 1.0, 0.5, 0.85), 1.5)
	draw_line(tip, tip - arrow_end.normalized() * 8.0 - perp, Color(0.2, 1.0, 0.5, 0.85), 1.5)

func _draw_orbit_ellipse(body: CelestialBody) -> void:
	var parent := UniverseManager.get_body(body.orbital_parent_id)
	if parent == null:
		return
	var cam_ctrl := get_viewport().get_camera_2d() as CameraController
	if cam_ctrl == null:
		return
	var ppau := cam_ctrl.pixels_per_au
	var zoom := get_viewport().get_camera_2d().zoom.x

	# Center of orbit ellipse (parent position in screen space)
	var parent_screen := cam_ctrl.au_to_screen(parent.position)
	var body_screen   := cam_ctrl.au_to_screen(body.position)
	var sma_px        := body.semi_major_axis * ppau * zoom
	var ecc           := clamp(body.eccentricity, 0.0, 0.95)

	# Draw as ellipse approximation using draw_arc from parent node's local space
	# We draw in global coords by converting parent position
	# In Godot 2D, CanvasItem draw calls are in local space.
	# Since this node is at body.position, we offset to parent.
	var offset := (parent_screen - body_screen)
	var semi_b := sma_px * sqrt(1.0 - ecc * ecc)
	var orbit_col := body.get_color() * Color(1, 1, 1, 0.2)
	draw_set_transform(offset, 0.0, Vector2.ONE)
	draw_arc(Vector2.ZERO, sma_px, 0.0, TAU, 64, orbit_col, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_habitable_zone(body: CelestialBody) -> void:
	if body.luminosity <= 0.0:
		return
	var cam_ctrl := get_viewport().get_camera_2d() as CameraController
	if cam_ctrl == null:
		return
	var ppau := cam_ctrl.pixels_per_au
	var zoom := get_viewport().get_camera_2d().zoom.x
	# HZ inner/outer edge (simplified: 0.95 * sqrt(L) and 1.37 * sqrt(L) AU)
	var lum := abs(body.luminosity)
	var hz_inner := 0.95 * sqrt(lum) * ppau * zoom
	var hz_outer := 1.37 * sqrt(lum) * ppau * zoom
	draw_arc(Vector2.ZERO, hz_inner, 0.0, TAU, 64, Color(0.1, 0.9, 0.2, 0.15), hz_outer - hz_inner)
	draw_arc(Vector2.ZERO, hz_inner, 0.0, TAU, 64, Color(0.1, 0.9, 0.2, 0.3), 1.5)
	draw_arc(Vector2.ZERO, hz_outer, 0.0, TAU, 64, Color(0.1, 0.9, 0.2, 0.3), 1.5)

func _get_daylight_color(body: CelestialBody) -> Color:
	# In daylight view: lit side is normal color, dark side is dimmed
	# For top-down 2D we approximate: half circle lit
	return body.get_color()  # Full implementation would split per-pixel

func _get_display_color(body: CelestialBody) -> Color:
	var base := body.get_color()
	if body.stellar_stage == CelestialBody.StellarStage.DARK_STAR:
		return Color(0.04, 0.02, 0.06)
	if body.is_white_hole:
		return Color(1.0, 0.95, 0.5)
	if PhysicsConstants.ANTIMATTER_BACKGROUND and not body.is_antimatter:
		return base.blend(Color(1.0, 0.35, 0.1, 0.4))
	return base

func _update_trail(body: CelestialBody, screen_pos: Vector2) -> void:
	var count := UniverseManager.bodies.size()
	if count > PhysicsConstants.TRAIL_LOD_THRESHOLD and not body.is_selected:
		_trail.clear_points()
		return

	_trail.add_point(screen_pos)
	var max_pts := PhysicsConstants.TRAIL_MAX_POINTS
	if count > 100: max_pts = 80
	while _trail.get_point_count() > max_pts:
		_trail.remove_point(0)

	var trail_col: Color
	if PhysicsConstants.reverse_mode:
		trail_col = Color(0.8, 0.2, 0.5, 0.35)
	elif body.body_type == CelestialBody.BodyType.COMET:
		trail_col = Color(0.7, 0.85, 1.0, 0.5)
	else:
		trail_col = body.get_color() * Color(1, 1, 1, 0.35)
	_trail.default_color = trail_col

func _on_reverse_mode_changed(_enabled: bool) -> void:
	_trail.clear_points()
	queue_redraw()

func _on_impact_flash(flash_pos: Vector2, energy: float) -> void:
	var body := UniverseManager.get_body(body_id)
	if body == null: return
	# Check if this flash is close to our body
	var cam_ctrl := get_viewport().get_camera_2d() as CameraController
	if cam_ctrl == null: return
	var body_screen := cam_ctrl.au_to_screen(body.position)
	var flash_screen := cam_ctrl.au_to_screen(flash_pos)
	if body_screen.distance_to(flash_screen) < _draw_radius * 3.0:
		body.impact_timer = clamp(energy * 10.0, 2.0, 8.0)
		body.impact_energy = energy
