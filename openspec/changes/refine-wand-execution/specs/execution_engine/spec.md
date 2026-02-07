# Spec: Spell Execution Engine

## ADDED Requirements

#### Requirement: Compile-Time Graph Analysis
The system must compile the visual node graph into a structured, nested execution tree before casting.

#### Scenario: Basic compilation
- **Given** a graph: `Source -> Fire Mod -> Blast`.
- **When** the wand is equipped.
- **Then** the compiler produces a `RootTier` containing one `SpellInstruction`.
- **And** the instruction has type `Blast` and includes a `Fire` modifier.

#### Scenario: Recursive compilation
- **Given** a graph: `Source -> Timer Trigger -> Blast`.
- **When** compiled.
- **Then** the `RootTier` contains one `TriggerInstruction` (Timer).
- **And** the `TriggerInstruction` contains a `child_tier` with one `SpellInstruction` (Blast).

#### Requirement: Mana Capacity Validation
The compiler must reject any configuration where the total mana cost exceeds the wand's capacity.

#### Scenario: Overcharged Wand
- **Given** a wand with `max_mana = 100`.
- **And** a graph with 3 nodes costing 40 mana each (Total 120).
- **When** saving/compiling.
- **Then** the operation fails with a "Mana Limit Exceeded" error.

#### Requirement: Loop Prevention
The compiler must detect and reject circular dependencies in the graph.

#### Scenario: Infinite Loop
- **Given** a graph where `Trigger A` connects to `Trigger B`, and `Trigger B` connects back to `Trigger A`.
- **When** saving/compiling.
- **Then** the operation fails with a "Cycle Detected" error.

#### Requirement: Tier 1 Execution (The Wave)
Activating the wand fires all valid endpoints found in the first traversal pass simultaneously.

#### Scenario: Twin Blasts
- **Given** a graph where `Source` connects to `Blast A` and `Blast B`.
- **When** the wand is cast.
- **Then** both `Blast A` and `Blast B` are spawned instantly.
- **And** the wand enters cooldown only after this wave is emitted.

#### Requirement: Trigger Propagation
Trigger entities must act as projectiles that execute their stored child tier upon specific events.

#### Scenario: Timer Trigger (Bullet)
- **Given** a `Timer Trigger (2s)` projectile in flight.
- **When** 2 seconds elapse.
- **Then** the projectile spawns its `child_tier` at its current location.
- **And** the projectile is destroyed.
- **But** if it hits a wall *before* 2s, it is destroyed *without* spawning children.

#### Scenario: Collision Trigger (Bullet)
- **Given** a `Collision Trigger` projectile in flight.
- **When** it hits an enemy/wall.
- **Then** it spawns its `child_tier` at the collision point.
- **And** the projectile is destroyed.

#### Requirement: Modifier Strict Scoping
Modifiers must apply ONLY to the immediate Action or Trigger node they precede, and are NOT inherited by child tiers.

#### Scenario: Modifiers do not cross tiers
- **Given** a graph: `Source -> Fire Mod -> Timer Trigger -> Blast`.
- **When** cast.
- **Then** the `Timer Trigger` projectile has "Fire" properties (e.g., burning visual, contact damage).
- **When** the Timer expires and spawns `Blast`.
- **Then** the `Blast` has standard properties (NO Fire).

