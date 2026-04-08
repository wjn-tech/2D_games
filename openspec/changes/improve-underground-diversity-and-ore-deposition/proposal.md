# Change: Improve Underground Diversity and Ore Deposition

## Why
Players report that underground exploration currently feels repetitive: large areas of similar stone, weak regional identity, too few memorable large caverns, and ore appearing as salt-and-pepper scatter instead of clustered deposits or vein-like structures.

Current implementation confirms the concern:
- Chunk enrichment resource placement is largely per-cell threshold replacement, which tends toward pointwise scatter.
- Critical-path cave carving intentionally uses simplified rules for runtime smoothness, reducing shape diversity in moment-to-moment play.
- Existing topology metadata includes underground theme and hazard bias, but those signals are not yet enforced as strong underground structural contracts.

This proposal defines explicit generation contracts so underground identity, cavern readability, and ore deposition coherence become measurable outcomes rather than best-effort side effects.

## What Changes
- Add deterministic underground region-zoning contracts that combine depth bands with macro-region context.
- Add explicit large-cavern and connector-route budgets so underground traversal includes memorable large spaces, not only narrow lanes and noise pockets.
- Add cave archetype identity contracts with stable metadata for gameplay systems and validation tooling.
- Add ore deposition contracts that require cluster-first connected ore bodies with cross-chunk continuity, instead of primarily per-cell scatter.
- Add distribution-quality validation requirements (connected-component, clustering, continuity, and depth-profile checks).
- Preserve streaming safety by keeping traversal-critical generation bounded and shifting heavy shaping/enrichment into deferred passes.
- Preserve liquid system behavior and contracts while upgrading underground topology and ore deposition.

## Detailed Scope
- Focus capabilities:
  - exploration-underground-generation
  - mineral-generation
- This proposal does not add new combat systems, enemy families, or economy loops.
- This proposal does not require a full tileset replacement; geometry, topology, and deposit coherence are primary.
- This proposal does not remove existing deterministic seed/chunk regeneration guarantees.
- This proposal targets medium stratification strength (readable but not abrupt layer transitions).
- This proposal requires at least one early-game friendly descent route near spawn-safe exploration distance.
- This proposal keeps old saves compatible and applies new underground/deposit contracts to newly generated worlds or new chunks only (no forced old-world backfill migration).

## Confirmed Product Decisions
- Priority: improve underground zoning readability, large caverns, long connector traversal, geological ore feel, and runtime stability together.
- Ore style: cluster-first bodies are the primary visual/structural target.
- Stratification style: medium strength transitions.
- Early exploration: spawn vicinity should provide discoverable descent.
- Performance posture: balanced quality and smoothness.
- Save compatibility: old saves remain usable; no mandatory retroactive world rewrite.
- Hard constraint: liquid system must be preserved.

## Impact
- Affected specs:
  - exploration-underground-generation
  - mineral-generation
- Affected code (implementation stage, after approval):
  - src/systems/world/world_generator.gd
  - src/systems/world/infinite_chunk_manager.gd
  - src/systems/world/world_topology.gd
  - worldgen validation scripts under tools/ and tests/
- Relationship to existing changes:
  - Complements enhance-natural-cave-entrances-and-deep-caverns by tightening underground variety and readability metrics.
  - Complements implement-mineral-generation by upgrading ore from mostly threshold scatter to structured deposits.
  - Keeps compatibility with planetary wraparound and staged worldgen constraints.