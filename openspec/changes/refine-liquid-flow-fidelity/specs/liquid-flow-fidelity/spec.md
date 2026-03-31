## ADDED Requirements

### Requirement: Continuous Liquid Transfer
The liquid simulation SHALL prefer temporally continuous transfer over coarse single-step movement while preserving aggregate throughput targets.

#### Scenario: Cavity drain continuity
- **GIVEN** a supported water column above a newly opened cavity
- **WHEN** the runtime solver processes active cells across consecutive ticks
- **THEN** the observed liquid descent SHALL occur in multiple micro-steps rather than a single abrupt jump
- **AND** the total transferred volume over a fixed time window SHALL remain within configured throughput tolerance

#### Scenario: Waterfall mode does not flicker at boundary conditions
- **GIVEN** a water source at an almost-open fall column where topology oscillates near the open/closed threshold
- **WHEN** consecutive ticks evaluate open-column direct-fall eligibility
- **THEN** direct-fall mode SHALL persist for a short hysteresis window instead of rapidly toggling with packet-only mode
- **AND** the hysteresis mode SHALL expire automatically when the hold window elapses or immediate drop compatibility is broken

#### Scenario: Waterfall mode prioritizes vertical descent
- **GIVEN** a water source cell in open-column direct-fall mode
- **WHEN** the solver computes transfer for consecutive active ticks
- **THEN** downward transfer SHALL keep a minimum waterfall slice before lateral redistribution
- **AND** open-fall cooldown SHALL be shorter than regular water fall cooldown
- **AND** lateral spread during open-fall mode SHALL be damped to preserve waterfall column continuity

### Requirement: Local Pressure Equalization
The solver SHALL perform bounded local pressure equalization for active neighborhoods to reduce staircase and checkerboard liquid fronts.

#### Scenario: Neighboring pools balance smoothly
- **GIVEN** two connected pools with different local fill levels
- **WHEN** active-cell simulation runs under normal budget
- **THEN** lateral redistribution SHALL reduce level discontinuity over successive ticks
- **AND** equalization SHALL not require a global world sweep

#### Scenario: Water-only split gain remains bounded
- **GIVEN** a water lateral transfer candidate that already passed quantized flow checks
- **WHEN** split gain is applied for Terraria-like mild amplification
- **THEN** the transfer SHALL be limited to a small fixed multiplier (+1%)
- **AND** the result SHALL remain capped by source available amount and destination capacity
- **AND** non-water liquids SHALL bypass this gain path

### Requirement: Waterfall Render Continuity
Low-volume vertical water streams SHALL render as visually continuous columns instead of discrete shelf-like strips.

#### Scenario: Thin waterfall visual cohesion
- **GIVEN** vertically connected low-volume water cells in a drop column
- **WHEN** overlay rendering draws runtime liquid cells
- **THEN** the stream SHALL be drawn as a blended full-width stream sheet with continuity across tile boundaries
- **AND** repeated per-tile shelf lines SHALL not dominate the final waterfall appearance

### Requirement: Seam Void Bubble Collapse
The solver SHALL collapse one-tile seam voids enclosed by same-type liquid above and below, even when lateral support is absent.

#### Scenario: Horizontal slit cavity inside a water body
- **GIVEN** a one-tile empty seam cell with same-type liquid above and below but sparse/empty left-right neighbors
- **WHEN** bubble-collapse cleanup runs under normal bounded budget
- **THEN** the seam void SHALL receive liquid via conservative donor transfer from the vertical neighbors
- **AND** total liquid mass SHALL remain conserved within floating-point tolerance

#### Scenario: Multi-cell vertical seam gap between upper/lower pools
- **GIVEN** an upper same-type liquid slab and a lower same-type liquid slab with a bounded multi-cell vertical air gap between them
- **WHEN** bubble-collapse cleanup runs for consecutive bounded passes
- **THEN** the solver SHALL probe bounded-depth vertical endpoints and progressively fill the seam cells without requiring immediate-neighbor top/bottom liquid
- **AND** bridge transfer SHALL keep filled seam cells above render visibility threshold to avoid apparent floating slabs caused by hidden connectors
- **AND** total liquid mass SHALL remain conserved within floating-point tolerance

#### Scenario: Thin intermediate film does not block deep seam endpoint detection
- **GIVEN** a seam candidate where a same-type thin intermediate film exists above/below the candidate, and a stable same-type endpoint exists deeper in the same direction
- **WHEN** seam endpoint probing runs within bounded depth
- **THEN** probing SHALL continue past the thin intermediate film instead of early-failing
- **AND** the deeper stable endpoint SHALL remain eligible as the bridge donor endpoint

