## Context
Current preload persistence writes large precomputed chunk artifacts to a global cache tree and reuses them across startup runs. The artifacts are not treated as bounded cache with strict eviction governance, and cleanup flows are primarily scoped to authoritative world delta directories. This allows stale precomputed data to survive indefinitely and accumulate until local disk pressure becomes severe.

## Goals / Non-Goals
- Goals:
  - Establish a strict lifecycle boundary: authoritative save state SHALL be durable; precomputed artifacts SHALL be disposable.
  - Bound precomputed disk usage with deterministic, automated eviction.
  - Reduce per-chunk storage overhead using compact, compressed payload contracts.
  - Preserve deterministic reconstruction from seed + authoritative deltas.
- Non-Goals:
  - Redesign world generation logic or terrain semantics.
  - Change player-facing world identity semantics.
  - Remove preload acceleration entirely.

## Decisions
- Decision: Adopt two persistence tiers with explicit ownership.
  - Tier A (authoritative): slot-owned save payloads and world deltas.
  - Tier B (disposable): precomputed preload cache keyed by world identity and storage schema version.
  - Tier B deletion MUST NOT alter durable gameplay state.

- Decision: Introduce cache budget governance.
  - Maintain global and per-world caps for precomputed storage.
  - Enforce eviction order by recency (LRU) and stale-world orphan priority.
  - Trigger eviction at startup and after preload writes when budget is exceeded.

- Decision: Add schema-versioned identity invalidation.
  - Cache identity SHALL include topology identity + storage schema version + generator schema version.
  - Mismatch MUST force cache miss and invalidate legacy entries for eviction.

- Decision: Move to compact payload encoding contract.
  - Precomputed payloads SHALL be persisted in compressed container format.
  - Implementation SHALL avoid high-overhead unbounded dictionary-key serialization as the long-term canonical on-disk representation.

- Decision: Add operational storage telemetry.
  - System SHALL expose footprint metrics by tier and emit structured eviction events.
  - Diagnostics SHALL include bytes reclaimed and reason codes.

## Trade-offs
- Additional complexity for lifecycle manager and migration handling.
- Slight startup overhead to scan cache metadata before preload.
- Significant reduction in disk bloat risk and improved operational predictability.

## Migration Plan
1. Introduce tiered persistence metadata and cache index manifest.
2. Add compatibility readers for legacy precomputed entries.
3. Enable bounded eviction and identity invalidation.
4. Switch writer to compact compressed contract.
5. Add one-time cleanup sweep for orphaned legacy directories.
6. Keep deterministic reconstruction fallback active throughout migration.

## Risks / Mitigations
- Risk: Over-aggressive eviction causes runtime cache churn.
  - Mitigation: Tune with per-world minimum warm set and adaptive thresholds.
- Risk: Migration bugs could reduce cache hit rate temporarily.
  - Mitigation: Keep legacy read path during transition and add telemetry alerts.
- Risk: Incorrect tier boundary could drop durable data.
  - Mitigation: Enforce explicit separation tests: cache deletion must not mutate authoritative world state.

## Validation Strategy
- Determinism tests: same seed + same authoritative deltas reconstruct identical terrain outcomes after cache purge.
- Storage tests: precomputed cache size remains <= configured caps under sustained world creation.
- Lifecycle tests: deleting/abandoning worlds removes related disposable cache ownership references.
- Compatibility tests: legacy cache can be ignored or migrated without breaking load.
- Tooling: `openspec validate refactor-precomputed-cache-lifecycle-and-storage --strict` MUST pass.