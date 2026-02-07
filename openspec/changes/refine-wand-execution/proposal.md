# Refine Wand Execution System

| Attribute | Value |
| :--- | :--- |
| **Status** | Draft |
| **Type** | Feature |
| **Owner** | Agent |
| **Created** | 2026-02-05 |

## Summary
Refactor the spell execution engine to support a tiered, recursive projectile system where triggers act as deferred execution points, and distinct "waves" of spells are fired based on graph topology.

## Problem Code
The current `SpellProcessor` (likely a placeholder or simple BFS) processes the wand graph as an instantaneous logic circuit. It fails to support:
1. **Deferred Execution:** Spells firing *after* a projectile hits or expires.
2. **Tiered Waves:** Grouping spells into "First Wave", "Second Wave (Children of Triggers)", etc.
3. **Physical Triggers:** Treating "Timers" and "Collisions" as projectiles that carry nested spell payloads.

## Proposed Solution
Implement a **Spell Compilation** step that runs when the wand is edited (or first equipped). This compiler transforms the raw Node Graph into a structured **Execution Tree**.

### Key Concepts
- **Mana Source:** The root of the execution.
- **Tier 1:** All spells (Blasts or Triggers) reachable from the source, passing through modifiers.
- **Modifiers:** Apply only to the specific spell in their path.
- **Triggers:** treated as a special type of "Projectile" that carries a **Next Tier** definition. When the trigger condition is met, the Next Tier is executed at the projectile's location.
- **Recursion:** This structure allows for infinite nesting (e.g., Timer -> Timer -> Blast).

## Impact
- **Systems:** `src/systems/magic/`
- **Files:**
    - `spell_processor.gd` (Rewrite)
    - `wand_data.gd` (Add compiled cache)
    - `spell_payload.gd` (Update to support recursive payloads)
- **Performance:** Compilation happens once (save/load), execution is efficient (iterating pre-built arrays).
