## ADDED Requirements

### Requirement: Hitch-Safe Autosave Pipeline
The save system SHALL perform autosave work without introducing repeatable gameplay hitch spikes during exploration.

#### Scenario: Autosave avoids single-frame blocking spike
- **WHEN** autosave is triggered during active exploration
- **THEN** save work is executed under bounded per-frame budget rules
- **AND** gameplay frame-time does not exhibit periodic spikes aligned with autosave interval

#### Scenario: Manual save preserves data integrity
- **WHEN** the player performs an explicit manual save
- **THEN** the system completes an integrity-preserving flush path before reporting save success
- **AND** deferred autosave buffers are reconciled safely

### Requirement: Dirty-Only Delta Persistence
Chunk delta persistence SHALL avoid full-cache synchronous flushes during gameplay-time save paths.

#### Scenario: Non-dirty chunks are skipped
- **WHEN** world delta persistence runs during gameplay-time maintenance or autosave
- **THEN** unchanged chunks are not rewritten to disk
- **AND** only dirty chunks are scheduled for write

#### Scenario: Transition points force consistency
- **WHEN** the game enters a critical transition (manual save confirmation, scene exit, or quit)
- **THEN** all pending dirty chunk writes are flushed to a consistent state
- **AND** world delta metadata remains recoverable on next load
