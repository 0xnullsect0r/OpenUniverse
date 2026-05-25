class_name WhiteDwarfBody
extends CelestialBody

func _init() -> void:
	body_type            = BodyType.WHITE_DWARF
	stellar_stage        = StellarStage.WHITE_DWARF_STAGE
	mass                 = 0.6           # typical WD mass
	radius               = 0.0125        # ~1.25% of solar radius
	surface_temperature  = 25000.0
	luminosity           = 0.005
	display_name         = "White Dwarf"
	hydrogen_fraction    = 0.0

func get_color() -> Color:
	# Cools over time — hot = blue-white, old = yellow-white
	if surface_temperature > 20000.0:
		return Color(0.75, 0.85, 1.0)
	elif surface_temperature > 10000.0:
		return Color(1.0, 1.0, 1.0)
	return Color(1.0, 0.95, 0.8)
