extends PanelContainer

const SCENARIOS := [
	{"name": "Solar System",      "file": "res://data/scenarios/solar_system.json"},
	{"name": "Binary Stars",       "file": "res://data/scenarios/binary_stars.json"},
	{"name": "Black Hole + Star",  "file": "res://data/scenarios/black_hole_star.json"},
	{"name": "Neutron Star",       "file": "res://data/scenarios/neutron_star.json"},
	{"name": "Rogue Planet",       "file": "res://data/scenarios/rogue_planet.json"},
	{"name": "Collision Course",   "file": "res://data/scenarios/collision_course.json"},
]

@onready var _vbox: VBoxContainer = $VBox/ScenarioList

func _ready() -> void:
	for s in SCENARIOS:
		var btn := Button.new()
		btn.text = s["name"]
		btn.pressed.connect(_load_scenario.bind(s["file"]))
		_vbox.add_child(btn)

func _load_scenario(path: String) -> void:
	UniverseManager.load_scenario(path)
	visible = false
