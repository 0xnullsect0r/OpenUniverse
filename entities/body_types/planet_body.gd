class_name PlanetBody
extends CelestialBody

func _init() -> void:
	body_type            = BodyType.PLANET
	stellar_stage        = StellarStage.NONE
	mass                 = 0.000003003   # 1 Earth mass in M_sun
	radius               = 0.009167      # 1 Earth radius in R_sun
	surface_temperature  = 288.0
	albedo               = 0.3
	greenhouse_factor    = 1.15
	atmosphere_pressure  = 1.0
	display_name         = "Planet"
	hydrogen_fraction    = 0.0

func get_color() -> Color:
	# Rocky planets: blue-green; hot: orange; frozen: white-blue
	if surface_temperature > 600.0:
		return Color(0.9, 0.5, 0.2)
	elif surface_temperature < 200.0:
		return Color(0.7, 0.85, 1.0)
	elif atmosphere_pressure > 0.5 and surface_temperature > 250.0:
		return Color(0.3, 0.55, 0.9)   # habitable blue
	return Color(0.6, 0.55, 0.45)      # rocky brown
