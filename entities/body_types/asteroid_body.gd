class_name AsteroidBody
extends CelestialBody

func _init() -> void:
	body_type           = BodyType.ASTEROID
	stellar_stage       = StellarStage.NONE
	mass                = 0.0000000001
	radius              = 0.0001
	surface_temperature = 170.0
	albedo              = 0.09
	display_name        = "Asteroid"
	hydrogen_fraction   = 0.0

func get_color() -> Color:
	return Color(0.55, 0.50, 0.45)  # dark grey-brown
