# Capability: Liquid Worldgen

World generation and initial stabilization for liquid bodies.

## ADDED Requirements

### Requirement: World Generation SHALL Produce Biome-Appropriate Liquid Reservoirs
World generation SHALL place functional liquid bodies according to biome, depth band, and structure context instead of relying only on runtime player placement.

#### Scenario: Surface water and deep lava are both discoverable
- GIVEN a newly generated representative world seed
- WHEN the world is inspected across surface and deeper underground bands
- THEN the generated content MUST include at least surface or shallow water reservoirs and deeper lava reservoirs in appropriate contexts.

### Requirement: Generated Liquids SHALL Be Stabilized Before First Discovery
The world generator SHALL run a settling or equivalent stabilization step so generated liquids do not appear in obviously suspended intermediate states when a player first reaches them.

#### Scenario: First-visit cave lake is already settled
- GIVEN a cave lake placed during world generation
- WHEN the player reaches that area for the first time
- THEN the lake MUST already read as a stable reservoir rather than an active waterfall still assembling itself from raw stamped cells.

### Requirement: Special Biome Liquids SHALL Be Extensible
The generator SHALL support biome- or structure-specific liquid pockets without forcing every liquid to appear in every region.

#### Scenario: Honey-like liquid remains biome-gated
- GIVEN a future biome or structure that owns a slow buff-style liquid
- WHEN worldgen builds that region
- THEN the system MUST be able to place that liquid there without requiring the same liquid to appear as a common reservoir in unrelated biomes.

### Requirement: Decorative Liquidfalls SHALL Be Distinct from Reservoir Volumes
The generation pipeline SHALL allow decorative falls, drips, or seep effects to be authored separately from authoritative reservoir volumes.

#### Scenario: Cliffside drip does not require a full lake simulation
- GIVEN a generated cliff or cavern lip with a decorative seep effect
- WHEN the area loads
- THEN the visual drip or fall MAY render without requiring a large upstream liquid body to be simulated at equal fidelity.