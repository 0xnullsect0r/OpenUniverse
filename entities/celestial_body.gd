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
	NONE,
	NEBULA_STAGE,
	PROTOSTAR,
	MAIN_SEQUENCE,
	SUBGIANT,
	RED_GIANT,
	WHITE_DWARF_STAGE,
	NEUTRON_STAR_STAGE,
	BLACK_HOLE_STAGE,
	DARK_STAR
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
var acceleration: Vector2 = Vector2.ZERO

# -------------------------------------------------------
# Physical
# -------------------------------------------------------
var mass:             float = 1.0
var radius:           float = 1.0
var density:          float = 1.0        # g/cm³ (derived)
var angular_velocity: float = 0.0        # rad/yr
var rotation_period:  float = 1.0        # Earth days (display only)
var axial_tilt:       float = 0.0        # degrees (0 = upright)

# -------------------------------------------------------
# Thermal
# -------------------------------------------------------
var surface_temperature: float = 5778.0
var luminosity:          float = 1.0
var albedo:              float = 0.3
var greenhouse_factor:   float = 1.0
var atmosphere_pressure: float = 0.0     # bar (total pressure)

# -------------------------------------------------------
# Atmospheric composition (fraction 0..1, should sum to ~1)
# -------------------------------------------------------
var atm_n2:          float = 0.0   # nitrogen
var atm_o2:          float = 0.0   # oxygen
var atm_co2:         float = 0.0   # carbon dioxide (greenhouse gas!)
var atm_methane:     float = 0.0   # methane (greenhouse gas!)
var atm_h2:          float = 0.0   # hydrogen
var atm_water_vapor: float = 0.0   # water vapor (greenhouse gas!)
var atm_helium:      float = 0.0   # helium

# -------------------------------------------------------
# Surface materials (fraction 0..1)
# -------------------------------------------------------
var surface_water:   float = 0.0   # liquid water / oceans
var surface_ice:     float = 0.0   # ice / snow cover
var surface_rock:    float = 1.0   # silicate rock crust
var surface_iron:    float = 0.0   # iron / metallic
var surface_methane_lake: float = 0.0  # Titan-like liquid methane

# -------------------------------------------------------
# Lifecycle
# -------------------------------------------------------
var age:               float = 0.0
var stellar_stage:     int   = StellarStage.NONE
var hydrogen_fraction: float = 0.74
var helium_fraction:   float = 0.24
var metallicity:       float = 0.02

# -------------------------------------------------------
# Special / black hole / exotic
# -------------------------------------------------------
var schwarzschild_radius: float = 0.0
var hawking_luminosity:   float = 0.0
var accretion_rate:       float = 0.0
var has_accretion_disc:   bool  = false
var is_white_hole:        bool  = false

# -------------------------------------------------------
# Ring system (gas giants)
# -------------------------------------------------------
var has_rings:         bool  = false
var ring_inner_radius: float = 1.3   # multiplier of visual radius
var ring_outer_radius: float = 2.8
var ring_color:        Color = Color(0.85, 0.78, 0.60, 0.55)

# -------------------------------------------------------
# Impact / collision state (for hot glow)
# -------------------------------------------------------
var impact_timer:   float = 0.0   # seconds since last impact (0 = fresh)
var impact_energy:  float = 0.0   # kinetic energy of impact

# -------------------------------------------------------
# Antimatter & reverse-mode
# -------------------------------------------------------
var is_antimatter:       bool  = false
var _base_is_antimatter: bool  = false

# -------------------------------------------------------
# Orbital (computed each tick by solvers)
# -------------------------------------------------------
var orbital_parent_id: int   = -1
var orbital_period:    float = 0.0
var semi_major_axis:   float = 0.0
var eccentricity:      float = 0.0
var periapsis:         float = 0.0   # AU
var apoapsis:          float = 0.0   # AU
var hill_sphere:       float = 0.0   # AU
var escape_velocity_au: float = 0.0  # AU/yr

