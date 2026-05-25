extends Node

# -------------------------------------------------------
# Fundamental constants (SI, then simulation-unit forms)
# Simulation units: AU (distance), M_sun (mass), years (time)
# -------------------------------------------------------
const G_SIM         := 39.4784  # AU³ M☉⁻¹ yr⁻²  (4π² from Kepler's 3rd law)
const C_LIGHT_AUyr  := 63241.1  # AU/yr (speed of light)
const SOLAR_MASS_KG := 1.989e30
const AU_IN_METERS  := 1.496e11
const YEAR_IN_SEC   := 3.156e7
const SOLAR_RADIUS_AU := 0.00465047  # 1 R_sun in AU
const STEFAN_BOLTZ  := 5.67e-8       # W m⁻² K⁻⁴
const BOLTZMANN     := 1.381e-23     # J/K
const PLANCK_CONST  := 6.626e-34     # J·s

# Simulation tuning
const SOFTENING_AU       := 0.001    # gravitational softening (AU)
const BARNES_HUT_THETA   := 0.5      # accuracy/speed tradeoff
const SNAPSHOT_INTERVAL  := 30       # ticks between timeline snapshots
const MAX_SNAPSHOTS      := 1000
const TRAIL_MAX_POINTS   := 200
const FRAGMENT_COUNT_MIN := 3
const FRAGMENT_COUNT_MAX := 8

# Body count thresholds for performance mode
const DIRECT_SUM_THRESHOLD := 20     # below this, skip BH tree
const TRAIL_LOD_THRESHOLD  := 200    # above this, trails only for selected body
const POINT_LOD_THRESHOLD  := 400    # above this, pixel-point rendering

# -------------------------------------------------------
# The master toggle
# -------------------------------------------------------
var reverse_mode: bool = false:
	set(value):
		reverse_mode = value
		_rebuild_derived()
		EventBus.reverse_mode_changed.emit(value)

# -------------------------------------------------------
# Tunable reverse-mode coefficients (exposed to settings)
# -------------------------------------------------------
var reverse_damping_coefficient:   float = 0.015
var reverse_fluctuation_scale:     float = 0.0008
var reverse_contraction_rate:      float = 0.00005  # fractional per sim-year

# -------------------------------------------------------
# Derived signed constants — rebuilt on mode change.
# Solvers ALWAYS read these; never hardcode signs.
# -------------------------------------------------------
var GRAVITY_SIGN:                float = 1.0
var ENTROPY_DIRECTION:           float = 1.0
var HEAT_FLOW_DIRECTION:         float = 1.0
var INERTIA_DAMPING:             float = 0.0
var VACUUM_FLUCTUATION_STRENGTH: float = 0.0
var HUBBLE_SIGN:                 float = 1.0
var LIGHT_EMISSION_SIGN:         float = 1.0
var FUSION_DIRECTION:            float = 1.0
var STRONG_FORCE_SIGN:           float = 1.0
var CHARGE_FORCE_SIGN:           float = 1.0
var STELLAR_EVOLUTION_DIRECTION: float = 1.0
var ANTIMATTER_BACKGROUND:       bool  = false

func _ready() -> void:
	_rebuild_derived()

func _rebuild_derived() -> void:
	if reverse_mode:
		GRAVITY_SIGN                = -1.0
		ENTROPY_DIRECTION           = -1.0
		HEAT_FLOW_DIRECTION         = -1.0
		INERTIA_DAMPING             = reverse_damping_coefficient
		VACUUM_FLUCTUATION_STRENGTH = reverse_fluctuation_scale
		HUBBLE_SIGN                 = -1.0
		LIGHT_EMISSION_SIGN         = -1.0
		FUSION_DIRECTION            = -1.0
		STRONG_FORCE_SIGN           = -1.0
		CHARGE_FORCE_SIGN           = -1.0
		STELLAR_EVOLUTION_DIRECTION = -1.0
		ANTIMATTER_BACKGROUND       = true
	else:
		GRAVITY_SIGN                =  1.0
		ENTROPY_DIRECTION           =  1.0
		HEAT_FLOW_DIRECTION         =  1.0
		INERTIA_DAMPING             =  0.0
		VACUUM_FLUCTUATION_STRENGTH =  0.0
		HUBBLE_SIGN                 =  1.0
		LIGHT_EMISSION_SIGN         =  1.0
		FUSION_DIRECTION            =  1.0
		STRONG_FORCE_SIGN           =  1.0
		CHARGE_FORCE_SIGN           =  1.0
		STELLAR_EVOLUTION_DIRECTION =  1.0
		ANTIMATTER_BACKGROUND       = false

# -------------------------------------------------------
# Convenience helpers used by solvers
# -------------------------------------------------------
func gravitational_constant() -> float:
	return G_SIM * GRAVITY_SIGN

func effective_luminosity(base_lum: float) -> float:
	return base_lum * LIGHT_EMISSION_SIGN

func heat_delta(temp_a: float, temp_b: float) -> float:
	return (temp_a - temp_b) * HEAT_FLOW_DIRECTION
