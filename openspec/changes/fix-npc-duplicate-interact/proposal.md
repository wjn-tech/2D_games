# Proposal: Fix duplicate interact function in BaseNPC

## 1. Problem Statement
The `BaseNPC` script (`src/systems/npc/base_npc.gd`) contains two definitions of the `interact()` function. This causes a GDScript error: `Function "interact" has the same name as a previously declared function.`

## 2. Proposed Solution
Remove the redundant and less functional `interact()` definition at the end of the file, keeping the one that implements the dialogue and trading logic.

## 3. Scope
- `src/systems/npc/base_npc.gd`: Remove the duplicate function.

## 4. Dependencies
None.
