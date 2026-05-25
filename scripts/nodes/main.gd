extends Node2D

# -------------------------------------------------------
# Root scene script — wires up toolbar buttons and loads
# the default scenario on start.
# -------------------------------------------------------

@onready var _hud: CanvasLayer = $HUD
@onready var _sim_vp: SubViewportContainer = $SimulationViewport

func _ready() -> void:
	# Wire toolbar buttons
	var spawn_btn   := _hud.get_node("ToolbarTop/SpawnBtn")
	var scen_btn    := _hud.get_node("ToolbarTop/ScenariosBtn")
	var sett_btn    := _hud.get_node("ToolbarTop/SettingsBtn")
	var focus_btn   := _hud.get_node("ToolbarTop/FocusAllBtn")
	var clear_btn   := _hud.get_node("ToolbarTop/ClearBtn")

	var spawn_menu  := _hud.get_node("SpawnMenu")
	var scen_menu   := _hud.get_node("ScenarioMenu")
	var sett_menu   := _hud.get_node("SettingsMenu")

	spawn_btn.pressed.connect(func(): spawn_menu.visible = !spawn_menu.visible)
	scen_btn.pressed.connect(func():  scen_menu.visible  = !scen_menu.visible)
	sett_btn.pressed.connect(func():  sett_menu.visible  = !sett_menu.visible)
	clear_btn.pressed.connect(_on_clear)
	focus_btn.pressed.connect(_on_focus_all)

	# Register sim_controller in group for time_controls lookup
	$SimulationController.add_to_group("sim_controller")

	# Register camera in group for scale indicator
	var cam := _sim_vp.get_node("SubViewport/Camera2D")
	if cam:
		cam.add_to_group("main_camera")

	# Load default scenario
	UniverseManager.load_scenario("res://data/scenarios/solar_system.json")

func _on_clear() -> void:
	UniverseManager.clear_all()
	EventBus.simulation_reset.emit()

func _on_focus_all() -> void:
	var cam := _sim_vp.get_node("SubViewport/Camera2D") as CameraController
	if cam:
		cam.focus_all()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE: GameState.toggle_pause()
			KEY_EQUAL, KEY_PLUS: GameState.faster()
			KEY_MINUS:           GameState.slower()
			KEY_R:               PhysicsConstants.reverse_mode = !PhysicsConstants.reverse_mode
			KEY_ESCAPE:          GameState.selected_body_id = -1
