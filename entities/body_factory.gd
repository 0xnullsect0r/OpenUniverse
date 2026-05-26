class_name BodyFactory
extends RefCounted

static func create(type: int, params: Dictionary = {}) -> CelestialBody:
	var body := CelestialBody.new()
	body.body_type = type
	_set_defaults(body, type)

	if params.has("display_name"):        body.display_name         = params["display_name"]
	if params.has("mass"):                body.mass                 = float(params["mass"])
	if params.has("radius"):              body.radius               = float(params["radius"])
	if params.has("surface_temperature"): body.surface_temperature  = float(params["surface_temperature"])
	if params.has("luminosity"):          body.luminosity           = float(params["luminosity"])
	if params.has("age_myr"):             body.age                  = float(params["age_myr"])
	if params.has("spectral_class_int"):  body.spectral_class       = int(params["spectral_class_int"])

	body._base_is_antimatter = PhysicsConstants.ANTIMATTER_BACKGROUND
	body.is_antimatter       = body._base_is_antimatter
	body.update_derived_properties()
	return body

static func _set_defaults(body: CelestialBody, type: int) -> void:
	match type:
		CelestialBody.BodyType.STAR:
			body.display_name        = "Star"
			body.mass                = 1.0
			body.radius              = 1.0
			body.surface_temperature = 5778.0
			body.luminosity          = 1.0
			body.spectral_class      = CelestialBody.SpectralClass.G
			body.stellar_stage       = CelestialBody.StellarStage.MAIN_SEQUENCE
			body.hydrogen_fraction   = 0.74
		CelestialBody.BodyType.PLANET:
			body.display_name        = "Planet"
			body.mass                = 3.0e-6
			body.radius              = 0.009
			body.surface_temperature = 288.0
			body.surface_rock        = 0.7
			body.surface_water       = 0.3
			body.atmosphere_pressure = 1.0
			body.atm_n2              = 0.78
			body.atm_o2              = 0.21
		CelestialBody.BodyType.MOON:
			body.display_name        = "Moon"
			body.mass                = 3.7e-8
			body.radius              = 0.0026
			body.surface_temperature = 200.0
			body.surface_rock        = 1.0
		CelestialBody.BodyType.ASTEROID:
			body.display_name        = "Asteroid"
			body.mass                = 1.0e-10
			body.radius              = 0.0001
			body.surface_temperature = 170.0
			body.surface_rock        = 1.0
		CelestialBody.BodyType.COMET:
			body.display_name        = "Comet"
			body.mass                = 1.0e-11
			body.radius              = 0.00005
			body.surface_temperature = 100.0
			body.surface_ice         = 0.8
			body.surface_rock        = 0.2
		CelestialBody.BodyType.GAS_GIANT:
			body.display_name        = "Gas Giant"
			body.mass                = 0.001
			body.radius              = 0.1
			body.surface_temperature = 165.0
			body.has_rings           = true
			body.atm_h2              = 0.89
			body.atm_helium          = 0.11
			body.atmosphere_pressure = 1000.0
		CelestialBody.BodyType.NEUTRON_STAR:
			body.display_name        = "Neutron Star"
			body.mass                = 1.5
			body.radius              = 0.000014
			body.surface_temperature = 600000.0
			body.stellar_stage       = CelestialBody.StellarStage.NEUTRON_STAR_STAGE
			body.has_accretion_disc  = true
		CelestialBody.BodyType.WHITE_DWARF:
			body.display_name        = "White Dwarf"
			body.mass                = 0.6
			body.radius              = 0.0092
			body.surface_temperature = 25000.0
			body.stellar_stage       = CelestialBody.StellarStage.WHITE_DWARF_STAGE
		CelestialBody.BodyType.BLACK_HOLE:
			body.display_name        = "Black Hole"
			body.mass                = 10.0
			body.radius              = 0.00003
			body.surface_temperature = 1.0e-7
			body.stellar_stage       = CelestialBody.StellarStage.BLACK_HOLE_STAGE
			body.has_accretion_disc  = true
		CelestialBody.BodyType.NEBULA:
			body.display_name        = "Nebula"
			body.mass                = 0.1
			body.radius              = 100.0
			body.surface_temperature = 30.0
			body.stellar_stage       = CelestialBody.StellarStage.NEBULA_STAGE
		CelestialBody.BodyType.GALAXY:
			body.display_name        = "Galaxy"
			body.mass                = 1.0e11
			body.radius              = 30000.0
			body.surface_temperature = 2.7
		_:
			body.display_name        = "Body"
			body.mass                = 1.0e-6
			body.radius              = 0.01
			body.surface_temperature = 200.0

static func make_solar_system_sun() -> CelestialBody:
	return create(CelestialBody.BodyType.STAR)

static func make_earth_like(distance_au: float) -> CelestialBody:
	var b := create(CelestialBody.BodyType.PLANET)
	b.display_name = "Earth-like"
	b.position = Vector2(distance_au, 0.0)
	var v := sqrt(absf(PhysicsConstants.gravitational_constant()) * 1.0 / distance_au)
	b.velocity = Vector2(0.0, v)
	return b
