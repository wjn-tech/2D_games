## 1. Specification
- [ ] 1.1 Finalize tiered persistence boundary definitions (authoritative vs disposable).
- [ ] 1.2 Finalize cache budget policy (global cap, per-world cap, eviction order, stale-world rules).
- [ ] 1.3 Finalize compact payload contract and schema versioning fields.

## 2. Implementation Planning
- [ ] 2.1 Define cache index/manifest responsibilities and failure-handling behavior.
- [ ] 2.2 Define migration strategy from legacy precomputed directories to bounded managed cache.
- [ ] 2.3 Define startup and post-write eviction trigger points with deterministic behavior.

## 3. Verification
- [ ] 3.1 Add validation matrix for determinism after cache purge and reconstruction.
- [ ] 3.2 Add storage-footprint validation cases (cap enforcement, eviction telemetry, reclaimed bytes).
- [ ] 3.3 Add world-abandonment cleanup validation cases (no orphan cache growth).
- [ ] 3.4 Run `openspec validate refactor-precomputed-cache-lifecycle-and-storage --strict` and resolve all issues.