## 1. Planning and Contract Alignment
- [ ] 1.1 Confirm topology single-source-of-truth for circumference and wrap helpers across player/chunk/generator paths.
- [ ] 1.2 Define measurable acceptance matrix for seeds and world size presets (small/medium/large).
- [ ] 1.3 Finalize migration policy for legacy saves that do not satisfy new metadata/version requirements.

## 2. Player Wraparound Integrity
- [ ] 2.1 Enforce deterministic east-west wraparound in runtime movement without breaking physics continuity.
- [ ] 2.2 Align camera and chunk streaming behavior at seam crossing.
- [ ] 2.3 Add seam traversal regression checks for both directions and repeated crossings.

## 3. Underground Strata and Liquid Fidelity
- [ ] 3.1 Implement variable soil thickness and depth-dependent material transitions with deterministic noise contracts.
- [ ] 3.2 Implement material intermix pass for dirt-in-stone and stone-in-dirt with bounded density.
- [ ] 3.3 Ensure liquid pockets/channels are generated in configured depth bands and remain observable after settle pass.
- [ ] 3.4 Add safeguards for spawn-safe and critical traversal paths against blocking liquid hazards.

## 4. Surface Biome Coverage and Natural Boundaries
- [ ] 4.1 Enforce minimum major-biome count and maximum single-biome span per world-size preset.
- [ ] 4.2 Add domain-warped biome boundary displacement with vertical decorrelation.
- [ ] 4.3 Enforce blend corridor width bounds to prevent straight hard cuts.
- [ ] 4.4 Add exploration-based validation pass that confirms biome diversity over full circumference traversal.

## 5. 107-Step Behavior Audit
- [ ] 5.1 Extend 107-step telemetry to assert behavior outcomes for key mapped steps, not just catalog presence.
- [ ] 5.2 Add explicit audit outputs for intermix-related steps and liquid-related steps.
- [ ] 5.3 Fail validation when mapped steps claim implemented/adapted status but produce no observable terrain effect.

## 6. Validation
- [ ] 6.1 Run openspec validate repair-planetary-worldgen-fidelity-and-wraparound --strict.
- [ ] 6.2 Execute deterministic seed matrix checks and capture evidence artifacts (counts, screenshots, metrics).
- [ ] 6.3 Run performance checks to ensure chunk generation budgets remain within target thresholds.