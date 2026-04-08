## ADDED Requirements

### Requirement: Signature Combat Identity per Hostile Family
The system SHALL define at least one signature combat pattern per approved hostile family so that encounter identity is behavior-distinct, not only visual.

#### Scenario: Family identity verification
- **WHEN** reviewing a hostile family definition
- **THEN** it includes signature behavior metadata with telegraph, threat window, and intended player counterplay

### Requirement: High-Risk Mechanics Default Enabled
The system SHALL enable high-risk mechanics (hard control, lethal pull, instant-kill class effects) by default in runtime behavior packages.

#### Scenario: Default-on behavior package
- **WHEN** a hostile family with high-risk signature mechanics is loaded
- **THEN** those mechanics are active by default without requiring an opt-in feature flag

### Requirement: Terrain-Behavior Coherence
The system SHALL keep hostile behavior aligned with habitat semantics so mechanics reinforce terrain identity.

#### Scenario: Cave specialist behavior
- **WHEN** a cave-specialized family spawns in tunnel or chamber contexts
- **THEN** its active behavior package uses cave-relevant movement/attack patterns rather than generic surface behavior

### Requirement: Fairness and Counterplay Guarantees
The system SHALL enforce readability and counterplay windows for signature mechanics.

#### Scenario: No untelegraphed unavoidable burst
- **WHEN** a signature attack can disable movement or cause lethal damage
- **THEN** the attack includes a readable telegraph and a configurable reaction window before effect application

### Requirement: Behavior Dependency Degradation
The system SHALL degrade gracefully when optional subsystems required by a behavior are not available.

#### Scenario: Missing subsystem fallback
- **WHEN** a behavior references an unavailable subsystem (for example sanity or equipment corrosion)
- **THEN** the family remains spawnable and executes a documented fallback effect profile

### Requirement: Excluded Peripheral Status Systems
The system SHALL NOT introduce new sanity, thirst, equipment durability corrosion, or QTE escape subsystems as part of this change.

#### Scenario: Scope guard for behavior implementation
- **WHEN** implementing signature hostile behaviors in this change
- **THEN** behavior effects use existing combat/status infrastructure and do not add new peripheral status subsystems
