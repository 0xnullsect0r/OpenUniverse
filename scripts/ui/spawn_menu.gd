extends PanelContainer

# Maps button name → BodyType int
const BODY_BUTTONS := [
	["Star (G)", CelestialBody.BodyType.STAR],
	["Planet", CelestialBody.BodyType.PLANET],
	["Moon", CelestialBody.BodyType.MOON],
	["Gas Giant", CelestialBody.BodyType.GAS_GIANT],
	["Asteroid", CelestialBody.BodyType.ASTEROID],
	["Comet", CelestialBody.BodyType.COMET],
	["Neutron Star", CelestialBody.BodyType.NEUTRON_STAR],
	["White Dwarf", CelestialBody.BodyType.WHITE_DWARF],
	["Black Hole", CelestialBody.BodyType.BLACK_HOLE],
	["Nebula", CelestialBody.BodyType.NEBULA],
	["Galaxy", CelestialBody.BodyType.GALAXY],
]

@onready var _grid: GridContainer = $VBox/Grid
@onready var _pending_label: Label = $VBox/PendingLabel

func _ready() -> void:
	for entry in BODY_BUTTONS:
		var btn := Button.new()
		btn.text = entry[0]
		btn.pressed.connect(_set_pending.bind(entry[1], entry[0]))
		_grid.add_child(btn)
	_pending_label.text = ""

func _set_pending(type: int, name: String) -> void:
	UniverseManager.pending_spawn_type = type
	_pending_label.text = "Click to place: " + name

func _process(_delta: float) -> void:
	if UniverseManager.pending_spawn_type < 0:
		_pending_label.text = ""
