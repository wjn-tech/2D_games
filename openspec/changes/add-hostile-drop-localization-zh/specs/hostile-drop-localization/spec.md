## ADDED Requirements

### Requirement: Hostile Drop Localization Key Coverage
The system SHALL assign a stable translation key to every hostile-drop item used by the hostile drop table design, including signature drops and common hostile materials.

#### Scenario: Full key coverage for hostile drop set
- **Given** the current hostile drop item set is loaded from design data
- **When** localization coverage validation runs
- **Then** each item_id resolves to exactly one translation key
- **And** validation fails if any item_id has no translation key mapping

### Requirement: Bilingual Naming Matrix for Hostile Drops
The system SHALL maintain a bilingual matrix for each hostile-drop item with fields: `item_id`, `translation_key`, `zh`, and `en`.

#### Scenario: Review-ready bilingual naming
- **Given** the hostile drop localization matrix is generated
- **When** design review is performed
- **Then** each row presents both Chinese and English names
- **And** the Chinese and English names describe the same gameplay material concept

### Requirement: Deterministic Translation Key Convention
Hostile-drop translation keys SHALL follow a deterministic naming convention:
- Signature drops: `ITEM_HOSTILE_<MONSTER>_<TOKEN>`
- Common materials: `ITEM_HOSTILE_MAT_<TOKEN>`

#### Scenario: Key naming validation
- **Given** localization keys for hostile drops
- **When** key-format validation runs
- **Then** all signature keys match `ITEM_HOSTILE_<MONSTER>_<TOKEN>`
- **And** all common material keys match `ITEM_HOSTILE_MAT_<TOKEN>`
- **And** duplicate keys are rejected

### Requirement: Localization Compatibility with Existing Display Pipeline
The hostile-drop localization plan SHALL remain compatible with existing UI paths that may still display raw `display_name` text directly.

#### Scenario: Missing runtime tr() call does not break readability
- **Given** a UI path renders hostile item name from direct `display_name`
- **When** the locale is switched or translation key binding is incomplete
- **Then** the hostile item still shows a readable fallback name
- **And** gameplay-critical loot feedback remains understandable

### Requirement: Localization-Link Gate for Drop Table Review
Drop-table design review SHALL fail if a hostile-drop item appears in the drop table without a bilingual localization row.

#### Scenario: Unlocalized drop entry blocked
- **Given** a hostile drop table includes item_id `X`
- **When** pre-merge review checks localization linkage
- **Then** review fails if `X` is missing from localization matrix
- **And** review passes only after the mapping row is added
