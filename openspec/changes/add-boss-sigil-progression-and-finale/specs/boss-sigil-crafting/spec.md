## ADDED Requirements

### Requirement: Boss Sigils SHALL Be Craftable from Hostile Signature Drops
The crafting system SHALL provide three summon sigil recipes mapped to hostile signature drops.

#### Scenario: Craft slime king sigil
- **GIVEN** player owns at least 10 `slime_essence`
- **WHEN** player crafts `slime_king_sigil`
- **THEN** exactly 10 `slime_essence` are consumed
- **AND** exactly 1 `slime_king_sigil` is produced

#### Scenario: Craft skeleton king sigil
- **GIVEN** player owns at least 10 `bone_fragment`
- **WHEN** player crafts `skeleton_king_sigil`
- **THEN** exactly 10 `bone_fragment` are consumed
- **AND** exactly 1 `skeleton_king_sigil` is produced

#### Scenario: Craft eye king sigil
- **GIVEN** player owns at least 10 `void_eyeball`
- **WHEN** player crafts `eye_king_sigil`
- **THEN** exactly 10 `void_eyeball` are consumed
- **AND** exactly 1 `eye_king_sigil` is produced

### Requirement: Boss Sigil Recipes SHALL Reject Insufficient Materials
The crafting system SHALL block crafting when any ingredient is below threshold.

#### Scenario: Reject insufficient slime essence
- **GIVEN** player owns only 9 `slime_essence`
- **WHEN** player attempts to craft `slime_king_sigil`
- **THEN** crafting is rejected
- **AND** no material is consumed
- **AND** player receives readable insufficiency feedback

### Requirement: Boss Progression Items SHALL Have Localization Coverage
All sigils and cores introduced by this change SHALL have resolvable localization keys.

#### Scenario: Validate localization mapping
- **GIVEN** progression items include three sigils and three cores
- **WHEN** localization validation runs
- **THEN** each item resolves to an existing translation key
- **AND** player-facing UI does not render raw `item_id`
