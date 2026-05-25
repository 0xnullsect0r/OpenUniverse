class_name MoonBody
extends CelestialBody

func _init() -> void:
	body_type           = BodyType.MOON
	stellar_stage       = StellarStage.NONE
	mass                = 0.000000123    # ~1 Luna mass in M_sun
	radius              = 0.00254        # ~1 Luna radius in R_sun
	surface_temperature = 220.0
	albedo              = 0.12
	atmosphere_pressure = 0.0
	display_name        = "Moon"
	hydrogen_fraction   = 0.0

func get_color() -> Color:
	return Color(0.75, 0.73, 0.70)  # grey