#### Scenario: Visible thin cap can bridge to lower pool
- **GIVEN** an upper same-type thin cap that is visible in overlay rendering and a lower same-type pool separated by a one-cell air gap
- **WHEN** seam bubble-collapse processing evaluates the gap cell
- **THEN** the visible thin cap SHALL remain eligible for vertical seam bridge matching
- **AND** the gap cell SHALL be filled through conservative donor transfer instead of persisting as a visible floating-cap bubble

#### Scenario: Underfilled seam candidate is topped up
- **GIVEN** a seam candidate cell that already contains same-type liquid above clear epsilon but still below seam-bridge threshold
- **WHEN** seam bubble-collapse processing evaluates top/bottom enclosed bridge conditions
- **THEN** the candidate SHALL be eligible for conservative top-up transfer instead of being skipped as non-empty
- **AND** the topped-up candidate SHALL become a stable bridge cell that removes persistent gap rows between upper/lower pools

### Requirement: Downward Transfer Dead-Zone Elimination
Thin liquid films SHALL continue draining downward under gravity even when quantized transfer would otherwise round to zero.

#### Scenario: Sub-quantum film above empty cell
- **GIVEN** a thin water film amount smaller than the downward transfer quantum
- **WHEN** open-fall mode is inactive and normal downward transfer is computed
- **THEN** a bounded micro-trickle fallback SHALL transfer liquid downward instead of producing a persistent suspended film
- **AND** the source cell SHALL remain scheduled for retry when non-zero downward capacity exists

### Requirement: Cooldown-Aware Activation Scheduling
Cells blocked by fall cooldown SHALL be re-activated when cooldown expires, not retried every frame.

#### Scenario: Cooldown-blocked waterfall cells under load
- **GIVEN** many active cells currently waiting for per-cell fall cooldown timers
- **WHEN** frame simulation runs before cooldown expiry
- **THEN** cooldown-blocked cells SHALL not be immediately re-enqueued each frame
- **AND** a bounded scheduler SHALL enqueue ready cells once their cooldown timestamp has elapsed

### Requirement: Directional Flow Stability
The solver SHALL provide short-lived directional stability so adjacent ticks do not repeatedly flip flow direction under near-equal conditions.

#### Scenario: Avoid frame-to-frame oscillation
- **GIVEN** a shallow surface where left and right capacities are near equal
- **WHEN** simulation updates run for consecutive ticks
- **THEN** flow direction SHALL remain stable for a short decay window before reevaluation
- **AND** stability SHALL decay automatically to avoid long-term bias

### Requirement: Budget-Safe Fidelity
Fidelity improvements SHALL operate within explicit per-frame simulation budgets and degrade gracefully when limits are reached.

#### Scenario: High activity budget pressure
- **GIVEN** many active liquid cells after large terrain edits
- **WHEN** per-frame liquid budget is exhausted
- **THEN** the system SHALL defer remaining updates without invalid states
- **AND** deferred cells SHALL resume in subsequent frames without starvation

### Requirement: Core Runtime Flow Without Repair Passes
Runtime flow SHALL support a core-logic mode that excludes post-simulation repair passes.

#### Scenario: Core-only processing loop
- **GIVEN** the runtime is operating in core-logic mode
- **WHEN** per-frame liquid processing executes
- **THEN** only active-cell gravity/lateral simulation, packet settlement, and cooldown-ready activation scheduling SHALL run
- **AND** static hole fill, fast local relax, pressure equalization, and bubble-collapse repair passes SHALL be skipped

#### Scenario: Downstream-capacity wait does not sleep potential-flow source cells
- **GIVEN** a source cell is temporarily blocked only because the cell below is at full capacity and may free space in subsequent ticks
- **WHEN** core runtime processing evaluates this source cell
- **THEN** the below cell SHALL be prioritized for wake-up
- **AND** the source cell SHALL receive delayed self-retry scheduling instead of immediate busy requeue
- **AND** the source cell SHALL remain eligible to resume downward flow once downstream capacity reopens

#### Scenario: Downstream-capacity wait avoids uphill-looking side growth
- **GIVEN** a source cell is in downstream-capacity wait while lower layers are draining
- **WHEN** core runtime processing evaluates this source tick
- **THEN** same-tick lateral spread and edge-spill from that source SHALL be suppressed
- **AND** no new side cell SHALL be created from that source until downstream wait clears

### Requirement: Persistence Parity Under Fidelity Tuning
Flow-fidelity behavior SHALL not change save/load correctness for liquid state.

#### Scenario: Save and reload parity
- **GIVEN** chunks containing dynamic liquid states, including initialized-but-empty liquid chunks
- **WHEN** the world is saved and then reloaded
- **THEN** liquid distribution SHALL match the pre-save authoritative state
- **AND** generation-time seeds SHALL NOT overwrite persisted liquid state for initialized chunks
