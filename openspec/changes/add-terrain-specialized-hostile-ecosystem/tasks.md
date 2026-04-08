## 1. Terrain Taxonomy and Rule Contracts
- [x] 1.1 Freeze the authoritative terrain taxonomy used by spawning (confirmed 31-class definition and naming contract).
- [x] 1.2 Extend spawn-table schema and validator rules for strict terrain matching and rule completeness.
- [x] 1.3 Add integrity checks that fail rules with missing terrain dimensions or invalid enum values.

## 2. Spawn Mapping Expansion
- [x] 2.1 Add/adjust hostile spawn mappings so every approved terrain class has native hostile coverage.
- [ ] 2.2 Implement rarity and hotspot multipliers for cross-terrain low-probability families (mimic cluster baseline 0.12%, pocket/connector/solid x2).
- [x] 2.3 Add deterministic conflict resolution for overlapping candidate rules in mixed terrain contexts.
- [x] 2.4 Enforce at least two hostile candidate families per terrain class.

## 3. Hostile Family Delivery (15 Families)
- [ ] 3.1 Define behavior profile contracts for all 15 families (telegraph, counterplay, status effects, fail-safe constraints) without introducing sanity/thirst/durability/QTE systems.
- [ ] 3.2 Deliver family implementation in phased waves with explicit terrain priority (Wave 1 foundational, Wave 2 specialized, Wave 3 extreme-depth).
- [ ] 3.3 Add data/resource wiring so each family is addressable by spawn rules and runtime behavior IDs using placeholder-first assets.

## 4. Balance and Fairness
- [ ] 4.1 Establish per-depth and per-terrain pressure budgets (spawn density, elite frequency, concurrent threat ceiling).
- [ ] 4.2 Add fairness guards for hard-control/lethal mechanics (default enabled, with cooldowns and anti-chain-lock rules).
- [ ] 4.3 Validate hostile composition variety so no key terrain is dominated by a single family over long sampling windows.

## 5. Validation and Acceptance
- [x] 5.1 Add tooling/debug reports for terrain coverage, spawn distribution, and seed determinism sampling.
- [ ] 5.2 Run representative seed validation for surface, underground, cave, and underworld bands; record anomalies and fixes.
- [x] 5.3 Run openspec validate add-terrain-specialized-hostile-ecosystem --strict and resolve all issues.
