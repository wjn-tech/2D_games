## Context
The project has a mature tile-cell liquid runtime and a player movement controller with gravity, jump buffering, coyote time, and knockback handling. However, movement logic currently has no authoritative water-interaction state, so characters do not physically react to entering water.

This change defines an explicit contract that connects liquid occupancy to character movement and presentation in a deterministic, testable way.

## Goals
- Establish deterministic water interaction states for character controllers.
- Make water movement feel physically distinct while preserving game responsiveness.
- Provide clear presentation cues for water entry, submerged motion, and resurfacing.
- Keep compatibility with existing movement and combat systems.

## Non-Goals
- Replacing grid liquid simulation with full-body fluid dynamics.
- Introducing per-pixel buoyancy solvers.
- Refactoring unrelated animation systems.

## Technical Baseline
- Character movement core: scenes/player.gd
- Liquid runtime authority: src/systems/world/liquid_manager.gd
- Audio/VFX integration points: src/core/audio_manager.gd and existing VFX systems

## Proposed Interaction Model
- Water contact sampling:
  - Sample character foot, torso, and head probes against authoritative liquid occupancy/amount.
  - Compute immersion ratio in [0, 1] from sampled fill.
- State machine:
  - `dry`: immersion below entry threshold.
  - `wading`: feet immersed, torso mostly dry.
  - `swimming`: torso immersed with controlled buoyant movement.
  - `submerged`: head immersed, reduced visibility/air-control profile.
- Movement modifiers:
  - Apply horizontal drag and reduced acceleration as immersion increases.
  - Replace pure gravity with blended buoyancy + gravity curve while immersed.
  - Modulate jump impulse and jump buffering behavior in non-dry states.

## Determinism and Ordering
- Character water state update occurs once per physics tick before final velocity integration.
- Water interaction uses read-only liquid snapshot for the current tick.
- Event hooks emit on state edge transitions only, not continuously each frame.

## Presentation Contract
- Entry/exit events:
  - Trigger splash and one-shot SFX with cooldown gates.
- Sustained movement in water:
  - Trigger looped ripple/wake cues with speed-scaled intensity.
- Surface break:
  - Trigger dedicated break-surface cue to improve readability.
- Underwater clarity:
  - Apply lightweight character readability modulation (not full post-processing in phase 1).

## Compatibility Notes
- Player-first rollout in phase 1.
- NPC adoption in phase 2 via shared utility functions and per-controller opt-in.
- Knockback remains source-of-truth force input but is damped by immersion profile.

## Risks and Mitigations
- Risk: Overdamped controls feel sluggish.
  - Mitigation: Keep state-specific tuning ranges and cap drag multipliers.
- Risk: Event spam during threshold oscillation.
  - Mitigation: Add hysteresis and per-event cooldown.
- Risk: Runtime cost from repeated liquid probes.
  - Mitigation: Fixed small probe count and cached cell lookups per tick.

## Validation Plan
- Functional:
  - Verify transitions across dry/wading/swimming/submerged using deterministic fixtures.
  - Verify movement envelope changes match expected tuning ranges.
- Presentation:
  - Verify entry/exit/surface-break events fire once per transition and respect cooldown.
- Regression:
  - Verify no interference with existing coyote, jump buffer, and knockback paths.

## Rollout Plan
1. Add spec and tests first with toggled integration path.
2. Implement player-only runtime behavior and tune baseline constants.
3. Enable presentation events and throttle rules.
4. Extend to NPC controllers behind explicit feature switch.
5. Document tuning and rollback profile.

## Implementation Notes (2026-03-30)
- Authoritative query contract in `src/systems/world/liquid_manager.gd`:
  - Added `get_liquid_cell_entry(world_pos)` for direct world-cell lookup.
  - Added `get_liquid_amount_at_world_cell(world_pos, liquid_type)` for type-filtered scalar queries.
  - Added `get_liquid_contact_at_global_position(global_pos)` to support controller probe sampling from global positions.
  - Added deterministic global-position mapping helper `_global_to_world_cell(...)`.
- Player runtime integration in `scenes/player.gd`:
  - Added water state model (`dry`, `wading`, `swimming`, `submerged`) and hysteresis thresholds.
  - Added per-tick deterministic update order: probe sample -> state resolve -> motion profile -> velocity integration.
  - Added immersion-based motion profile (`speed_scale`, `accel_scale`, `gravity_scale`, `buoyancy`, `jump_scale`, `max_fall_speed`).
  - Added swim-up semantics for swimming/submerged states while preserving existing coyote/jump buffer flow.
  - Added transition/presentation events (`enter_water`, `exit_water`, `surface_break`, `underwater_loop`) with cooldown throttling.
- Event/audio integration:
  - Added `EventBus` mirrors: `player_water_state_changed`, `player_water_interaction_event`.
  - Added water sound keys and debounce policy in `src/core/audio_manager.gd`.
- Validation additions in `tests/test_worldgen_bedrock_and_liquid.gd`:
  - `_test_liquid_authoritative_contact_query`
  - `_test_player_water_state_thresholds`
  - `_test_player_water_motion_profiles`
  - `_test_player_water_event_throttle`
- Documentation:
  - Added runtime tuning and rollout guide in `docs/character_water_interaction.md`.
