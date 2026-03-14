## 1. Baseline Lock and Implementation Boundaries
- [ ] 1.1 Inventory the current surface-height, cave-routing, feature-tag, and biome-query entry points in `world_generator.gd` and related topology helpers so the implementation starts from the real generation seams.
- [ ] 1.2 Inventory atlas-coupled downstream consumers such as digging, drops, chunk assembly, and structure placement that would be affected by new terrain material families or accent tiles.
- [ ] 1.3 Lock a representative seed set and fixed observation views covering spawn surface, non-spawn surface, shallow underground, mid underground, and long horizontal underground traversal.
- [ ] 1.4 Capture baseline screenshots or equivalent debug artifacts for the locked seed/view set so later waves are compared against the same evidence.
- [ ] 1.5 Define the first-pass low-asset delivery rule for this change: which relief and archetype differences must be expressed through geometry, backgrounds, and decorators first, and what tiny accent-tile budget is allowed if readability still falls short.
- [ ] 1.6 Define the additive metadata contract for relief profile, entrance family, strata id, route role, and shaped archetype identity without breaking existing region-tag consumers.
- [ ] 1.7 Profile the current chunk-loading path from `_pending_chunk_requests` through `_build_chunk_on_main_thread()` and `generate_chunk_cells()` so the change starts with an explicit performance baseline and hitch-risk map.
- [ ] 1.8 Break the current hot path into explicit algorithm families such as relief sampling, biome or strata lookup, cave carve, mineral or tree placement, structure overlay, and post-load finishing so each hotspot has an owner and budget.

## 2. Wave 1: Replace the Obvious Surface and Cave Skeleton
- [ ] 2.1 Introduce a deterministic macro relief profile selection layer tied to world-plan surface regions instead of relying only on the current continental-noise amplitude.
- [ ] 2.2 Implement only the first relief profile set needed for a visible win: starter-flat, rolling, ridge, and basin or direct equivalents.
- [ ] 2.3 Split surface shaping into staged responsibilities for macro landform choice, biome-specific shaping, local breakup, and post-shaping passes rather than one monolithic height calculation.
- [ ] 2.4 Preserve early traversal by reworking spawn-safe smoothing, slope budgets, and drop limits against the new relief stack instead of keeping today’s ad hoc flattening only.
- [ ] 2.5 Expose relief-profile query helpers so surface systems can ask for local terrain identity without reverse-engineering raw height noise.
- [ ] 2.6 Ensure the new relief stack exposes chunk-local or region-local reusable results so macro-profile decisions are not recomputed expensively for every tile.
- [ ] 2.7 Replace the single-wave cave-lane backbone with a less obvious anchor, backbone, and branch model or an equivalent deterministic routing system.
- [ ] 2.8 Rework branch generation so side paths, local chambers, and reconnectors emerge from the new backbone instead of periodic vertical drilling patterns.
- [ ] 2.9 Keep the first backbone rewrite compatible with the existing cave-region query contract before adding richer archetype metadata.
- [ ] 2.10 Run Wave 1 debug review on the locked seed/view set and confirm the world no longer primarily reads as a flat shelf over a visible single-wave cave spine before starting entrance work.

## 3. Wave 2: Make Surface-to-Underground Discovery Readable
- [ ] 3.1 Define only the first entrance-family set required for readable variety: gentle mouth, ravine or cut descent, and pit or funnel entry.
- [ ] 3.2 Add deterministic entrance budgeting and spacing rules so the surface periodically reveals readable descent options without turning into constant perforation.
- [ ] 3.3 Guarantee at least one starter-appropriate early descent route within the spawn-safe travel budget while keeping that corridor forgiving.
- [ ] 3.4 Update surface feature and landmark passes so they can react to relief category and entrance outcomes rather than assuming mostly flat terrain.
- [ ] 3.5 Validate that representative surface regions remain readable primarily through silhouette, cut shape, backdrop choice, and decorators even before adding any new accent tiles.
- [ ] 3.6 Separate traversal-critical entrance carving from deferrable surface enrichment so chunk loads do not block on non-essential ornamentation.
- [ ] 3.7 Bound entrance and feature selection work so new family logic does not introduce burst-heavy searches or repeated full-column rescans during chunk load.
- [ ] 3.8 Run Wave 2 review on the locked seed/view set and confirm players can periodically discover readable natural entries without surface over-perforation before starting strata work.

