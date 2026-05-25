extends Node2D

# -------------------------------------------------------
# Root scene — wires toolbar buttons, keyboard shortcuts,
# handles laser/push tool input, and loads default scenario.
# -------------------------------------------------------

@onready var _hud:    CanvasLayer          = $HUD
@onready var _sim_vp: SubViewportContainer = $SimulationViewport

var _laser_solver: LaserSolver = LaserSolver.new()
var _laser_active: bool = false
var _laser_target: int  = -1

func _ready() -> void:
	_wire_toolbar()
	_wire_views_panel()

	$SimulationController.add_to_group("sim_controller")
	var cam := _sim_vp.get_node("SubViewport/Camera2D")
	if cam:
		cam.add_to_group("main_camera")

	# Default scenario
	UniverseManager.load_scenario("res://data/scenarios/solar_system.json")

func _wire_toolbar() -> void:
	var spawn_btn   := _hud.get_node("ToolbarTop/SpawnBtn")
	var scen_btn    := _hud.get_node("ToolbarTop/ScenariosBtn")
	var sett_btn    := _hud.get_node("ToolbarTop/SettingsBtn")
	var focus_btn   := _hud.get_node("ToolbarTop/FocusAllBtn")
	var clear_btn   := _hud.get_node("ToolbarTop/ClearBtn")
	var laser_btn   := _hud.get_node("ToolbarTop/LaserBtn")
	var cool_btn    := _hud.get_node("ToolbarTop/CoolBtn")
	var push_btn    := _hud.get_node("ToolbarTop/PushBtn")
	var step_btn    := _hud.get_node("ToolbarTop/StepBtn")

	var spawn_menu  := _hud.get_node("SpawnMenu")
	var scen_menu   := _hud.get_node("ScenarioMenu")
	var sett_menu   := _hud.get_node("SettingsMenu")

	spawn_btn.pressed.connect(func(): spawn_menu.visible = !spawn_menu.visible)
	scen_btn.pressed.connect(func():  scen_menu.visible  = !scen_menu.visible)
	sett_btn.pressed.connect(func():  sett_menu.visible  = !sett_menu.visible)
	clear_btn.pressed.connect(_on_clear)
	focus_btn.pressed.connect(_on_focus_all)
	laser_btn.pressed.connect(func(): GameState.active_tool = GameState.Tool.LASER_HEAT)
	cool_btn.pressed.connect(func():  GameState.active_tool = GameState.Tool.LASER_COOL)
	push_btn.pressed.connect(func():  GameState.active_tool = GameState.Tool.PUSH)
	step_btn.pressed.connect(GameState.step_frame)

func _wire_views_panel() -> void:
	var vp := _hud.get_node_or_null("ViewsPanel")
	if vp == null:
		return
	var normal_btn  := vp.get_node_or_null("NormalBtn")
	var temp_btn    := vp.get_node_or_null("TempBtn")
	var day_btn     := vp.get_node_or_null("DayBtn")
	var orbits_chk  := vp.get_node_or_null("OrbitsCheck")
	var vel_chk     := vp.get_node_or_null("VelCheck")
	var hz_chk      := vp.get_node_or_null("HZCheck")
	var names_chk   := vp.get_node_or_null("NamesCheck")
	var grid_chk    := vp.get_node_or_null("GridCheck")
	var hill_chk    := vp.get_node_or_null("HillCheck")

	if normal_btn: normal_btn.pressed.connect(func(): GameState.view_mode = GameState.ViewMode.NORMAL)
	if temp_btn:   temp_btn.pressed.connect(func():   GameState.view_mode = GameState.ViewMode.TEMPERATURE_MAP)
	if day_btn:    day_btn.pressed.connect(func():    GameState.view_mode = GameState.ViewMode.DAYLIGHT_VIEW)
	if orbits_chk: orbits_chk.toggled.connect(func(b): GameState.show_orbits = b)
	if vel_chk:    vel_chk.toggled.connect(func(b):    GameState.show_velocity_vectors = b)
	if hz_chk:     hz_chk.toggled.connect(func(b):    GameState.show_habitable_zones = b)
	if names_chk:  names_chk.toggled.connect(func(b): GameState.show_names = b)
	if grid_chk:   grid_chk.toggled.connect(func(b):  GameState.show_grid = b)
	if hill_chk:   hill_chk.toggled.connect(func(b):  GameState.show_hill_spheres = b)

