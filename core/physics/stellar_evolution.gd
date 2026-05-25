class_name StellarEvolution
extends RefCounted

# Mass thresholds in solar masses
const MASS_PROTOSTAR_MIN   := 0.08   # below this: brown dwarf (stays as planet-like)
const MASS_WD_MAX          := 8.0    # below: white dwarf end-state
const MASS_NS_MAX          := 20.0   # below: neutron star; above: black hole

# Fusion rate: fraction of H consumed per Myr per solar luminosity
const FUSION_RATE_BASE     := 0.0001
const DE_FUSION_RATE_BASE  := 0.0001  # reverse: H production rate

func advance(body: CelestialBody, dt_years: float) -> void:
	if not body.is_stellar() and body.body_type != CelestialBody.BodyType.NEBULA:
		return

	var dir := PhysicsConstants.STELLAR_EVOLUTION_DIRECTION
	# Age in Myr; dt is in years
	body.age += dir * dt_years / 1_000_000.0

	match body.stellar_stage:
		CelestialBody.StellarStage.NEBULA_STAGE:
			_evolve_nebula(body, dt_years, dir)
		CelestialBody.StellarStage.PROTOSTAR:
			_evolve_protostar(body, dt_years, dir)
		CelestialBody.StellarStage.MAIN_SEQUENCE:
			_evolve_main_sequence(body, dt_years, dir)
		CelestialBody.StellarStage.SUBGIANT:
			_evolve_subgiant(body, dt_years, dir)
		CelestialBody.StellarStage.RED_GIANT:
			_evolve_red_giant(body, dt_years, dir)
		CelestialBody.StellarStage.WHITE_DWARF_STAGE:
			_evolve_white_dwarf(body, dt_years, dir)
		CelestialBody.StellarStage.NEUTRON_STAR_STAGE:
			_evolve_neutron_star(body, dt_years, dir)
		CelestialBody.StellarStage.BLACK_HOLE_STAGE:
			_evolve_black_hole(body, dt_years, dir)
		CelestialBody.StellarStage.DARK_STAR:
			_evolve_dark_star(body, dt_years, dir)

# -------------------------------------------------------
# Stage evolvers
# -------------------------------------------------------
func _evolve_nebula(body: CelestialBody, dt: float, dir: float) -> void:
	if dir > 0:
		# Normal: nebula slowly contracts
		body.radius = max(body.radius * (1.0 - 0.0000001 * dt), 1.0)
		if body.radius < 500.0 and body.mass > MASS_PROTOSTAR_MIN:
			_transition(body, CelestialBody.StellarStage.PROTOSTAR)
	else:
		# Reverse: protostar expands back into nebula (handled when transitioning from protostar)
		pass

func _evolve_protostar(body: CelestialBody, dt: float, dir: float) -> void:
	if dir > 0:
		body.surface_temperature += 0.001 * dt * body.mass
		body.radius *= (1.0 - 0.000001 * dt)
		if body.surface_temperature > 2e6:
			_transition(body, CelestialBody.StellarStage.MAIN_SEQUENCE)
	else:
		body.surface_temperature -= 0.001 * dt * body.mass
		if body.surface_temperature < 500.0:
			_transition(body, CelestialBody.StellarStage.NEBULA_STAGE)

func _evolve_main_sequence(body: CelestialBody, dt: float, dir: float) -> void:
	var fusion_dir := PhysicsConstants.FUSION_DIRECTION
	var rate := FUSION_RATE_BASE * body.luminosity * dt / 1_000_000.0
	body.hydrogen_fraction -= fusion_dir * rate
	body.hydrogen_fraction = clamp(body.hydrogen_fraction, 0.0, 1.0)
	body.helium_fraction   = clamp(body.helium_fraction   + fusion_dir * rate, 0.0, 1.0)

	if dir > 0 and body.hydrogen_fraction < 0.05:
		_transition(body, CelestialBody.StellarStage.SUBGIANT)
	elif dir < 0 and body.hydrogen_fraction > 0.90:
		_transition(body, CelestialBody.StellarStage.PROTOSTAR)

func _evolve_subgiant(body: CelestialBody, dt: float, dir: float) -> void:
	if dir > 0:
		body.radius *= (1.0 + 0.000001 * dt * body.mass)
		body.surface_temperature -= 0.00001 * dt
		if body.radius > body.mass * 5.0:
			_transition(body, CelestialBody.StellarStage.RED_GIANT)
	else:
		body.radius *= (1.0 - 0.000001 * dt * body.mass)
		if body.radius < body.mass * 1.2:
			_transition(body, CelestialBody.StellarStage.MAIN_SEQUENCE)

