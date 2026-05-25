extends ScrollContainer

@onready var _vbox: VBoxContainer = $VBox

var _buttons: Dictionary = {}   # body_id -> Button

func _ready() -> void:
	EventBus.body_spawned.connect(_on_body_spawned)
	EventBus.body_destroyed.connect(_on_body_destroyed)
	EventBus.body_selected.connect(_on_body_selected)
	EventBus.body_deselected.connect(_on_body_deselected)

func _on_body_spawned(body: CelestialBody) -> void:
	var btn := Button.new()
	btn.text = _make_label(body)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.pressed.connect(_on_button_pressed.bind(body.id))
	_vbox.add_child(btn)
	_buttons[body.id] = btn

func _on_body_destroyed(id: int) -> void:
	if _buttons.has(id):
		_buttons[id].queue_free()
		_buttons.erase(id)

func _on_body_selected(body: CelestialBody) -> void:
	for id in _buttons:
		_buttons[id].button_pressed = (id == body.id)

func _on_body_deselected() -> void:
	for btn in _buttons.values():
		btn.button_pressed = false

func _on_button_pressed(id: int) -> void:
	GameState.selected_body_id = id

func _make_label(body: CelestialBody) -> String:
	return "[%s] %s" % [body.get_type_name().left(3), body.display_name]

func _process(_delta: float) -> void:
	# Refresh labels for bodies that may have changed type/name
	for id in _buttons:
		var body := UniverseManager.get_body(id)
		if body:
			_buttons[id].text = _make_label(body)
