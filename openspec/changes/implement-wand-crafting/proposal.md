# Proposal: Magic Wand Synthesis System

## Summary
Implement a modular Wand Crafting System where players can synthesize "Wand Embryos", customize their appearance pixel-by-pixel, and program their magical effects using a circuit-like logic system. This system transforms weapon crafting from simple recipe output to a highly customizable, creative process.

## Background
The current weapon system is standard. The user wants a "Magic Wand" system that allows for:
1.  **Progression**: Tiered "Embryos" (bases) with limits.
2.  **Customization**: Visual customization (1x1 held sprite, but edited as a grid).
3.  **Strategy**: Logic-based spell construction (Circuit connection of materials).

## Goals
-   **Wand Embryos**: Base items with levels, dictating grid resolution and capacities. Container only (no inherent attack).
-   **Visual Editor**: A grid-based editor to "draw" the wand using materials. Materials are consumed and add stats.
-   **Logic Editor**: A free-node graph editor to chain varying "Attack Materials" (Splitters, Modifiers, Emitters).
-   **Runtime Execution**: A system to interpret the logic graph and execute effects when the player attacks.

## Scope
-   **New Data Structures**: `WandEmbryo`, `WandInstance`, `LogicGraph`.
-   **New UI**: Wand Editor (Visual Grid + Graph View).
-   **New Mechanics**: Spell logic processing pipeline (DAG traversal).
-   **Assets**: Minimalist wand templates, UI assets for the editor.

## Open Questions / Risks
-   **Performance**: Complex logic chains need efficient caching/compilation to avoid lag on every attack.
-   **Input**: Defaulting to "Left Click" to use, "C" to edit.
-   **Decoration Materials**: Assuming these are purely cosmetic in the Visual Editor, but "Additional Materials" for stats are separate slots.
