class_name CometBody
extends CelestialBody

var tail_length: float = 0.0  # visual only, updated by renderer

func _init() -> void:
	body_type           = BodyType.COMET
	stellar_stage       = StellarStage.NONE
	mass                = 0.00000000001
	radius              = 0.00005
	surface_temperature = 50.0
	albedo              = 0.04
	display_name        = "Comet"
	hydrogen_fraction   = 0.0

func get_color() -> Color:
	return Color(0.8, 0.9, 1.0)  # icy blue-white
