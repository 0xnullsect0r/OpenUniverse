class_name NebulaBody
extends CelestialBody

var cloud_radius: float = 5.0  # AU — visual spread

func _init() -> void:
	body_type            = BodyType.NEBULA
	stellar_stage        = StellarStage.NEBULA_STAGE
	mass                 = 100.0         # solar masses of diffuse gas
	radius               = 1000.0        # effective radius in R_sun (very spread out)
	surface_temperature  = 10.0          # extremely cold
	luminosity           = 0.001
	atmosphere_pressure  = 0.0
	display_name         = "Nebula"
	hydrogen_fraction    = 0.74
	helium_fraction      = 0.24

func get_color() -> Color:
	return Color(0.6, 0.3, 0.8, 0.3)   # semi-transparent purple

func get_visual_radius() -> float:
	return cloud_radius
