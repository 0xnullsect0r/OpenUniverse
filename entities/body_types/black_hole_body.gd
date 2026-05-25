class_name BlackHoleBody
extends CelestialBody

func _init() -> void:
	body_type            = BodyType.BLACK_HOLE
	stellar_stage        = StellarStage.BLACK_HOLE_STAGE
	mass                 = 10.0          # stellar black hole, solar masses
	radius               = 0.0           # physical size irrelevant; use schwarzschild_radius
	surface_temperature  = 0.0
	luminosity           = 0.0
	display_name         = "Black Hole"
	has_accretion_disc   = true
	accretion_rate       = 0.0001        # M_sun/yr
	hydrogen_fraction    = 0.0

func update_derived_properties() -> void:
	super.update_derived_properties()
	# Hawking temperature: T_H = ℏc³ / (8πGMk_B)
	# In display units: T_H ≈ 6.17e-8 / mass_solar_masses  [Kelvin]
	var hawk_temp := 6.17e-8 / max(mass, 1e-10)
	# Hawking luminosity (absurdly small for stellar BH, large for micro-BH)
	hawking_luminosity = pow(hawk_temp, 4.0) * 1e-40

func get_color() -> Color:
	if is_white_hole:
		return Color(1.0, 0.95, 0.5)   # white hole: bright yellow-white corona
	return Color(0.05, 0.02, 0.08)     # near-black with purple tinge

func get_visual_radius() -> float:
	# Show photon sphere for visibility: 1.5 × schwarzschild radius
	var rs_au := schwarzschild_radius / PhysicsConstants.AU_IN_METERS * 1000.0
	return max(rs_au * 1.5, 0.0005)    # minimum visible size
