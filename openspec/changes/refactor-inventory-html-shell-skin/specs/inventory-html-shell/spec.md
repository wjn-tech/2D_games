## ADDED Requirements

### Requirement: InventoryWindow HTML Shell Scope
The system SHALL apply embedded HTML shell rendering to InventoryWindow only for this change.

#### Scenario: Open inventory in gameplay with shell available
- **WHEN** the player opens InventoryWindow during gameplay and the shell resource is available
- **THEN** the system renders InventoryWindow using the embedded HTML shell
- **AND** no other inventory-related windows are migrated in this change

#### Scenario: Scope guard for non-target windows
- **WHEN** CharacterPanel, TradeWindow, or other windows are opened
- **THEN** they continue using their existing implementation in this change

### Requirement: Strict Inventory Logic Parity
The system SHALL preserve all inventory-related gameplay logic and behavior exactly as currently implemented.

#### Scenario: Action execution remains Godot-authoritative
- **WHEN** the user performs inventory actions from the HTML shell (including move, use, drop, tab switch, and close)
- **THEN** the action is resolved through existing Godot inventory logic paths
- **AND** resulting behavior matches the native implementation

#### Scenario: Save and load parity remains unchanged
- **WHEN** inventory state is saved and later loaded after using the HTML shell
- **THEN** the saved data structure and restored behavior remain compatible with current save/load logic

### Requirement: Visual Shell Replacement Without Text Source Drift
The system SHALL replace only presentation architecture and preserve existing localization and text source behavior.

#### Scenario: Existing localized text remains authoritative
- **WHEN** InventoryWindow is displayed in the HTML shell
- **THEN** labels and text content follow existing localization/text sources
- **AND** no new hardcoded English-only text replaces localized content

### Requirement: Static Build and Packaged Shell Assets
The system SHALL use static build artifacts from inventory_ui and package them as runtime shell assets.

#### Scenario: Runtime loads packaged static shell
- **WHEN** the game starts and InventoryWindow is opened
- **THEN** the shell loads from packaged static files under ui/web/inventory_shell
- **AND** no external development server is required

### Requirement: Mandatory Native Fallback
The system SHALL automatically fall back to native InventoryWindow rendering when HTML shell runtime is unavailable or unhealthy.

#### Scenario: WebView class or shell resource unavailable
- **WHEN** WebView cannot initialize or shell files are missing
- **THEN** the system logs a warning
- **AND** InventoryWindow remains usable through native fallback

#### Scenario: Bridge failure during runtime
- **WHEN** bridge communication fails or becomes invalid while inventory is open
- **THEN** the system exits the shell path safely
- **AND** preserves usability via native fallback without corrupting inventory state
