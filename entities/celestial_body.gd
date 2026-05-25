class_name CelestialBody
extends Resource

# -------------------------------------------------------
# Enumerations
# -------------------------------------------------------
enum BodyType {
	STAR, PLANET, MOON, ASTEROID, COMET,
	GAS_GIANT, NEUTRON_STAR, WHITE_DWARF,
	BLACK_HOLE, NEBULA, GALAXY
}

enum SpectralClass { O, B, A, F, G, K, M }

enum StellarStage {
	NONE,           # non-stellar bodies
	NEBULA_STAGE,
	PROTOSTAR,
	MAIN_SEQUENCE,
	SUBGIANT,
	RED_GIANT,
	WHITE_DWARF_STAGE,
	NEUTRON_STAR_STAGE,
	BLACK_HOLE_STAGE,
	DARK_STAR         # reverse-mode terminal: fully light-absorbing collapsed object
}

# -------------------------------------------------------
# Identity
# -------------------------------------------------------
var id:           int    = -1
var display_name: String = "Unknown"
var body_type:    int    = BodyType.PLANET
var spectral_class: int  = SpectralClass.G

# -------------------------------------------------------
# Kinematics  (AU, M_sun, yr)
# -------------------------------------------------------
var position:     Vector2 = Vector2.ZERO
var velocity:     Vector2 = Vector2.ZERO
var acceleration: Vector2 = Vector2.ZERO  # scratch, reset each tick

# -------------------------------------------------------
# Physical
# -------------------------------------------------------
var mass:             float = 1.0        # solar masses
var radius:           float = 1.0        # solar radii
var density:          float = 1.0        # g/cm³ (derived)
var angular_velocity: float = 0.0        # rad/yr (axial spin)

# -------------------------------------------------------
# Thermal
# -------------------------------------------------------
var surface_temperature: float = 5778.0  # Kelvin
var luminosity:          float = 1.0     # solar luminosities
var albedo:              float = 0.3
var greenhouse_factor:   float = 1.0
var atmosphere_pressure: float = 0.0     # bar

# -------------------------------------------------------
# Lifecycle
# -------------------------------------------------------
var age:               float = 0.0       # Myr
var stellar_stage:     int   = StellarStage.NONE
var hydrogen_fraction: float = 0.74
var helium_fraction:   float = 0.24
var metallicity:       float = 0.02

# -------------------------------------------------------
# Special / black hole
# -------------------------------------------------------
var schwarzschild_radius: float = 0.0    # km
var hawking_luminosity:   float = 0.0    # solar luminosities (tiny for stellar BH)
var accretion_rate:       float = 0.0    # M_sun/yr
var has_accretion_disc:   bool  = false
var is_white_hole:        bool  = false

# -------------------------------------------------------
# Antimatter & reverse-mode
# -------------------------------------------------------
var is_antimatter:       bool  = false
var _base_is_antimatter: bool  = false   # original value before mode flip

# -------------------------------------------------------
# Orbital (computed each tick by solvers)
# -------------------------------------------------------
var orbital_parent_id: int   = -1
var orbital_period:    float = 0.0   # yr
var semi_major_axis:   float = 0.0   # AU

# -------------------------------------------------------
# State flags
# -------------------------------------------------------
var is_selected:       bool = false
var is_pinned:         bool = false   # frozen in place
var is_fragment:       bool = false
var is_spaghettified:  bool = false
var is_habitable:      bool = false
var user_modified:     bool = false

var parent_body_ids:   Array = []     # bodies that merged into this one

# -------------------------------------------------------
# Entropy (display only)
# -------------------------------------------------------
var entropy: float = 1.0   # dimensionless, increases in normal mode

# -------------------------------------------------------
# Overridable helpers (subclasses specialise these)
# -------------------------------------------------------
func get_color() -> Color:
	return _color_for_temperature(surface_temperature)

func get_visual_radius() -> float:
	# Returns a display-scale radius in AU
	return radius * PhysicsConstants.SOLAR_RADIUS_AU

func update_derived_properties() -> void:
	_update_schwarzschild()
	_update_density()
	_update_luminosity_from_temperature()

func _update_schwarzschild() -> void:
	if body_type == BodyType.BLACK_HOLE or body_type == BodyType.NEUTRON_STAR:
		# r_s = 2GM/c²;  in km: r_s_km = 2.953 * mass_in_solar_masses
		schwarzschild_radius = 2.953 * mass

func _update_density() -> void:
	if radius > 0.0:
		var vol := (4.0 / 3.0) * PI * pow(radius * PhysicsConstants.SOLAR_RADIUS_AU * PhysicsConstants.AU_IN_METERS * 0.01, 3.0)
		density = (mass * PhysicsConstants.SOLAR_MASS_KG * 1000.0) / max(vol, 1e-30)

func _update_luminosity_from_temperature() -> void:
	if body_type == BodyType.STAR:
		luminosity = pow(radius, 2.0) * pow(surface_temperature / 5778.0, 4.0)

# -------------------------------------------------------
# Utility
# -------------------------------------------------------
func _color_for_temperature(temp: float) -> Color:
	if temp < 3500.0:
		return Color(1.0, 0.35, 0.1)    # M class — orange-red
	elif temp < 5000.0:
		return Color(1.0, 0.6, 0.3)     # K class — orange
	elif temp < 6000.0:
		return Color(1.0, 0.95, 0.7)    # G class — yellow-white
	elif temp < 7500.0:
		return Color(1.0, 1.0, 1.0)     # F class — white
	elif temp < 10000.0:
		return Color(0.7, 0.85, 1.0)    # A class — blue-white
	elif temp < 30000.0:
		return Color(0.5, 0.7, 1.0)     # B class — blue
	else:
		return Color(0.4, 0.5, 1.0)     # O class — deep blue

func get_type_name() -> String:
	return BodyType.keys()[body_type]

func get_stage_name() -> String:
	return StellarStage.keys()[stellar_stage]

func is_stellar() -> bool:
	return body_type in [BodyType.STAR, BodyType.NEUTRON_STAR, BodyType.WHITE_DWARF, BodyType.BLACK_HOLE]
