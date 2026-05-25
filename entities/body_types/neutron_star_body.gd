class_name NeutronStarBody
extends CelestialBody

var is_pulsar: bool = false
var pulse_period: float = 0.033  # seconds

func _init() -> void:
	body_type            = BodyType.NEUTRON_STAR
	stellar_stage        = StellarStage.NEUTRON_STAR_STAGE
	mass                 = 1.4           # typical NS mass in M_sun
	radius               = 0.0000144     # ~10 km in R_sun
	surface_temperature  = 1_000_000.0
	luminosity           = 0.001
	atmosphere_pressure  = 0.0
	display_name         = "Neutron Star"
	hydrogen_fraction    = 0.0

func update_derived_properties() -> void:
	super.update_derived_properties()
	# NS spin-down rate (very slow on sim timescales)
	if is_pulsar:
		pulse_period += 1.0e-15 * PhysicsConstants.STELLAR_EVOLUTION_DIRECTION

func get_color() -> Color:
	return Color(0.6, 0.85, 1.0)  # pale blue-white