# -------------------------------------------------------
# Computed display properties
# -------------------------------------------------------
var surface_gravity:   float = 9.8   # m/s²

# -------------------------------------------------------
# State flags
# -------------------------------------------------------
var is_selected:       bool = false
var is_pinned:         bool = false
var is_fragment:       bool = false
var is_spaghettified:  bool = false
var is_habitable:      bool = false
var user_modified:     bool = false
var is_multi_selected: bool = false

var parent_body_ids:   Array = []

# -------------------------------------------------------
# Entropy (display only)
# -------------------------------------------------------
var entropy: float = 1.0

# -------------------------------------------------------
# Overridable helpers
# -------------------------------------------------------
func get_color() -> Color:
	return _color_for_temperature(surface_temperature)

func get_visual_radius() -> float:
	return radius * PhysicsConstants.SOLAR_RADIUS_AU

func update_derived_properties() -> void:
	_update_schwarzschild()
	_update_density()
	_update_luminosity_from_temperature()
	_update_greenhouse_from_atmosphere()
	_update_surface_gravity()
	_update_escape_velocity()
	_update_albedo_from_surface()

func _update_schwarzschild() -> void:
	if body_type == BodyType.BLACK_HOLE or body_type == BodyType.NEUTRON_STAR:
		schwarzschild_radius = 2.953 * mass

func _update_density() -> void:
	if radius > 0.0:
		var vol := (4.0 / 3.0) * PI * pow(radius * PhysicsConstants.SOLAR_RADIUS_AU * PhysicsConstants.AU_IN_METERS * 0.01, 3.0)
		density = (mass * PhysicsConstants.SOLAR_MASS_KG * 1000.0) / max(vol, 1e-30)

func _update_luminosity_from_temperature() -> void:
	if body_type == BodyType.STAR:
		luminosity = pow(radius, 2.0) * pow(surface_temperature / 5778.0, 4.0)

func _update_greenhouse_from_atmosphere() -> void:
	# Realistic greenhouse effect from CO₂, CH₄, H₂O
	# Each greenhouse gas contributes multiplicatively
	var co2_factor    := 1.0 + atm_co2    * atmosphere_pressure * 3.0
	var methane_factor := 1.0 + atm_methane * atmosphere_pressure * 8.0
	var water_factor  := 1.0 + atm_water_vapor * atmosphere_pressure * 2.0
	greenhouse_factor = co2_factor * methane_factor * water_factor
	greenhouse_factor = clamp(greenhouse_factor, 1.0, 15.0)

func _update_surface_gravity() -> void:
	if radius > 0.0:
		# g = GM/R² in SI
		var R_m := radius * PhysicsConstants.SOLAR_RADIUS_AU * PhysicsConstants.AU_IN_METERS
		var M_kg := mass * PhysicsConstants.SOLAR_MASS_KG
		surface_gravity = 6.674e-11 * M_kg / max(R_m * R_m, 1.0)

func _update_escape_velocity() -> void:
	if radius > 0.0:
		var R_au := radius * PhysicsConstants.SOLAR_RADIUS_AU
		escape_velocity_au = sqrt(2.0 * abs(PhysicsConstants.gravitational_constant()) * mass / max(R_au, 1e-20))

func _update_albedo_from_surface() -> void:
	# Ice increases albedo (bright white); rock is low albedo; water moderate
	albedo = clamp(
		surface_rock * 0.1 + surface_water * 0.35 + surface_ice * 0.7 + surface_iron * 0.15,
		0.05, 0.95
	)
	if albedo == 0.0:
		albedo = 0.3  # default fallback

