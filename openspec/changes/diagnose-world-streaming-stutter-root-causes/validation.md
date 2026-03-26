## Validation Scenario

### Script
- `res://tools/validate_streaming_hitch_contracts.gd`

### Intended run command
```powershell
godot --headless --path . --script res://tools/validate_streaming_hitch_contracts.gd
```

## Acceptance Thresholds
- Walking route frame-time target:
  - P50 <= 16.7 ms
  - P95 <= 25.0 ms
  - P99 <= 33.0 ms
- Streaming stage budgets:
  - `critical_load` <= 5.0 ms
  - `enrichment` <= 3.0 ms
  - `unload` <= 2.5 ms
  - `entity_spawn` <= 2.0 ms
  - `dirty_flush` <= 2.5 ms
- Autosave hitch condition:
  - No repeatable spike cluster aligned with autosave cadence.

## Notes
- The current environment may not provide a runnable Godot CLI; when unavailable, use static code checks and defer runtime metric capture to an environment with Godot executable configured.
