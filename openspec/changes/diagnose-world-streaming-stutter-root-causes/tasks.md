## 1. Baseline Diagnosis
- [ ] 1.1 Capture current hotspot baseline for walking across chunk boundaries (fixed seed, fixed route, fixed duration).
- [ ] 1.2 Record per-stage timing for chunk critical load, enrichment, tile apply, unload cleanup, and save/autosave path.
- [ ] 1.3 Produce a ranked hotspot report with frame-hitch attribution and reproducible steps.

## 2. Streaming Budget Contracts
- [ ] 2.1 Define hard per-frame budget policy for critical load, enrichment, unload, and entity spawn stages.
- [ ] 2.2 Add queue backpressure rules and starvation-prevention policy (critical vs enrichment fairness).
- [ ] 2.3 Define visibility/collision guarantees when budgets are exceeded.

## 3. Save Hitch Control
- [ ] 3.1 Define dirty-only flush behavior for world deltas in non-manual-save gameplay frames.
- [ ] 3.2 Define hitch-safe autosave pipeline with bounded per-frame write work.
- [ ] 3.3 Define force-flush checkpoints for manual save, quit, and critical transitions.

## 4. Validation
- [ ] 4.1 Add repeatable validation script/scenario for walking-time stutter regression.
- [ ] 4.2 Verify no autosave-aligned hitch spikes under stress route.
- [ ] 4.3 Document performance acceptance thresholds and publish before/after comparison.