# -------------------------------------------------------
# Atmospheric helpers
# -------------------------------------------------------
func get_atmosphere_color() -> Color:
	if atmosphere_pressure < 0.001:
		return Color(0, 0, 0, 0)
	# Color the atmosphere based on dominant gas
	if atm_co2 > 0.5:
		return Color(0.8, 0.5, 0.2, 0.6)   # Venus-like orange-brown
	elif atm_n2 > 0.5 and atm_o2 > 0.1:
		return Color(0.3, 0.5, 1.0, 0.4)   # Earth-like blue
	elif atm_methane > 0.5:
		return Color(0.8, 0.6, 1.0, 0.5)   # Titan-like orange-purple
	elif atm_h2 > 0.5:
		return Color(0.7, 0.8, 1.0, 0.4)   # gas giant — pale blue
	elif atm_water_vapor > 0.3:
		return Color(0.5, 0.7, 1.0, 0.5)   # steamy — pale blue
	return Color(0.6, 0.6, 0.7, 0.3)       # generic thin atmosphere

func get_atmosphere_thickness() -> float:
	return clamp(atmosphere_pressure * 0.15, 0.0, 0.5)

# -------------------------------------------------------
# Utility
# -------------------------------------------------------
func _color_for_temperature(temp: float) -> Color:
	if body_type == BodyType.PLANET or body_type == BodyType.MOON:
		return _planet_color()
	if temp < 3500.0:
		return Color(1.0, 0.35, 0.1)
	elif temp < 5000.0:
		return Color(1.0, 0.6, 0.3)
	elif temp < 6000.0:
		return Color(1.0, 0.95, 0.7)
	elif temp < 7500.0:
		return Color(1.0, 1.0, 1.0)
	elif temp < 10000.0:
		return Color(0.7, 0.85, 1.0)
	elif temp < 30000.0:
		return Color(0.5, 0.7, 1.0)
	else:
		return Color(0.4, 0.5, 1.0)

func _planet_color() -> Color:
	# Composite color from surface materials
	var col := Color.BLACK
	col += Color(0.3, 0.55, 0.9) * surface_water
	col += Color(0.9, 0.93, 1.0) * surface_ice
	col += Color(0.6, 0.55, 0.45) * surface_rock
	col += Color(0.45, 0.40, 0.38) * surface_iron
	col += Color(0.65, 0.45, 0.2) * surface_methane_lake
	var total := surface_water + surface_ice + surface_rock + surface_iron + surface_methane_lake
	if total > 0.0:
		col /= total
	else:
		col = Color(0.6, 0.55, 0.45)
	# Hot planet override
	if surface_temperature > 700.0:
		col = col.blend(Color(0.9, 0.4, 0.1, 0.7))
	elif surface_temperature > 1500.0:
		col = Color(0.95, 0.3, 0.05)
	return col

func get_type_name() -> String:
	return BodyType.keys()[body_type]

func get_stage_name() -> String:
	return StellarStage.keys()[stellar_stage]

func is_stellar() -> bool:
	return body_type in [BodyType.STAR, BodyType.NEUTRON_STAR, BodyType.WHITE_DWARF, BodyType.BLACK_HOLE]

func get_temperature_color() -> Color:
	# False-color map for temperature view: blue(cold)→green→yellow→red(hot)
	var t := clamp(log(max(surface_temperature, 2.7)) / log(100000.0), 0.0, 1.0)
	if t < 0.25:
		return Color(0.0, 0.0, t * 4.0)
	elif t < 0.5:
		return Color(0.0, (t - 0.25) * 4.0, 1.0)
	elif t < 0.75:
		return Color((t - 0.5) * 4.0, 1.0, 1.0 - (t - 0.5) * 4.0)
	else:
		return Color(1.0, 1.0 - (t - 0.75) * 4.0, 0.0)

func get_daylight_fraction(star_position: Vector2) -> float:
	# 0.0 = facing away from star (full night), 1.0 = facing star (full day)
	# Simplified: based on position relative to star — actual hemisphere calc
	var to_star := (star_position - position).normalized()
	# In 2D top-down, always half-lit; return 0.5 as default
	return 0.5
