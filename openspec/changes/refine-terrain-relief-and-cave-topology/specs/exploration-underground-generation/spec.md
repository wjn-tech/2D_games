## MODIFIED Requirements

### Requirement: Underground Cave Networks SHALL Provide Distinct Traversal Archetypes
The world generation system SHALL produce underground cave spaces using a topology model that yields distinct traversal archetypes without exposing an obvious single-wave routing artifact to the player.

#### Scenario: Representative underground regions differ in structure
- **WHEN** the game generates underground chunks for multiple deterministic seeds and depth bands
- **THEN** the resulting cave layouts include at least chamber-like spaces, connective tunnel-like paths, branching routes, and shaped biome- or strata-themed underground regions such as broad caverns, horizontal galleries, compartment clusters, or equivalents
- **AND** those layouts remain deterministic for the same seed and chunk coordinates

#### Scenario: Cave backbones are not visibly a single repeated waveform
- **WHEN** a player traverses a representative sample of underground regions across long horizontal distance
- **THEN** the cave network does not read as one clearly exposed sinusoidal or equivalently repetitive master line with occasional connectors
- **AND** navigation quality is preserved through less obvious but still reachable backbone routing

#### Scenario: Connector and branch patterns avoid fixed-interval stripe artifacts
- **WHEN** representative underground cross-sections are reviewed in deterministic seeds
- **THEN** connector and branch placement does not collapse into obvious stripe-like or fixed-depth repeated strokes
- **AND** route reachability remains intact without reintroducing periodic visual rhythms

### Requirement: Underground Cave Networks SHALL Preserve Player Reachability
The world generation system SHALL preserve practical underground reachability so cave diversity does not collapse into sealed pockets, excessive dead ends, disconnected vertical progression, or buried-only access.

#### Scenario: Underground descent remains traversable across chunk boundaries
- **WHEN** the game generates adjacent underground chunks for the same seed
- **THEN** cave openings, shafts, chambers, and connective passages align well enough that traversal routes are not routinely broken at chunk seams

#### Scenario: Encounter spaces are not dominated by sealed pockets
- **WHEN** the game generates underground and cavern regions intended for exploration or hostile spawning
- **THEN** most encounter-worthy cave spaces remain enterable and escapable by ordinary player traversal tools expected for that progression band
- **AND** intentionally sealed or special pockets, if any, are treated as explicit exceptions rather than the default cave outcome

### Requirement: Underground Generation SHALL Support Encounter-Aware Regions
The world generation system SHALL expose enough information for encounter systems to distinguish meaningful underground region types, strata identity, and reachability context when spawning enemies or placing resources.

#### Scenario: Spawn systems can query underground region identity
- **WHEN** a hostile or content system evaluates an underground position
- **THEN** it can determine the biome or depth identity, relevant strata or sub-region, and whether the area belongs to a distinct underground region or cave archetype suitable for themed encounters
- **AND** it can distinguish whether that region is open, tunnel-like, chamber-like, pocket-like, connector-like, or equivalently classified for encounter decisions

#### Scenario: Spawn systems can query underground reachability context
- **WHEN** a hostile spawn system evaluates a candidate cave position
- **THEN** it can determine whether the surrounding cave space is reachable, traversal-worthy, and suitable for regular encounter placement rather than a sealed or invalid pocket

## ADDED Requirements

### Requirement: Underground Strata SHALL Express Layered Regional Identity
The world generation system SHALL make underground progression feel layered by combining ordered depth strata with macro-region-dependent underground identity, rather than presenting most subsurface space as one homogeneous stone field.

#### Scenario: Depth progression changes underground character
- **WHEN** the player descends through representative underground depth bands in a deterministic world
- **THEN** the surrounding space shows readable changes in cave openness, local material family, pocket frequency, mineral expectations, or equivalent regional cues
- **AND** those changes feel like transitions between intended strata rather than abrupt random swaps

#### Scenario: Representative underground views do not collapse into one uniform mass
- **WHEN** representative shallow and mid-depth underground views are reviewed in the same deterministic world
- **THEN** those views do not both read as one mostly uniform pale stone field with only sparse ore accents
- **AND** players can distinguish the surrounding underground identity through geometry, layering, openness, background treatment, or equivalent regional cues

