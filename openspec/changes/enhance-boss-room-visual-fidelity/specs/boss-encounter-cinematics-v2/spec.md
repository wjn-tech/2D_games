## ADDED Requirements

### Requirement: Boss Encounter Intro SHALL Provide Enhanced Camera Rhythm Without Rule Drift
Boss encounter intro SHALL enhance camera rhythm while preserving existing entry/exit gameplay rules.

#### Scenario: Enhanced intro compatibility
- **GIVEN** player triggers any boss encounter
- **WHEN** intro sequence runs
- **THEN** camera performs a configured focus transition with enhanced rhythm
- **AND** existing encounter trigger consumption and return-position rules remain unchanged

### Requirement: Cinematic Timing SHALL Protect Player Agency
Cinematic enhancements SHALL not block player control beyond a defined upper bound.

#### Scenario: Control lock upper bound
- **GIVEN** intro cinematic is active
- **WHEN** timing validation runs
- **THEN** player input lock duration does not exceed configured ceiling
- **AND** combat activation occurs immediately after lock release

### Requirement: Phase Events SHALL Emit Distinct Visual Signals
Boss phase transitions SHALL emit explicit visual signals that are readable without audio dependency.

#### Scenario: Phase transition signal
- **GIVEN** a boss enters a new phase
- **WHEN** phase transition occurs
- **THEN** encounter scene emits a distinct visual cue tied to that phase event
- **AND** cue is distinguishable from baseline ambience

### Requirement: Cinematic Enhancements SHALL Fail Gracefully
If optional cinematic effects are unavailable, encounter flow SHALL continue with a deterministic fallback.

#### Scenario: Missing optional cinematic component
- **GIVEN** an optional cinematic component fails to load
- **WHEN** encounter intro starts
- **THEN** system falls back to baseline focus flow
- **AND** encounter still starts and completes without soft lock

### Requirement: Cinematic v2 SHALL Be Regression-Gated
Cinematic enhancements SHALL be covered by regression checks alongside existing boss progression pipeline checks.

#### Scenario: Pipeline integration
- **GIVEN** cinematic v2 updates are present
- **WHEN** boss progression pipeline checks run
- **THEN** visual/cinematic contract checks execute with progression checks
- **AND** pipeline fails on cinematic contract violations