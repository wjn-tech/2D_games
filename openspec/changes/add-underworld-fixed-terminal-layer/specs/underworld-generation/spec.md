## ADDED Requirements

### Requirement: World Generation SHALL Create One Deterministic Fixed Underworld Layer Per New World
The world generation system SHALL create exactly one deterministic underworld mega-space per newly created world.

#### Scenario: Same seed yields same underworld identity
- **WHEN** the same seed regenerates the same world after reload
- **THEN** underworld anchor placement and shape identity remain deterministic
- **AND** no additional second underworld layer is generated

#### Scenario: Legacy metadata backfill without forced rewrite
- **WHEN** an existing pre-change save is loaded
- **THEN** no forced retroactive chunk rewrite is performed
- **AND** missing underworld metadata is backfilled so newly generated depth chunks can include the fixed underworld layer

### Requirement: Underworld Layer SHALL Be Anchored Above Bedrock Transition With Controlled Intrusion
The underworld layer SHALL be anchored immediately above the bedrock transition region and MAY intrude into transition depth within bounded limits.

#### Scenario: Anchor placement contract
- **WHEN** underworld anchor metadata is computed
- **THEN** the anchor band is positioned above configured bedrock transition start depth
- **AND** anchor placement is deterministic for the same topology metadata

#### Scenario: Intrusion bounds and safety
- **WHEN** underworld geometry intrudes toward bedrock transition space
- **THEN** intrusion remains within configured bounds
- **AND** hard-floor safety invariants remain preserved

### Requirement: Underworld Layer SHALL Provide World-Scale Mega-Space Coverage
The underworld layer SHALL occupy near full-circumference horizontal coverage with a minimum vertical span of 180 tiles.

#### Scenario: Scale invariants in generated worlds
- **WHEN** representative seeds are sampled for each world-size preset
- **THEN** underworld horizontal coverage satisfies configured near-full-circumference threshold
- **AND** measured vertical span is at least 180 tiles in the designated underworld envelope

### Requirement: Underworld Morphology SHALL Follow Aggressive Landmark Profile
The underworld layer SHALL present aggressive morphology including giant open cavity floors, cliff/escarpment systems, and suspended island groups.

#### Scenario: Landmark profile validation
- **WHEN** underworld geometry is evaluated in deterministic validation
- **THEN** giant cavity floor regions and major cliff discontinuities are present
- **AND** suspended island clusters appear at configured bounded density

### Requirement: Underworld Progression SHALL Guarantee a Natural Primary Access Route
The world generation system SHALL guarantee at least one natural primary route from mid-cavern progression into the underworld layer.

#### Scenario: Route discoverability and continuity
- **WHEN** traversal analysis follows connector/cavern pathways from mid-cavern bands
- **THEN** at least one continuous natural route reaches underworld space
- **AND** chunk seams do not break required route continuity in wrapped topology

### Requirement: Underworld-Adjacent Resource Zones SHALL Increase Ore Density by 30 Percent
Underworld-adjacent generation zones SHALL apply a deterministic ore-density uplift of 30% relative to baseline zone rules.

#### Scenario: Ore uplift verification
- **WHEN** representative seed sampling compares baseline deep-zone ore density with underworld-adjacent zones
- **THEN** underworld-adjacent zones show approximately +30% density uplift within configured tolerance
- **AND** mineral rarity/depth affinity contracts remain deterministic and valid

### Requirement: Underworld Generation SHALL Remain Streaming-Safe
Underworld generation SHALL preserve traversal-critical runtime smoothness under chunk streaming constraints.

#### Scenario: Traversal-critical bounded work
- **WHEN** players move continuously through cave-to-underworld transition corridors
- **THEN** traversal-critical chunk generation remains within configured bounded workload
- **AND** non-critical enrichment is deferred without breaking immediate traversability
