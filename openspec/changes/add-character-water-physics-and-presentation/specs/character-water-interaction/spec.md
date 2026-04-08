## ADDED Requirements

### Requirement: Character Controller SHALL Derive Water State from Authoritative Liquid Data
Character movement SHALL derive water interaction state from runtime authoritative liquid occupancy and fill amount, not from visual-only overlays.

#### Scenario: Physics tick state sampling
- **WHEN** a character physics tick begins
- **THEN** the controller samples water contact probes against authoritative liquid data
- **AND** computes a deterministic immersion ratio used for this tick

#### Scenario: Visual/render decoupling
- **WHEN** overlay rendering differs from exact cell visuals due to presentation smoothing
- **THEN** controller water state still follows authoritative simulation data
- **AND** movement behavior remains deterministic

### Requirement: Character Movement SHALL Apply Immersion-Based Motion Modifiers
Character movement SHALL apply drag, buoyancy blend, and jump modulation according to immersion-defined water state.

#### Scenario: Entering wading/swimming
- **WHEN** immersion crosses configured thresholds into `wading` or `swimming`
- **THEN** horizontal acceleration and top-speed are reduced by configured drag curves
- **AND** vertical motion transitions to blended gravity/buoyancy behavior

#### Scenario: Submerged control profile
- **WHEN** head-level immersion crosses submerged threshold
- **THEN** controller applies submerged movement profile
- **AND** jump semantics switch to swim-up modulation rules

#### Scenario: Exit recovery
- **WHEN** immersion falls below exit hysteresis threshold
- **THEN** dry-state movement profile is restored within bounded recovery time
- **AND** stale water modifiers are fully cleared

### Requirement: Water Interaction Events SHALL Drive Presentation with Throttling
Water interaction SHALL expose transition events for audiovisual feedback with anti-spam throttling.

#### Scenario: Entry and exit events
- **WHEN** character transitions across dry/wet boundary
- **THEN** `enter_water` or `exit_water` event emits once per transition
- **AND** one-shot splash audio/visual cues respect cooldown limits

#### Scenario: Surface-break readability event
- **WHEN** character crosses the waterline between swimming and non-submerged states
- **THEN** a dedicated `surface_break` event emits
- **AND** presentation system applies the configured cue for readability

### Requirement: Water Interaction SHALL Preserve Existing Core Movement Contracts
Water behavior SHALL integrate without breaking existing movement systems such as knockback, coyote time, and jump buffering.

#### Scenario: Knockback in water
- **WHEN** a character receives knockback while immersed
- **THEN** knockback force is applied first as source impulse
- **AND** immersion damping modifies resulting movement without canceling the hit response

#### Scenario: Jump buffer and coyote compatibility
- **WHEN** water-state transitions occur near jump input windows
- **THEN** jump buffer and coyote logic remain well-defined
- **AND** no duplicate jump-trigger or lost-input regressions are introduced

### Requirement: Runtime SHALL Keep Water-State Updates Deterministic and Bounded
Water interaction updates SHALL execute in deterministic order with bounded per-tick cost.

#### Scenario: Fixed update ordering
- **WHEN** the physics tick runs
- **THEN** water-state evaluation executes in a stable, documented order before final velocity integration
- **AND** the same input sequence yields the same state transitions

#### Scenario: Probe cost bound
- **WHEN** many characters are active near water boundaries
- **THEN** probe count and lookup operations stay within configured per-character bounds
- **AND** no unbounded per-frame scan is introduced
