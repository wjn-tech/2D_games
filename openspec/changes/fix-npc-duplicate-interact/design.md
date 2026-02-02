# Design: Fix duplicate interact function in BaseNPC

## Architectural Reasoning
The `interact()` function is the entry point for player interaction with NPCs. During the recent expansion of the NPC system, a new version of `interact()` was added with dialogue and trading support, but the old placeholder version was not removed.

Removing the old version restores script validity while preserving the new functionality.

## Trade-offs
None. This is a bug fix for a syntax error.

## Verification Plan
- **Static Analysis**: Verify that the script no longer reports a duplicate function error.
- **Manual Test**: Interact with an NPC in-game and verify that the dialogue system still triggers correctly.
