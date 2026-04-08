# Character-Water Interaction Tuning Guide

## Scope
This document describes the phase-1 (player-first) water interaction runtime behavior.

## Runtime Order Contract
1. Sample authoritative liquid contact probes each physics tick (foot/torso/head).
2. Compute immersion ratio and resolve water state (`dry`, `wading`, `swimming`, `submerged`).
3. Build motion profile for this tick.
4. Apply horizontal and vertical modifiers before final velocity integration.
5. Emit transition events with cooldown throttling.

## Key Tuning Knobs
Defined in `scenes/player.gd`.

- State thresholds:
  - `WATER_ENTER_WADING`, `WATER_EXIT_WADING`
  - `WATER_ENTER_SWIMMING_TORSO`, `WATER_EXIT_SWIMMING_TORSO`
  - `WATER_ENTER_SUBMERGED_HEAD`, `WATER_EXIT_SUBMERGED_HEAD`
- Vertical control:
  - `WATER_SWIM_UP_ACCEL`
  - `WATER_SWIM_UP_MAX_SPEED`
- Event throttling:
  - `WATER_EVENT_COOLDOWN_MS`
  - `WATER_LOOP_EVENT_INTERVAL_MS`

## Recommended Ranges
- Wading enter threshold: `0.06 ~ 0.12`
- Swimming torso threshold: `0.20 ~ 0.32`
- Submerged head threshold: `0.24 ~ 0.40`
- Swim-up max speed: `180 ~ 260`
- Loop event interval (ms): `300 ~ 500`

## Presentation Events
The player emits these events:
- `enter_water`
- `exit_water`
- `surface_break`
- `underwater_loop`

EventBus mirrors:
- `player_water_state_changed(state, immersion)`
- `player_water_interaction_event(event_name, immersion)`

## Rollout and Rollback
- Phase 1: player-only behavior enabled in `scenes/player.gd`.
- Phase 2: NPC opt-in should reuse the same threshold/profile policy.
- Rollback lever: short-circuit `_update_water_interaction_state(...)` to keep `_water_state = WATER_STATE_DRY` and default motion profile.

## Compatibility Notes
- Knockback remains source impulse and is not canceled in water.
- Coyote time and jump buffer remain active; swimming/submerged states switch jump semantics to swim-up behavior.
- Water interaction uses authoritative liquid runtime queries (`LiquidManager`) and does not depend on overlay rendering.
