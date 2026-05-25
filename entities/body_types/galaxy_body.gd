class_name GalaxyBody
extends CelestialBody

enum GalaxyType { SPIRAL, ELLIPTICAL, IRREGULAR, LENTICULAR }
var galaxy_type: int = GalaxyType.SPIRAL
var galaxy_radius: float = 50000.0  # AU (very rough — for display)

func _init() -> void:
	body_type            = BodyType.GALAXY
	stellar_stage        = StellarStage.NONE
	mass                 = 1.0e12        # solar masses
	radius               = 1.0e9        # R_sun (just for gravity calcs)
	surface_temperature  = 2.7          # CMB temperature
	display_name         = "Galaxy"
	hydrogen_fraction    = 0.74

func get_color() -> Color:
	match galaxy_type:
		GalaxyType.SPIRAL:     return Color(0.7, 0.75, 1.0)
		GalaxyType.ELLIPTICAL: return Color(1.0, 0.85, 0.6)
		GalaxyType.IRREGULAR:  return Color(0.65, 1.0, 0.8)
	return Color(0.8, 0.8, 0.9)

func get_visual_radius() -> float:
	return galaxy_radius
