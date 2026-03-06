# Interactive Narrative Tutorial Proposal

This proposal aims to rewrite the tutorial flow into a complete narrative experience where the player learns game mechanics (Movement, Inventory, Equipment, Spell Editing) within the context of a dramatic spaceship crash sequence guided by a Court Mage.

## Motivation

The current tutorial is too static and disconnected from the game's core "Magic Logic" mechanic. Players need to learn how to program spells (Wand Editor) before entering the world. The narrative also needs to establish the stakes (Stolen Magic, Crash Landing).

## Objectives

1.  **Narrative Immersion**: Use the "Court Mage" character to deliver backstory and urgency.
2.  **Mandatory Logic Training**: Force the player to open the `Wand Editor` and connect a `Trigger` to a `Projectile` to understand the magic system.
3.  **Visual Feedback**: Use screen shake, alarms, and UI highlighting to guide the player.
4.  **Seamless Transition**: End with a dramatic crash that transitions to the main world, stripping the player of the tutorial items to reset progression.

## Scope

- **Systems**: `TutorialSequenceManager`, `WandEditor` (Signal Hooks), `InventorySystem`.
- **Content**: `spaceship2.tscn`, `breakable_wall.tscn`, `TestWand`, `TriggerItem`, `ProjectileItem`.
- **Out of Scope**: Complex combat tutorials (reserved for later).
