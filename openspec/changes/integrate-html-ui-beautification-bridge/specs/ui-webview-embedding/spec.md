## ADDED Requirements

### Requirement: WebView Adapter Abstraction
The system SHALL provide a pluggable WebView adapter abstraction so the game can switch between different embedding backends without changing gameplay logic.

#### Scenario: Adapter swap without gameplay changes
- **WHEN** the project switches adapter implementation between supported WebView providers
- **THEN** `UIManager` and gameplay scripts continue using the same adapter contract and do not require logic rewrites.

### Requirement: Embedded Inventory Pilot
The system SHALL support loading an HTML-based Inventory UI inside the running native game window for the pilot scope.

#### Scenario: Open embedded inventory
- **WHEN** the player opens Inventory in WebView mode
- **THEN** the selected WebView adapter loads the configured inventory page and displays it in-game.

### Requirement: Bidirectional Message Channel
The system SHALL provide bidirectional messaging between Godot runtime and embedded web runtime for inventory data and actions.

#### Scenario: Snapshot to web runtime
- **WHEN** Inventory opens in WebView mode
- **THEN** Godot sends a snapshot payload to the web runtime and the web UI renders from that payload.

#### Scenario: Action round-trip to Godot
- **WHEN** the player performs move/use/drop in web UI
- **THEN** the action message is delivered to Godot, validated, applied to authoritative state, and acknowledged.

### Requirement: Input Focus and Layering Safety
The system MUST coordinate gameplay input and UI focus while embedded WebView is active.

#### Scenario: WebView captures interaction
- **WHEN** web inventory is active and focused
- **THEN** gameplay input is blocked and UI interaction remains available.

#### Scenario: Close web inventory
- **WHEN** web inventory is closed
- **THEN** gameplay input is restored and focus lock is cleared.

### Requirement: Deterministic Native Fallback
The system MUST fallback to native Godot inventory UI if embedded WebView startup or runtime health checks fail.

#### Scenario: WebView initialization failure
- **WHEN** adapter initialization fails or page load exceeds the timeout
- **THEN** the system opens `res://scenes/ui/InventoryWindow.tscn` and records fallback diagnostics.

#### Scenario: Runtime web process failure
- **WHEN** the embedded web runtime crashes or disconnects during an active session
- **THEN** the system switches to native inventory UI within the configured fallback SLA.