func _process(delta: float) -> void:
	_handle_laser_input(delta)
	_update_tool_cursor()

func _handle_laser_input(delta: float) -> void:
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_laser_active = false
		_laser_target = -1
		return
	if GameState.active_tool == GameState.Tool.SELECT:
		return

	var cam_ctrl := _sim_vp.get_node("SubViewport/Camera2D") as CameraController
	if cam_ctrl == null:
		return
	var mouse_vp := _sim_vp.get_local_mouse_position()
	var sim_pos  := cam_ctrl.screen_to_au(mouse_vp)

	# Find closest body to mouse
	var target: CelestialBody = null
	var best_dist := 0.1  # AU threshold
	for body in UniverseManager.get_all_bodies():
		var d := sim_pos.distance_to(body.position)
		if d < best_dist:
			best_dist = d
			target = body

	if target == null:
		return

	match GameState.active_tool:
		GameState.Tool.LASER_HEAT:
			_laser_solver.apply_laser(target, true, delta)
			EventBus.laser_fired.emit(target.position, target.id, true)
		GameState.Tool.LASER_COOL:
			_laser_solver.apply_laser(target, false, delta)
			EventBus.laser_fired.emit(target.position, target.id, false)
		GameState.Tool.PUSH:
			var push_dir := (target.position - sim_pos).normalized()
			_laser_solver.apply_push(target, push_dir, delta)
		GameState.Tool.PULL:
			var pull_dir := (sim_pos - target.position).normalized()
			_laser_solver.apply_pull(target, pull_dir, delta)

func _update_tool_cursor() -> void:
	match GameState.active_tool:
		GameState.Tool.LASER_HEAT, GameState.Tool.LASER_COOL:
			Input.set_default_cursor_shape(Input.CURSOR_CROSS)
		GameState.Tool.PUSH, GameState.Tool.PULL:
			Input.set_default_cursor_shape(Input.CURSOR_MOVE)
		_:
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _on_clear() -> void:
	UniverseManager.clear_all()
	EventBus.simulation_reset.emit()

func _on_focus_all() -> void:
	var cam := _sim_vp.get_node("SubViewport/Camera2D") as CameraController
	if cam: cam.focus_all()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:     GameState.toggle_pause()
			KEY_PERIOD:    GameState.step_frame()        # . = step one frame
			KEY_EQUAL:     GameState.faster()
			KEY_MINUS:     GameState.slower()
			KEY_R:         PhysicsConstants.reverse_mode = !PhysicsConstants.reverse_mode
			KEY_ESCAPE:
				if GameState.active_tool != GameState.Tool.SELECT:
					GameState.active_tool = GameState.Tool.SELECT
				else:
					GameState.selected_body_id = -1
			KEY_H:         GameState.show_habitable_zones = !GameState.show_habitable_zones
			KEY_O:         GameState.show_orbits = !GameState.show_orbits
			KEY_V:         GameState.show_velocity_vectors = !GameState.show_velocity_vectors
			KEY_N:         GameState.show_names = !GameState.show_names
			KEY_L:         GameState.active_tool = GameState.Tool.LASER_HEAT
			KEY_P:         GameState.active_tool = GameState.Tool.PUSH
			KEY_DELETE:
				if GameState.selected_body_id >= 0:
					UniverseManager.destroy_body(GameState.selected_body_id)
			KEY_F:
				if GameState.selected_body_id >= 0:
					GameState.camera_follow_id = GameState.selected_body_id
