# Tasks: Implement Grand Sandbox Roadmap

## Hotfixes & Stability
- [x] Fix `WorldGenerator._find_flat_areas` type mismatch error (AI)

## Phase 01: Stabilization (Immediate Focus)

### Project 1: Environmental Visuals (Rain/Snow)
- [x] Implement `WeatherVFX` logic in `WeatherManager` to toggle Particle nodes (AI)
- [ ] Create `RainParticles` and `SnowParticles` nodes in `Main` scene (Manual - Editor)
- [x] Connect `WeatherManager` signals to visual toggle functions (AI)

### Project 2: Depth Layer Finalization
- [x] Update `LayerManager.gd` to handle up to 5 layers with Z-index shifts (AI)
- [ ] Add `LayerUI` buttons to switch view modes (AI Script / Manual Layout)
- [x] Set up `CollisionLayer` and `CollisionMask` constants for each depth (AI)

### Project 3: Attribute Framework UI
- [x] Create `AttributeDisplay` UI component (AI Script / Manual Layout)
- [x] Bind `LifespanManager` data to health/age bars (AI)
- [x] Implement "Death and Inheritance" basic popup when time runs out (AI)

## Phase 02: Economy & Social (Next)

### Project 4: Gathering & Interaction
- [ ] Expand `Gatherable.gd` to drop specific item Resources (AI)
- [ ] Implement "Looting" interaction logic in Player script (AI)

### Project 5: NPC Social Engine
- [ ] Add `relationship` dictionary to `BaseNPC` data (AI)
- [ ] Implement basic "Gift" interaction to increase stats (AI)

## Validation
- [ ] Weather particles trigger correctly when `weather_timer` hits zero.
- [ ] Player can only interact with objects on the same depth layer.
- [ ] Chronometer correctly advances age in the Attribute UI.