## 4. Wave 3: Build Layered Underground Identity
- [ ] 4.1 Formalize only the first strata set needed for visible progression: shallow, upper cavern, mid cavern, and deep.
- [ ] 4.2 Define how macro surface regions or underground themes modify the default strata behavior rather than mapping each surface biome to one static underground variant.
- [ ] 4.3 Introduce strata-driven decisions for openness, connector density, pocket frequency, background family, mineral weighting, and hazard bias.
- [ ] 4.4 Keep first-pass underground material identity mostly on shared core stone families plus backgrounds, decorator clusters, and limited accent assets instead of full new tilesets per strata.
- [ ] 4.5 Expose additive underground metadata so encounter and content systems can query strata, macro-region influence, and reachability context separately.
- [ ] 4.6 Cache or pre-resolve strata and underground-theme decisions at chunk or sub-region granularity where possible so deeper regional identity does not bloat the inner tile loop.
- [ ] 4.7 Ensure underground classification, hazard-bias, and material-family selection reuse the same cached region context instead of duplicating nearby lookups in separate passes.

## 5. Wave 3b: Add the First Recognizable Underground Families
- [ ] 5.1 Define a minimal first wave of shaped archetype families such as long galleries, broad caverns, compartment clusters, and rift-descents or direct equivalents.
- [ ] 5.2 Attach archetype-family selection rules to strata and macro-region context so these shapes are not placed as random one-off curiosities.
- [ ] 5.3 Implement large-scale geometry rules for each archetype family so players can distinguish them by shape and traversal feel, not only by material swap.
- [ ] 5.4 Ensure shaped archetypes stay deterministic and continuous across chunk seams and world reloads.
- [ ] 5.5 Verify that archetype identity is still legible with mostly reused base materials and only localized visual emphasis.
- [ ] 5.6 Classify which archetype details are critical to reachability and which can be deferred or simplified when chunk-generation budget is tight.
- [ ] 5.7 Bound archetype-shaping algorithms so large-scale geometry remains deterministic without requiring unbounded neighbor searches or recursive stitching during load.
- [ ] 5.8 Run Wave 3 review on the locked seed/view set and confirm shallow-to-mid underground no longer reads as one mostly uniform pale mass before moving to final performance hardening.

## 6. Long Routes and Route Metadata
- [ ] 6.1 Add at least one long-form underground traversal family that can connect multiple larger cave spaces over meaningful distance.
- [ ] 6.2 Classify long-route membership or route role in metadata so later systems can identify traversal-worthy underground corridors.
- [ ] 6.3 Preserve reasonable dead-end frequency so the network remains explorable without collapsing back into sealed pockets or over-connected soup.
- [ ] 6.4 Keep backbone and long-route generation compatible with bounded per-chunk work so long-distance topology does not require burst-heavy synchronous solving during load.
- [ ] 6.5 Reuse precomputed route anchors or equivalent deterministic handles so backbone, branches, and long routes do not each solve the same large-scale topology independently.

## 7. Wave 4: Periodic Artifact and Transition Cleanup
- [x] 7.1 Build a periodic-artifact checklist from the locked screenshot set, including repeated entrance cadence, stripe-like connector strokes, isolated wrong-tile slabs, and one-column hard biome boundaries.
- [x] 7.2 Replace single fixed-spacing entrance anchor patterns with deterministic multi-scale anchor distribution so players cannot easily read a constant horizontal rhythm.
- [x] 7.3 Replace fixed-depth connector cadence with deterministic non-periodic depth targeting that still preserves chunk-stable reachability.
- [x] 7.4 Add minimum transition-width rules for biome and strata boundaries so region switches do not present as one-column vertical cuts.
- [x] 7.5 Add deterministic local breakup rules near region boundaries to avoid large planar seam walls while preserving macro identity.
- [x] 7.6 Add lightweight post-shaping cleanup for isolated unsupported tile islands and narrow stripe artifacts without erasing intended cave geometry.
- [x] 7.7 Run Wave 4 screenshot review and confirm representative views no longer show obvious fixed-interval artifacts before moving to final performance hardening.

