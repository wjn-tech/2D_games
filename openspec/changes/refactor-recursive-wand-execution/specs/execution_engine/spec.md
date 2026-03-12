## ADDED Requirements

### Requirement: Recursive Branch Execution
The system SHALL interpret wand graphs as recursive branch functions rather than a mixed linear-deck and child-tier runtime.

#### Scenario: Source entry compiles recursive branches
- **GIVEN** a graph with one source and multiple outgoing branches
- **WHEN** a cast cycle begins
- **THEN** the compiler SHALL produce recursive branch evaluation structures for each reachable branch
- **AND** branch execution SHALL use the same semantics for root paths, nested branches, and trigger payloads

#### Scenario: Multiple root sources share one cast cycle
- **GIVEN** a graph with two source nodes and no incoming edges on either source
- **WHEN** a cast cycle begins
- **THEN** both sources SHALL be compiled as root entries of the same cast cycle
- **AND** each source SHALL start with an empty local load and `enabled = true`
- **AND** their emission records SHALL be merged into one root-cycle emission table

### Requirement: Modifier Load Propagation
The system SHALL treat modifiers as branch-local load writes, while inherited load remains context-only and MUST NOT be charged again.

#### Scenario: Newly written modifier charges resources once
- **GIVEN** a branch that inherits one modifier from its parent and writes one new local modifier
- **WHEN** the branch is compiled for a cast cycle
- **THEN** the inherited modifier SHALL remain available in the branch context
- **AND** only the newly written modifier SHALL contribute new mana, delay, and recharge cost at that write point

### Requirement: Materialization Clears Load
The system SHALL treat projectiles and trigger projectiles as materialization points that consume the current load, apply it to the entity, and clear the local load afterward.

#### Scenario: Projectile consumes branch load
- **GIVEN** a branch with two accumulated modifiers followed by one projectile
- **WHEN** the projectile is materialized
- **THEN** the projectile SHALL be emitted with both modifiers applied
- **AND** the projectile's mana cost SHALL be added at that materialization point
- **AND** the current branch load SHALL be cleared before continuing past that node

### Requirement: Delay Table Compilation
The system SHALL compile each cast cycle into an emission table containing all root-cycle projectiles, their applied modifiers, and their non-negative fire delays.

#### Scenario: Negative delay clamps to immediate fire
- **GIVEN** a projectile whose accumulated delay is negative after modifier application
- **WHEN** the emission table is produced
- **THEN** the projectile SHALL be recorded with fire delay `0`

### Requirement: Trigger Materialization And Payload Continuation
The system SHALL treat triggers as projectiles that receive current load, clear local load, disable further delay accumulation for their payload continuation, and release payload immediately when the trigger condition is met.

#### Scenario: Trigger carries current load and payload ignores downstream delay accumulation
- **GIVEN** a branch `Modifier A -> Timer Trigger -> Modifier B -> Blast`
- **WHEN** the trigger projectile is materialized
- **THEN** the trigger SHALL receive `Modifier A`
- **AND** the payload continuation SHALL start with `delay_enable = false`
- **AND** `Modifier B` SHALL still be able to modify the payload spell's properties except for new delay accumulation

#### Scenario: Trigger releases payload at trigger location
- **GIVEN** a trigger projectile in flight with a compiled payload continuation
- **WHEN** its trigger condition is satisfied
- **THEN** the trigger SHALL be destroyed immediately
- **AND** the payload spells SHALL be emitted at the trigger's current position
- **AND** the payload direction SHALL inherit the trigger's current travel direction

#### Scenario: Nested triggers reuse precompiled continuations
- **GIVEN** a path `Source -> Trigger A -> Trigger B -> Blast`
- **WHEN** the cast cycle is compiled
- **THEN** `Trigger A` SHALL capture a continuation that already contains the compiled representation of `Trigger B`
- **AND** `Trigger B` SHALL capture its own continuation for `Blast` during the same compile phase
- **WHEN** `Trigger A` and then `Trigger B` are satisfied at runtime
- **THEN** each trigger SHALL consume only its captured continuation
- **AND** no runtime recompilation of the payload graph SHALL occur

### Requirement: Recharge After Emission Table Completion
The wand SHALL enter recharge immediately after all root-cycle emissions in the compiled table have been released.

#### Scenario: Recharge starts after final scheduled emission
- **GIVEN** a cast cycle with three root-cycle emissions at delays `0`, `0.1`, and `0.35`
- **WHEN** the third emission is released
- **THEN** the wand SHALL enter recharge immediately
- **AND** the next cast cycle SHALL remain blocked until the recharge duration completes

### Requirement: Recharge Accumulates From Branch Writes
The total recharge duration SHALL equal the wand's base recharge time plus the sum of recharge contributions from newly written load across enabled spell paths in the cast cycle.

#### Scenario: Recharge ignores inherited load duplication
- **GIVEN** two sibling branches that both inherit the same parent modifier
- **AND** each branch adds one different local modifier with its own recharge contribution
- **WHEN** the cast cycle is compiled
- **THEN** the inherited modifier's recharge contribution SHALL NOT be counted twice for the sibling branches
- **AND** each branch-local modifier's recharge contribution SHALL be counted once

#### Scenario: Trigger continuation commits recharge at compile time
- **GIVEN** a path `Source -> Timer Trigger -> Modifier R -> Blast`
- **WHEN** the cast cycle is compiled
- **THEN** the recharge contribution of `Modifier R` SHALL be included in the cast cycle's total recharge duration
- **AND** that recharge contribution SHALL remain committed even if the trigger condition is never satisfied at runtime

#### Scenario: Multiple root sources sum recharge without sharing local writes
- **GIVEN** two root sources where each source writes one different local modifier with a recharge contribution
- **WHEN** the cast cycle is compiled
- **THEN** both recharge contributions SHALL be included in the same cast cycle recharge total
- **AND** neither source SHALL inherit the other source's local modifier writes
