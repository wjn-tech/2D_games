# Design: Fix TradeWindow open_window arguments in BaseNPC

## Architectural Reasoning
The `UIManager` requires a scene path to instantiate windows that are not already in the scene tree. The `BaseNPC` script handles opening the trade window when the player selects the "Trade" option in the dialogue.

Providing the explicit path ensures the `UIManager` can find and open the `TradeWindow`.

## Trade-offs
None. This is a required fix for a syntax/runtime error.

## Verification Plan
- **Static Analysis**: Verify the script compiles without "too few arguments" errors.
- **Manual Test**: Interact with an NPC, select "Trade", and verify the trade window opens correctly.