## 8. Wave 5: Performance Hardening and Streaming Safety
- [ ] 8.1 Define a traversal-critical chunk-generation slice that guarantees walkable terrain, core cave connectivity, and essential entrance geometry before secondary enrichment completes. (in progress)
- [ ] 8.2 Define which feature, archetype, and accent passes are allowed to run later or be budgeted separately from critical chunk geometry.
- [ ] 8.3 Introduce chunk-local caching or prepass outputs for relief profile, entrance budget, strata identity, and archetype candidates so expensive high-level queries are reused.
- [ ] 8.4 Define or prototype a bounded scheduling strategy for richer chunk generation so multiple pending requests do not turn into repeated main-thread load hitches during player movement.
- [ ] 8.5 Preserve existing session-cancellation and unload-safety behavior so stale chunk requests or outdated generation work are discarded cleanly.
- [ ] 8.6 Define how structure overlay, tree placement, and any post-generation finishing work are budgeted relative to the core terrain pass so secondary algorithms cannot dominate visible load cost.
- [ ] 8.7 Define acceptable fallback or degradation rules for non-critical passes when chunk-generation budget is exceeded, while keeping deterministic reload results intact.
- [ ] 8.8 Run representative movement and chunk-loading paths against the locked seed set and confirm richer worldgen does not introduce obvious repeatable hitch patterns.

## 9. Reachability, Chunk Compatibility, and Consumer Updates
- [ ] 9.1 Verify that the revised relief, entrances, and cave backbone remain continuous across chunk boundaries in the current infinite-chunk loading model.
- [ ] 9.2 Keep generated terrain and cave outputs compatible with delta persistence so player edits still override regenerated content correctly.
- [ ] 9.3 Update generation-time consumers that depend on terrain shape or region tags, including chunk assembly, structure placement, and any route-aware content hooks.
- [ ] 9.4 Update downstream atlas-coupled consumers only where required by the low-asset plan, avoiding unnecessary expansion of tile-based hardness, drop, or preview rules.
- [ ] 9.5 Preserve compatibility for existing cave-region query consumers by keeping old region tags available or mapping them cleanly onto the richer metadata model.

## 10. Debugging and Validation
- [ ] 10.1 Add or update debug inspection helpers so relief profile, entrance family, strata id, archetype family, route role, and chunk-generation phase can be sampled in representative seeds.
- [ ] 10.2 Add regression checks for relief diversity, starter-corridor forgiveness, entrance-family presence, and removal of the obvious single-wave cave artifact.
- [ ] 10.3 Add regression checks for underground strata transitions, shaped archetype continuity, route reachability, determinism, and chunk reload stability.
- [ ] 10.4 Add artifact-focused checks for fixed-interval repetition, one-column hard boundaries, stripe-like cave strokes, and isolated unsupported tile islands.
- [ ] 10.5 Run representative seed reviews to confirm that surface and underground readability survives with mostly reused material families plus only limited new accent assets.
- [ ] 10.5a Review representative wide-view screenshots to confirm the world no longer reads as a mostly flat surface shelf over a uniform pale underground mass with repeated ribbon-like cave strokes.
- [ ] 10.5b Review representative screenshots against the Terraria reference rubric to confirm cadence, transition softness, and cave body readability no longer expose obvious generator rhythm.
- [ ] 10.5c Do not advance from Wave 1, Wave 2, Wave 3, or Wave 4 until the corresponding gate review has been completed against the locked baseline artifact set.
- [ ] 10.6 Review every hot-path algorithm family against the final budget model to confirm no single low-level pass is left outside profiling, caching, scheduling, or degradation strategy.
- [ ] 10.7 Run openspec validate refine-terrain-relief-and-cave-topology --strict and resolve all validation issues.