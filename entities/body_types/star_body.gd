class_name StarBody
extends CelestialBody

# Spectral class defaults applied at construction
static var SPECTRAL_DEFAULTS := {
	SpectralClass.O: {"temp": 40000.0, "mass": 30.0,  "radius": 10.0,  "lum": 100000.0},
	SpectralClass.B: {"temp": 20000.0, "mass": 7.0,   "radius": 4.0,   "lum": 1000.0},
	SpectralClass.A: {"temp": 8500.0,  "mass": 2.0,   "radius": 1.7,   "lum": 10.0},
	SpectralClass.F: {"temp": 6700.0,  "mass": 1.3,   "radius": 1.3,   "lum": 2.5},
	SpectralClass.G: {"temp": 5778.0,  "mass": 1.0,   "radius": 1.0,   "lum": 1.0},
	SpectralClass.K: {"temp": 4500.0,  "mass": 0.75,  "radius": 0.85,  "lum": 0.4},
	SpectralClass.M: {"temp": 3200.0,  "mass": 0.3,   "radius": 0.4,   "lum": 0.04},
}

func _init(sc: int = SpectralClass.G) -> void:
	body_type      = BodyType.STAR
	spectral_class = sc
	stellar_stage  = StellarStage.MAIN_SEQUENCE
	var d := SPECTRAL_DEFAULTS[sc]
	surface_temperature = d["temp"]
	mass                = d["mass"]
	radius              = d["radius"]
	luminosity          = d["lum"]
	hydrogen_fraction   = 0.74
	helium_fraction     = 0.24
	display_name        = "Star"
	has_accretion_disc  = false

func get_color() -> Color:
	var base := super.get_color()
	# In reverse mode (absorbing light), darken the star dramatically
	if not PhysicsConstants.ANTIMATTER_BACKGROUND:
		return base
	var t := surface_temperature / 5778.0
	return base.darkened(clamp(1.0 - t * 0.3, 0.0, 0.9))

func update_derived_properties() -> void:
	super.update_derived_properties()
	# Stefan-Boltzmann: L ∝ R² T⁴
	luminosity = pow(radius, 2.0) * pow(surface_temperature / 5778.0, 4.0)
