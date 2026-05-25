extends Node

# Body lifecycle
signal body_spawned(body)
signal body_destroyed(id: int)
signal body_selected(body)
signal body_deselected()
signal body_property_changed(id: int, property: String, old_value: Variant, new_value: Variant)

# Simulation events
signal collision_occurred(id_a: int, id_b: int, merged_id: int)
signal fragment_spawned(fragment, parent_ids: Array)
signal stellar_transition(id: int, old_stage: int, new_stage: int)
signal body_spaghettified(id: int)
signal white_hole_emission(id: int, emitted_mass: float)
signal habitability_changed(id: int, is_habitable: bool)
signal impact_flash(position: Vector2, energy: float)
signal supernova_flash(position: Vector2, mass: float)
signal atmosphere_changed(id: int)

# Simulation control
signal reverse_mode_changed(enabled: bool)
signal time_speed_changed(multiplier: float)
signal simulation_paused()
signal simulation_resumed()
signal scenario_loaded(scenario_name: String)
signal timeline_scrubbed(sim_time: float)
signal simulation_reset()

# Tool events
signal laser_fired(position: Vector2, target_id: int, heat: bool)
signal tool_changed(tool: int)

# View changes
signal view_mode_changed(mode: int)
signal overlay_toggled(name: String, enabled: bool)