func _evolve_red_giant(body: CelestialBody, dt: float, dir: float) -> void:
	if dir > 0:
		body.radius *= (1.0 + 0.0000005 * dt)
		if body.mass < MASS_WD_MAX:
			if body.radius > body.mass * 100.0:
				_eject_envelope(body)
				_transition(body, CelestialBody.StellarStage.WHITE_DWARF_STAGE)
		elif body.mass < MASS_NS_MAX:
			if body.radius > body.mass * 50.0:
				_supernova(body, CelestialBody.StellarStage.NEUTRON_STAR_STAGE)
		else:
			if body.radius > body.mass * 30.0:
				_supernova(body, CelestialBody.StellarStage.BLACK_HOLE_STAGE)
	else:
		body.radius *= (1.0 - 0.0000005 * dt)
		if body.radius < body.mass * 5.0:
			_transition(body, CelestialBody.StellarStage.SUBGIANT)

func _evolve_white_dwarf(body: CelestialBody, dt: float, dir: float) -> void:
	if dir > 0:
		# Cooling over billions of years
		body.surface_temperature -= 0.000001 * dt
		body.surface_temperature = max(body.surface_temperature, 2.7)
	else:
		# Reverse: white dwarf heats up
		body.surface_temperature += 0.000001 * dt
		if body.surface_temperature > 50000.0:
			_transition(body, CelestialBody.StellarStage.RED_GIANT)

func _evolve_neutron_star(body: CelestialBody, dt: float, dir: float) -> void:
	if dir < 0:
		# Reverse: neutron star gains energy, eventually reverses supernova
		body.surface_temperature += 0.001 * dt
		if body.surface_temperature > 2e8:
			_reverse_supernova(body, CelestialBody.StellarStage.RED_GIANT)

func _evolve_black_hole(body: CelestialBody, dt: float, dir: float) -> void:
	if dir > 0:
		# Accretion and Hawking evaporation
		body.mass += body.accretion_rate * dt
		var hawk_temp := 6.17e-8 / max(body.mass, 1e-10)
		# Tiny mass loss from Hawking radiation
		body.mass -= body.hawking_luminosity * 1e-40 * dt
		body.mass = max(body.mass, 0.0)
		if body.mass < 1e-30:
			UniverseManager.destroy_body(body.id)
	else:
		# Reverse: black hole loses mass, eventually reverse-supernovas back to red giant
		body.mass -= body.accretion_rate * abs(dt)
		body.mass = max(body.mass, 0.1)
		if body.mass < MASS_NS_MAX * 0.5:
			_reverse_supernova(body, CelestialBody.StellarStage.RED_GIANT)
	body.update_derived_properties()

func _evolve_dark_star(body: CelestialBody, dt: float, dir: float) -> void:
	# Terminal reverse-mode state: absorbs all light, loses energy
	body.surface_temperature = max(body.surface_temperature - 0.01 * dt, 0.0)
	body.luminosity = max(body.luminosity - 0.000001 * dt, -10.0)  # increasingly negative (absorbing)

# -------------------------------------------------------
# Transition helpers
# -------------------------------------------------------
func _transition(body: CelestialBody, new_stage: int) -> void:
	var old_stage := body.stellar_stage
	body.stellar_stage = new_stage
	EventBus.stellar_transition.emit(body.id, old_stage, new_stage)

func _eject_envelope(body: CelestialBody) -> void:
	# Planetary nebula ejection: spawn a nebula fragment
	var neb = UniverseManager.spawn_body(
		CelestialBody.BodyType.NEBULA,
		body.position + Vector2(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1)),
		body.velocity * 0.5
	)
	neb.mass = body.mass * 0.3
	body.mass *= 0.7
	body.radius = 0.0125  # WD radius

func _supernova(body: CelestialBody, next_stage: int) -> void:
	# Eject most mass as fragments, leave remnant
	var ejected_mass := body.mass * 0.8
	body.mass *= 0.2
	var n_frags := 6
	for _i in range(n_frags):
		var rand_vel := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized() * randf_range(1.0, 5.0)
		var frag = UniverseManager.spawn_body(
			CelestialBody.BodyType.NEBULA,
			body.position, body.velocity + rand_vel
		)
		frag.mass = ejected_mass / n_frags
		frag.surface_temperature = 1e6
	# Remnant becomes NS or BH
	_configure_remnant(body, next_stage)
	_transition(body, next_stage)

func _configure_remnant(body: CelestialBody, stage: int) -> void:
	match stage:
		CelestialBody.StellarStage.NEUTRON_STAR_STAGE:
			body.radius = 0.0000144
			body.surface_temperature = 1_000_000.0
			body.body_type = CelestialBody.BodyType.NEUTRON_STAR
			body.display_name = "Neutron Star"
		CelestialBody.StellarStage.BLACK_HOLE_STAGE:
			body.radius = 0.0
			body.body_type = CelestialBody.BodyType.BLACK_HOLE
			body.has_accretion_disc = true
			body.display_name = "Black Hole"
			body.is_white_hole = PhysicsConstants.reverse_mode
	body.update_derived_properties()

func _reverse_supernova(body: CelestialBody, next_stage: int) -> void:
	# Debris COALESCES into a red giant (reverse of supernova)
	body.mass = max(body.mass, 8.0)
	body.radius = body.mass * 50.0
	body.surface_temperature = 3500.0
	body.body_type = CelestialBody.BodyType.STAR
	body.hydrogen_fraction = 0.5
	_transition(body, next_stage)
