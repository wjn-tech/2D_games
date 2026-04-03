## Context
A new compact storage approach for precomputed world artifacts requires a corresponding runtime loading design. Existing runtime flow is oriented around legacy per-chunk artifact files and cannot be assumed to safely load compact bundle/index-based data without an explicit contract.

## Goals / Non-Goals
- Goals:
  - Define a deterministic, resilient loading pipeline for compact storage artifacts.
  - Preserve startup smoothness and deterministic world reconstruction guarantees.
  - Guarantee safe fallback when compact artifacts are missing, stale, or corrupted.
  - Keep compatibility during migration from legacy precomputed format.
- Non-Goals:
  - Redesign world generation algorithms.
  - Change gameplay semantics or difficulty.
  - Replace authoritative save data model.

## Decisions
- Decision: Use staged load resolution order.
  - Stage 1: Compact artifact lookup by world identity + chunk canonical key.
  - Stage 2: Legacy precomputed compatibility reader.
  - Stage 3: Deterministic regeneration path (seed + authoritative deltas).

- Decision: Treat compact artifact decoding as untrusted input.
  - Loader SHALL verify schema/version/identity before decode.
  - Decode failure SHALL mark artifact invalid for session and trigger fallback.
  - Invalid artifacts SHOULD be quarantined for later cleanup telemetry.

- Decision: Keep loading bounded and observable.
  - Loader SHALL obey per-frame/per-batch budget constraints.
  - Loader SHALL emit progress/branch telemetry (compact hit, legacy hit, regenerate).

- Decision: Preserve canonical coordinate and topology semantics.
  - All load keys SHALL be canonicalized with topology rules before lookup.
  - Seam/wraparound coordinate mismatches SHALL NOT produce duplicate logical chunks.

## Trade-offs
- Added complexity in the load path and migration compatibility branch.
- More metadata checks before chunk materialization.
- Better reliability and controlled performance under partial cache corruption.

## Migration Plan
1. Introduce compact artifact reader and identity verification contract.
2. Add fallback branch to legacy reader.
3. Keep regeneration fallback as final safety branch.
4. Add telemetry counters for each branch and failure reason.
5. Phase out legacy branch after migration confidence threshold.

## Risks / Mitigations
- Risk: Silent data incompatibility causes unexpected cache misses.
  - Mitigation: explicit reason-code telemetry for each load branch decision.
- Risk: Corrupted compact artifacts cause startup instability.
  - Mitigation: strict decode guard + quarantine + deterministic fallback.
- Risk: Migration period increases code complexity.
  - Mitigation: isolate compatibility branch and define removal gate criteria.

## Validation Strategy
- Compatibility tests: compact load success, legacy fallback success, regeneration fallback success.
- Integrity tests: corrupted compact payload does not crash load flow.
- Determinism tests: same seed + same authoritative deltas yields same world outcomes regardless of branch.
- Performance tests: loading remains within configured frame budget.
- Tooling: `openspec validate add-compact-storage-loading-pipeline --strict` MUST pass.

## Implementation Notes
- Runtime now defaults `PRECOMPUTED_WRITE_LEGACY_COMPAT` to `false`, so new precomputed artifacts are written as compact-first without legacy `.bin` dual-write amplification.
- Runtime keeps legacy read fallback in the resolution chain (`compact -> legacy -> regenerate`) to preserve migration safety for existing caches.
- Runtime performs signature-scoped legacy pruning when compact peers exist (delete `chunk_x_y.bin` if `chunk_x_y.cbin` exists), and records reclaimed-bytes telemetry via precomputed-resolution stage events.