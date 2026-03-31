## 1. Specification
- [x] 1.1 Finalize requirement scenarios for water contact detection, movement modifiers, and state transitions.
- [x] 1.2 Finalize requirement scenarios for presentation feedback (VFX, SFX, readability at waterline).
- [x] 1.3 Define deterministic ordering and fallback behavior for water interaction updates.

## 2. Runtime Design
- [x] 2.1 Define a minimal water-contact query contract from runtime liquid data for character controllers.
- [x] 2.2 Define player water-state model (`dry`, `wading`, `swimming`, `submerged`) and transition guards.
- [x] 2.3 Define movement math for drag, buoyancy, acceleration damping, and jump modulation in each state.
- [x] 2.4 Define compatibility policy for existing knockback, coyote time, jump buffer, and gravity ramps.

## 3. Presentation Design
- [x] 3.1 Define event hooks for `enter_water`, `exit_water`, `surface_break`, and `underwater_loop`.
- [x] 3.2 Define splash/ripple effect budgets and throttling to avoid spam.
- [x] 3.3 Define audio layering policy for water movement and transitions.
- [x] 3.4 Define visual readability rules (waterline cues and submerged character clarity).

## 4. NPC and System Compatibility
- [x] 4.1 Define phase-1 scope for player-first rollout and phase-2 NPC adoption constraints.
- [x] 4.2 Define interactions with combat and projectile systems in water contexts.
- [x] 4.3 Define save/load and chunk-streaming invariants for character water state resets.

## 5. Validation
- [x] 5.1 Add automated behavior tests for entry, submerged traversal, and exit recovery.
- [x] 5.2 Add regression tests for edge cases (thin films, one-tile puddles, waterfalls, cavity boundaries).
- [x] 5.3 Add performance checks for VFX/SFX throttling under repeated contact transitions.

## 6. Documentation and Rollout
- [x] 6.1 Document tuning knobs and recommended ranges for gameplay iteration.
- [x] 6.2 Provide staged rollout and rollback toggles for safe integration.
- [x] 6.3 Record implementation notes mapping code paths to spec requirements.
