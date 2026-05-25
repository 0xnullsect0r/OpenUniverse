class_name BodyFactory
extends RefCounted

static func create(type: int, params: Dictionary = {}) -> CelestialBody:
	var body: CelestialBody
	match type:
		CelestialBody.BodyType.STAR:
			var sc := params.get("spectral_class_int", CelestialBody.SpectralClass.G)
			body = StarBody.new(sc)
		CelestialBody.BodyType.PLANET:
			body = PlanetBody.new()
		CelestialBody.BodyType.MOON:
			body = MoonBody.new()
		CelestialBody.BodyType.ASTEROID:
			body = AsteroidBody.new()
		CelestialBody.BodyType.COMET:
			body = CometBody.new()
		CelestialBody.BodyType.GAS_GIANT:
			body = GasGiantBody.new()
		CelestialBody.BodyType.NEUTRON_STAR:
			body = NeutronStarBody.new()
		CelestialBody.BodyType.WHITE_DWARF:
			body = WhiteDwarfBody.new()
		CelestialBody.BodyType.BLACK_HOLE:
			body = BlackHoleBody.new()
		CelestialBody.BodyType.NEBULA:
			body = NebulaBody.new()
		CelestialBody.BodyType.GALAXY:
			body = GalaxyBody.new()
		_:
			body = PlanetBody.new()

	# Apply any overrides from params
	if params.has("display_name"):    body.display_name         = params["display_name"]
	if params.has("mass"):            body.mass                 = float(params["mass"])
	if params.has("radius"):          body.radius               = float(params["radius"])
	if params.has("surface_temperature"): body.surface_temperature = float(params["surface_temperature"])
	if params.has("luminosity"):      body.luminosity           = float(params["luminosity"])
	if params.has("age_myr"):         body.age                  = float(params["age_myr"])

	body._base_is_antimatter = PhysicsConstants.ANTIMATTER_BACKGROUND
	body.is_antimatter = body._base_is_antimatter
	body.update_derived_properties()
	return body

# Convenience spawn helpers
static func make_solar_system_sun() -> CelestialBody:
	return create(CelestialBody.BodyType.STAR, {"spectral_class_int": CelestialBody.SpectralClass.G})

static func make_earth_like(distance_au: float) -> CelestialBody:
	var b := create(CelestialBody.BodyType.PLANET)
	b.display_name = "Earth-like"
	b.position = Vector2(distance_au, 0.0)
	# Circular orbit velocity: v = sqrt(GM/r)
	var v := sqrt(PhysicsConstants.G_SIM * 1.0 / distance_au)
	b.velocity = Vector2(0.0, v)
	return b
