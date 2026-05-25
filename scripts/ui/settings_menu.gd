extends PanelContainer

# -------------------------------------------------------
# The "Reverse Everything" toggle lives here and is the
# single entry point for flipping PhysicsConstants.reverse_mode.
# -------------------------------------------------------

@onready var _reverse_toggle:     CheckButton = $VBox/ReverseSection/ReverseToggle
@onready var _damping_slider:     HSlider     = $VBox/ReverseSection/DampingSlider
@onready var _fluct_slider:       HSlider     = $VBox/ReverseSection/FluctSlider
@onready var _damping_label:      Label       = $VBox/ReverseSection/DampingLabel
@onready var _fluct_label:        Label       = $VBox/ReverseSection/FluctLabel

@onready var _bh_theta_slider:    HSlider = $VBox/PhysicsSection/BHTheta
@onready var _bh_theta_label:     Label   = $VBox/PhysicsSection/BHThetaLabel

@onready var _gravity_toggle:     CheckButton = $VBox/PhysicsSection/GravityToggle
@onready var _thermal_toggle:     CheckButton = $VBox/PhysicsSection/ThermalToggle
@onready var _collision_toggle:   CheckButton = $VBox/PhysicsSection/CollisionToggle
@onready var _evolution_toggle:   CheckButton = $VBox/PhysicsSection/EvolutionToggle

var _initialising: bool = true

func _ready() -> void:
	# Sync UI to current state
	_reverse_toggle.button_pressed = PhysicsConstants.reverse_mode
	_damping_slider.value          = PhysicsConstants.reverse_damping_coefficient
	_fluct_slider.value            = PhysicsConstants.reverse_fluctuation_scale
	_bh_theta_slider.value         = PhysicsConstants.BARNES_HUT_THETA

	_reverse_toggle.toggled.connect(_on_reverse_toggled)
	_damping_slider.value_changed.connect(_on_damping_changed)
	_fluct_slider.value_changed.connect(_on_fluct_changed)
	_bh_theta_slider.value_changed.connect(_on_bh_theta_changed)

	EventBus.reverse_mode_changed.connect(_on_reverse_mode_changed)
	_initialising = false
	_refresh_reverse_section()

func _on_reverse_toggled(pressed: bool) -> void:
	if _initialising: return
	PhysicsConstants.reverse_mode = pressed
	_refresh_reverse_section()

func _on_reverse_mode_changed(enabled: bool) -> void:
	_initialising = true
	_reverse_toggle.button_pressed = enabled
	_initialising = false
	_refresh_reverse_section()

func _refresh_reverse_section() -> void:
	var enabled := PhysicsConstants.reverse_mode
	_damping_slider.editable = enabled
	_fluct_slider.editable   = enabled
	_reverse_toggle.text = "REVERSE EVERYTHING  [ON]" if enabled else "REVERSE EVERYTHING  [off]"
	if enabled:
		_reverse_toggle.modulate = Color(1.0, 0.3, 0.3)
	else:
		_reverse_toggle.modulate = Color(1.0, 1.0, 1.0)

func _on_damping_changed(value: float) -> void:
	PhysicsConstants.reverse_damping_coefficient = value
	PhysicsConstants._rebuild_derived()
	_damping_label.text = "Velocity damping: %.3f" % value

func _on_fluct_changed(value: float) -> void:
	PhysicsConstants.reverse_fluctuation_scale = value
	PhysicsConstants._rebuild_derived()
	_fluct_label.text = "Vacuum fluctuations: %.4f" % value

func _on_bh_theta_changed(value: float) -> void:
	_bh_theta_label.text = "Barnes-Hut θ: %.2f" % value
	# Note: theta is read directly from PhysicsConstants.BARNES_HUT_THETA (const)
	# This is display-only; a full implementation would make BARNES_HUT_THETA a var.
