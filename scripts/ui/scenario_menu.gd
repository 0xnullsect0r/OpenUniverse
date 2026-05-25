extends PanelContainer

const SCENARIOS := [
	{"name": "Solar System",             "file": "res://data/scenarios/solar_system.json"},
	{"name": "Binary Stars",             "file": "res://data/scenarios/binary_stars.json"},
	{"name": "Three-Body Problem",       "file": "res://data/scenarios/three_body_problem.json"},
	{"name": "TRAPPIST-1 System",        "file": "res://data/scenarios/trappist1.json"},
	{"name": "Black Hole + Star",        "file": "res://data/scenarios/black_hole_star.json"},
	{"name": "Neutron Star",             "file": "res://data/scenarios/neutron_star.json"},
	{"name": "Neutron Star Merger",      "file": "res://data/scenarios/neutron_star_merger.json"},
	{"name": "Rogue Planet",             "file": "res://data/scenarios/rogue_planet.json"},
	{"name": "Collision Course",         "file": "res://data/scenarios/collision_course.json"},
	{"name": "100 Colliding Moons",      "file": "res://data/scenarios/hundred_moons.json"},
	{"name": "Galaxy Collision",         "file": "res://data/scenarios/galaxy_collision.json"},
	{"name": "Terraforming Mars",        "file": "res://data/scenarios/terraforming_mars.json"},
	{"name": "Venus vs Earth",           "file": "res://data/scenarios/venus_earth_comparison.json"},
]

@onready var _vbox: VBoxContainer = $VBox/ScenarioList

func _ready() -> void:
	for s in SCENARIOS:
		var btn := Button.new()
		btn.text = s["name"]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_load_scenario.bind(s["file"]))
		_vbox.add_child(btn)

func _load_scenario(path: String) -> void:
	UniverseManager.load_scenario(path)
	visible = false
