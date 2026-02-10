# Spec: Lineage and Breeding System

## ADDED Requirements

### Genetic Inheritance
Offspring inherit stats from parents based on distinct "Wild Levels".

#### Scenario: Stat Inheritance
- **Given** Father has 30 Wild Levels in Health.
- **And** Mother has 40 Wild Levels in Health.
- **When** Offspring is generated.
- **Then** Offspring has a 55% chance to inherit 40 levels, and 45% chance to inherit 30 levels.
- **And** Tamed levels are ignored (0).

### Mutation Mechanism
Mutations introduce random stat increases and count towards lineage limits.

#### Scenario: Mutation Event
- **Given** Parents have total mutation count < 20.
- **When** Breeding occurs and RNG hits 7.3%.
- **Then** Offspring gains +2 Wild Levels in a random stat.
- **And** Offspring's mutation counter (corresponding to the parent source) increments by 1.

### Growth & Imprinting
Baby characters must physically grow and can be buffed via care.

#### Scenario: Growth Over Time
- **Given** a new born Baby (Growth 0.0).
- **When** time passes.
- **Then** `scale` approaches 1.0.
- **And** at Growth 1.0, it becomes Adult.

#### Scenario: Imprinting
- **Given** a growing baby asking for specific food.
- **When** Player provides item.
- **Then** `ImprintBonus` increases (max 100%).
- **And** Final stats are multiplied by `1 + ImprintBonus * Multiplier`.

### Death & Inheritance
The player can continue playing as a descendant upon death.

#### Scenario: Player Death
- **Given** Player health reaches 0.
- **When** Player dies.
- **Then** Game pauses and `HeirSelectionUI` appears.
- **And** Original inventory is dropped at death coordinates.

#### Scenario: Switching Control
- **Given** Heir is selected.
- **When** Selection is confirmed.
- **Then** Camera focuses on Heir.
- **And** Controls are mapped to Heir.
- **And** Heir inherits Player Faction/Group status.
