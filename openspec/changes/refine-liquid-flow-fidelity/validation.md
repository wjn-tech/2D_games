## Validation Notes: refine-liquid-flow-fidelity

### Baseline Snapshot (Before)
- Solver pacing
  - MAX_ACTIVE_STEPS_PER_FRAME: 56
  - SIMULATION_BUDGET_MS: 0.75
- Transfer granularity
  - DOWN_FLOW_QUANTUM: 0.0625
  - SIDE_FLOW_QUANTUM: 0.03125
- Per-step transfer caps
  - MAX_DOWN_FLOW_PER_STEP: 0.0625
  - MAX_SIDE_FLOW_PER_STEP: 0.14
- Fall timing
  - WATER_FALL_DELAY_MS / LAVA_FALL_DELAY_MS: 24 / 38
  - WATER_FALL_TRAVEL_MS / LAVA_FALL_TRAVEL_MS: 30 / 45

### Updated Snapshot (After)
- Solver pacing
  - MAX_ACTIVE_STEPS_PER_FRAME: 88
  - SIMULATION_BUDGET_MS: 1.10
- Transfer granularity
  - DOWN_FLOW_QUANTUM: 0.03125
  - SIDE_FLOW_QUANTUM: 0.015625
- Per-step transfer caps
  - MAX_DOWN_FLOW_PER_STEP: 0.05
  - MAX_SIDE_FLOW_PER_STEP: 0.10
- Fall timing
  - WATER_FALL_DELAY_MS / LAVA_FALL_DELAY_MS: 20 / 34
  - WATER_FALL_TRAVEL_MS / LAVA_FALL_TRAVEL_MS: 24 / 40
- New fidelity controls
  - PRESSURE_EQUALIZATION_BUDGET: 320
  - PRESSURE_EQUALIZATION_MIN_DIFF: 0.06
  - PRESSURE_EQUALIZATION_MAX_TRANSFER: 0.046875
  - LATERAL_DIRECTION_MEMORY_MS: 180

### Added Automated Contract Coverage
- tests/test_worldgen_bedrock_and_liquid.gd
  - _test_liquid_flow_fidelity_equalization
  - _test_liquid_flow_direction_stability
  - _test_liquid_persistence_seed_override_guard
  - _test_liquid_flush_runtime_to_chunk_state

### Determinism and Safety Guardrails
- FIFO active queue is preserved.
- Chunk unload prune now also cleans directional-memory state.
- Local pressure equalization is bounded by PRESSURE_EQUALIZATION_BUDGET per idle frame.
- Save/load parity remains enforced by liquid_state_initialized and runtime-to-chunk flush.

### Cave/Basin/Waterfall Scenario Matrix
- Cave cavity drain:
  - Expected: multi-step descent with reduced binary jumps.
  - Covered by: adaptive fall cooldown + micro-step quanta.
- Basin equalization:
  - Expected: reduced checkerboard fronts.
  - Covered by: bounded local pressure equalization pass.
- Waterfall edge stability:
  - Expected: fewer left-right oscillations near equal side capacities.
  - Covered by: short-lived directional memory.

### Environment Note
- Local CLI in this workspace does not expose a runnable godot executable (`godot` command not found), so headless runtime execution cannot be performed in this session.
- Static checks and file diagnostics are clean for all modified files.