#### Scenario: Surface macro regions influence the underground below them
- **WHEN** underground chunks are generated beneath different major surface macro regions or biome arcs
- **THEN** their strata presentation is meaningfully modified by the owning region
- **AND** the result is more expressive than mapping every surface biome to only one static underground biome variant

### Requirement: Underground Generation SHALL Produce Shaped Subterranean Archetypes
The world generation system SHALL produce some underground regions as deliberately shaped archetype families rather than treating all cave space as interchangeable carved void.

#### Scenario: Regional cave families have recognizable geometry
- **WHEN** representative seeds are generated across supported world configurations
- **THEN** some underground regions present recognizable large-scale geometry such as long galleries, wide-open caverns, compartment-like nests, sink-connected rifts, or equivalent forms
- **AND** those forms are stable enough that players can distinguish one underground region family from another during traversal

#### Scenario: Archetype families remain compatible with chunked generation
- **WHEN** shaped subterranean archetypes cross chunk boundaries or are regenerated after unloading
- **THEN** their large-scale geometry remains continuous and deterministic
- **AND** player deltas still override generated tiles through the existing persistence model

### Requirement: Underground Generation SHALL Expose Natural Surface Entrances
The world generation system SHALL periodically expose natural surface-to-underground entry points so players can discover and choose descent routes from the surface without relying primarily on manual vertical digging.

#### Scenario: Representative surface travel reveals discoverable cave entries
- **WHEN** a player explores representative non-spawn surface regions in a fresh world
- **THEN** the player periodically encounters readable cave mouths, sinkholes, ravine descents, cliff cut entrances, funnel pits, chambered descents, or equivalent natural openings into underground routes
- **AND** those openings are deterministic for the same seed and world metadata

#### Scenario: Spawn-safe regions retain at least one forgiving early descent
- **WHEN** the player explores the early-game distance budget around the spawn-safe corridor
- **THEN** at least one starter-appropriate underground entry route is discoverable without requiring deep manual shaft excavation
- **AND** that route does not violate spawn-area safety or tutorial stability constraints

#### Scenario: Entrance families vary across terrain contexts
- **WHEN** different biome and relief contexts generate surface-to-underground entries
- **THEN** the same world can expose more than one entrance family instead of one repeated opening silhouette everywhere
- **AND** entrance family selection remains compatible with the local landform or region identity

### Requirement: Underground Topology SHALL Provide Long-Form Traversal Routes
The world generation system SHALL periodically provide longer underground traversal routes that connect multiple exploration spaces without exposing a single obvious global wave artifact.

#### Scenario: Long routes connect multiple underground spaces
- **WHEN** a representative underground region set is generated for a deterministic seed
- **THEN** at least some traversable routes extend across multiple chambers, caverns, or sub-biome spaces through a continuous route family or equivalent connective structure
- **AND** the player can follow those routes for meaningful distance without repeatedly rebuilding direction through isolated vertical shafts

#### Scenario: Long routes preserve existing reachability guarantees
- **WHEN** long-form traversal routes are generated near normal cave systems
- **THEN** they remain compatible with chunk-boundary continuity, ordinary traversal expectations for the progression band, and the existing encounter-query model

### Requirement: Underground Identity SHALL Survive Limited Tile Budgets
The world generation system SHALL keep underground strata and archetype identity readable even when multiple regions reuse the same core stone families and only a limited number of new accent assets are available.

#### Scenario: Shaped regions stay recognizable with shared core materials
- **WHEN** representative underground strata and archetype families are generated using mostly shared stone or background material families
- **THEN** players can still distinguish galleries, open caverns, compartment clusters, or equivalent underground region families through geometry, openness, layering, and localized cues
- **AND** any new archetype-specific tiles remain optional readability enhancers rather than the only way to communicate region identity

### Requirement: Underground Tile Layout SHALL Suppress Periodic Wrong-Tile Artifacts
The world generation system SHALL suppress deterministic-but-visible wrong-tile artifact patterns such as isolated unsupported islands, repeated stripe bands, or one-column material walls that do not match the surrounding cave geometry.

#### Scenario: Artifact suppression preserves deterministic cave readability
- **WHEN** representative underground regions are generated and compared across reloads for the same seed
- **THEN** obvious periodic wrong-tile artifacts are absent or reduced below readability-breaking levels
- **AND** artifact suppression does not break determinism, chunk continuity, or intended cave traversal routes