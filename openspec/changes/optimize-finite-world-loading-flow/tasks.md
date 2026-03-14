## 1. Baseline Audit and Startup Scope
- [x] 1.1 Trace the current new-game and load-game flow across MainMenu, SaveSelection, GameManager, scene reload, world startup, player spawn, and HUD reveal.
- [x] 1.2 Identify which current startup steps are critical-ready versus which ones can be deferred without exposing a broken or unsafe world.
- [x] 1.3 Document which nodes, systems, and UI layers must remain hidden or disabled while the startup gate is active.

## 2. Startup State and Readiness Contract
- [x] 2.1 Add a distinct startup loading state to the orchestration model so scene reload completion no longer implies immediate gameplay access.
- [x] 2.2 Define a startup readiness provider contract for GameManager, world bootstrap, save restore, and spawn safety checks.
- [x] 2.3 Define the canonical startup stages, their weights, and the exact completion condition for each stage.
- [x] 2.4 Define timeout, failure, and recovery rules for any startup stage that cannot confirm readiness.

## 3. Progress Reporting and Finite Bootstrap Coverage
- [x] 3.1 Route both new-game and load-game entry through the same staged progress pipeline.
- [x] 3.2 Define how world metadata restore and topology setup contribute to startup progress.
- [x] 3.3 Define how world generator startup, critical chunk warmup, or finite-world bootstrap contribute to startup progress.
- [x] 3.4 Define a spawn-area-ready checkpoint that covers safe placement, nearby terrain availability, and required critical world data.
- [x] 3.5 Ensure deferred enrichment work cannot keep the progress model below completion after critical-ready has been achieved.

## 4. Loading Overlay and Progress Animation
- [x] 4.1 Define a persistent transition-layer loading overlay that survives scene changes.
- [x] 4.2 Define the loading overlay contents, including progress bar animation, stage/status text, and minimum blocking behavior.
- [x] 4.3 Define how main-menu fade-out, loading overlay fade-in, HUD reveal, and loading overlay fade-out are sequenced.
- [x] 4.4 Define the failure-state presentation so blocked loading remains understandable and recoverable.

## 5. Player, HUD, and Runtime Gating
- [x] 5.1 Keep player input disabled until the final gameplay handoff stage explicitly releases it.
- [x] 5.2 Keep player process, HUD visibility, and other enter-world signals gated until critical-ready is complete.
- [x] 5.3 Define how entity visibility and high-risk runtime systems avoid exposing half-initialized gameplay before release.
- [x] 5.4 Use one shared release path for new-game and load-game so player/HUD/world activation order cannot drift.

## 6. Validation
- [ ] 6.1 Validate that starting a new world does not expose the player, HUD, or interactive gameplay before the startup gate finishes.
- [ ] 6.2 Validate that loading an existing save also uses the startup gate and progress model rather than bypassing it.
- [ ] 6.3 Validate that finite or planetary world bootstrap can hold the gate until critical world readiness is actually satisfied.
- [ ] 6.4 Validate that deferred startup work can continue without visible hitch-prone re-entry or premature progress regressions.
- [x] 6.5 Run openspec validate optimize-finite-world-loading-flow --strict.