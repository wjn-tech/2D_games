## ADDED Requirements

### Requirement: Core Convergence Without Mandatory Repair Passes
The runtime liquid solver SHALL converge to physically plausible states through core flow rules, without requiring repair passes as a correctness dependency.

#### Scenario: Enclosed cavity does not persist indefinitely
- **GIVEN** a connected same-type liquid body with a one-cell or short vertical-gap cavity inside a physically connected region
- **WHEN** normal core simulation runs under bounded frame budgets
- **THEN** the cavity SHALL be reduced and eliminated within a bounded tick window
- **AND** elimination SHALL be achieved by core flow convergence, not by mandatory repair-only paths

### Requirement: Downward Reachability Monotonicity
The solver SHALL guarantee downward progress when a downward path is physically reachable.

#### Scenario: Newly opened drain path
- **GIVEN** a liquid source above a blocked cavity where the player opens a valid downward path
- **WHEN** consecutive simulation ticks process the source and downstream cells
- **THEN** the source region SHALL show net downward transfer over time
- **AND** no long-lived suspended droplet state SHALL persist while the path remains reachable

### Requirement: Cross-Chunk Flow Continuity
Cross-chunk boundaries SHALL not break liquid continuity when destination chunks are temporarily unavailable.

#### Scenario: Destination chunk becomes available later
- **GIVEN** a source cell at chunk edge ready to transfer liquid into an unloaded or not-yet-writable destination chunk
- **WHEN** boundary transfer is evaluated and the destination chunk becomes writable later
- **THEN** the transfer SHALL resume through a defined handoff state
- **AND** the source SHALL not remain indefinitely suspended due only to temporary destination unavailability

### Requirement: Mass Conservation Across Runtime Lifecycle
The system SHALL conserve liquid mass across runtime transfer, unload/load, and save/reload transitions.

#### Scenario: Inflight transfer during unload and reload
- **GIVEN** liquid is in transfer or pending-handoff state while involved chunks unload and later reload
- **WHEN** runtime state is persisted and restored
- **THEN** total liquid mass SHALL remain conserved within configured floating-point tolerance
- **AND** no transfer state SHALL be silently dropped

### Requirement: Fair Scheduling Under Budget Constraints
Budget-limited simulation SHALL provide eventual processing fairness for active liquid cells.

#### Scenario: High activity burst
- **GIVEN** a large number of active liquid cells after major terrain edits
- **WHEN** per-frame budget is repeatedly saturated
- **THEN** deferred cells SHALL still be processed in later frames without permanent starvation
- **AND** the system SHALL avoid localized long-term freeze while neighboring cells continue updating

### Requirement: Physics-Render Consistency for Connectivity
Rendering thresholds SHALL not hide physically critical connectivity in a way that produces persistent floating-liquid perception.

#### Scenario: Thin film that carries connectivity
- **GIVEN** a thin liquid connector above clear-epsilon that is required for local hydraulic continuity
- **WHEN** overlay rendering evaluates visibility thresholds
- **THEN** the connector SHALL remain visually perceivable through a minimum display rule
- **AND** players SHALL not observe a persistent visual gap that contradicts physics continuity
