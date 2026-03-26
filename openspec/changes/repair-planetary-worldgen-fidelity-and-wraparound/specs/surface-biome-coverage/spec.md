## ADDED Requirements

### Requirement: Planetary Surface SHALL Meet Minimum Biome Diversity
The system SHALL enforce minimum major-biome diversity per world-size preset so full-circumference traversal does not collapse into only a few repeated biome types.

#### Scenario: Medium world includes at least five major biome regions
- **GIVEN** world size preset is medium and topology is planetary
- **WHEN** the full surface circumference plan is generated
- **THEN** at least five major biome regions are present
- **AND** no single major biome region exceeds the configured maximum span ratio.

#### Scenario: Large world increases diversity budget
- **GIVEN** world size preset is large and topology is planetary
- **WHEN** the full surface circumference plan is generated
- **THEN** the major biome region count is greater than or equal to medium preset requirements
- **AND** at least one secondary/transition biome segment appears between major regions.

### Requirement: Biome Planning SHALL Be Seed-Deterministic
The system SHALL produce the same biome layout for the same seed, preset, and topology metadata.

#### Scenario: Repeat generation with same seed
- **GIVEN** identical seed and topology metadata
- **WHEN** world planning is executed multiple times
- **THEN** biome sequence, spans, and region identities are identical.