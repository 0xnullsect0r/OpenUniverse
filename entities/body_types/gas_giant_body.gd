class_name GasGiantBody
extends CelestialBody

func _init() -> void:
	body_type            = BodyType.GAS_GIANT
	stellar_stage        = StellarStage.NONE
	mass                 = 0.000954572   # 1 Jupiter mass in M_sun
	radius               = 0.10045       # 1 Jupiter radius in R_sun
	surface_temperature  = 165.0
	albedo               = 0.52
	atmosphere_pressure  = 100.0
	display_name         = "Gas Giant"
	hydrogen_fraction    = 0.90
	helium_fraction      = 0.10

func get_color() -> Color:
	# Banded appearance approximated by temperature/mass
	if mass > 0.005:
		return Color(0.9, 0.75, 0.5)    # hot Jupiter — amber
	return Color(0.8, 0.65, 0.45)       # cold Jupiter — tan
