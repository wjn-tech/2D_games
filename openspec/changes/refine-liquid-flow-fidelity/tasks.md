## 1. Specification
- [x] 1.1 Confirm baseline behavior and metrics for current liquid motion (drain continuity, lateral equalization smoothness, convergence duration).
- [x] 1.2 Finalize requirement scenarios for flow continuity, pressure balancing, pacing stability, and persistence parity.

## 2. Simulation Design
- [x] 2.1 Define micro-step transfer policy that keeps aggregate throughput while increasing temporal continuity.
- [x] 2.2 Define adaptive pacing model for falling and lateral spread using local capacity and head difference.
- [x] 2.3 Define bounded local pressure-equalization pass for active neighborhoods.
- [x] 2.4 Define short-lived directional inertia model to reduce per-frame direction flipping.

## 3. Performance and Safety
- [x] 3.1 Define strict runtime budgets (max active steps, max settle checks, time budget per frame) and fallback behavior.
- [x] 3.2 Define deterministic processing order constraints for reproducible seed replay and stable save/load parity.

## 4. Validation
- [x] 4.1 Add/extend automated liquid behavior checks for convergence time and continuity thresholds.
- [x] 4.2 Add persistence regression checks covering save while loaded, unload/reload, and empty-initialized chunk states.
- [x] 4.3 Record before/after benchmark snapshots for representative cave, basin, and waterfall scenarios.

## 5. Documentation and Rollout
- [x] 5.1 Update runtime liquid notes and tuning guide with new fidelity knobs and recommended ranges.
- [x] 5.2 Provide rollout checklist and rollback levers for safe tuning in live content branches.

## 6. Water-Only Terraria Continuity Delta
- [x] 6.1 Add short open-fall hysteresis window for water to reduce packet/direct mode flicker in borderline open columns.
- [x] 6.2 Add bounded water lateral split gain (+1%) with source/capacity caps and non-water bypass.
- [x] 6.3 Add regression checks for hysteresis hold/expiry, split-gain guardrail, and clear-epsilon boundary behavior.
- [x] 6.4 Strengthen open-fall vertical priority (thicker downward transfer floor + short cooldown cap + lateral damping) and add regression checks.
- [x] 6.5 Improve waterfall visual continuity for low-volume vertical streams to remove stripe-like stepping artifacts.
- [x] 6.6 Patch top-bottom enclosed seam void bubbles (left/right unsupported slit cavities) and add regression checks.
- [x] 6.7 Remove downward quantization dead-zone for thin films (micro-trickle fallback + retry scheduling) and add regression checks.
- [x] 6.8 Remove cooldown busy-requeue thrash via cooldown-ready activation scheduler and add regression checks.
- [x] 6.9 Collapse multi-cell vertical seam gaps using bounded deep endpoint probing and visible bridge transfer, with regression checks.
- [x] 6.10 Ensure seam endpoint probing does not early-fail on same-type thin intermediate films, with regression checks.
- [x] 6.11 Align seam bridge minimum neighbor threshold with render visibility threshold to eliminate visible floating-cap bubbles.
- [x] 6.12 Allow seam collapse to top up same-type underfilled candidate cells (instead of skipping non-empty low-volume seams) and add regression checks.

## 7. Core-Logic Runtime Rollback
- [x] 7.1 Temporarily disable post-simulation repair passes in runtime loop (static hole fill, fast relax, pressure equalization, bubble collapse) to keep only core gravity/lateral/cooldown flow logic.
- [x] 7.2 Add downstream-capacity wait source-cell delayed self-retry scheduling to avoid potential-flow sleep while keeping downstream-priority activation.
- [x] 7.3 Suppress lateral spread/edge-spill during downstream-capacity wait ticks to avoid uphill-looking side growth while preserving vertical-priority drainage.
