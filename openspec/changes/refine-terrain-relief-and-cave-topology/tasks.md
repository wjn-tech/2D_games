## 1. Surface Relief Foundations
- [ ] 1.1 Replace the current single-layer surface height logic with a staged relief stack that supports plains, rolling hills, mountain or ridge segments, basin or valley segments, and deterministic biome transitions.
- [ ] 1.2 Preserve spawn-safe traversal by enforcing starter-corridor smoothing, slope budgets, and bounded early-game drop severity while stronger relief appears outside the safe corridor.
- [ ] 1.3 Add biome- and relief-aware entrance families so the surface can expose readable descent cues such as cave mouths, ravines, pits, or equivalent openings instead of relying on incidental cave breakthrough.
- [ ] 1.4 Update surface landmark, decorator, and structure placement rules so they read the new relief categories and entrance outcomes instead of assuming mostly flat terrain.
- [ ] 1.5 Audit current atlas-coupled terrain consumers and define a low-asset delivery plan that reuses existing material families first, reserving only a small budget for accent or transition tiles.

## 2. Underground Strata and Regional Identity
- [ ] 2.1 Define ordered underground strata or equivalent depth-region bands with deterministic transitions, not just a single underground biome per surface biome.
- [ ] 2.2 Add a small set of shaped subterranean archetype families, such as long galleries, wide-open caverns, compartment clusters, or equivalent region forms, that can be selected by strata and macro world region.
- [ ] 2.3 Tie underground stone palette, cave openness, mineral weighting, special pocket rules, and archetype selection to both depth strata and macro world region.
- [ ] 2.4 Expose additive metadata for strata identity, relief context, entrance context, and route or archetype context without breaking existing cave region query consumers.

## 3. Cave Topology and Entrances
- [ ] 3.1 Replace the current visibly sinusoidal primary cave route with a more natural backbone-and-branch topology or equivalent non-obvious routing model.
- [ ] 3.2 Add deterministic natural cave entrance generation so representative surface regions periodically expose readable openings into underground traversal routes, with more than one entrance family in circulation.
- [ ] 3.3 Add at least one long-form underground route family that can connect multiple larger underground spaces without relying on a visible global wave artifact.
- [ ] 3.4 Preserve reachability, chunk-boundary continuity, spawn-area safety, and reasonable dead-end frequency under the new cave topology.

## 4. Validation
- [ ] 4.1 Add debug verification or regression checks for relief diversity, underground strata transitions, entrance-family presence, shaped archetype distribution, determinism, and chunk reload stability.
- [ ] 4.2 Validate representative seeds to confirm surface silhouette variety, underground progression readability, natural entrance discoverability, shaped sub-biome readability, long-route usefulness, and the removal of obvious single-wave cave artifacts.
- [ ] 4.3 Validate that representative seeds remain visually readable with mostly reused base terrain tiles plus only limited new accent assets.
- [ ] 4.4 Run openspec validate refine-terrain-relief-and-cave-topology --strict and resolve all validation issues.