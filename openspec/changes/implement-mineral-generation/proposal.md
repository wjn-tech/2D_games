# Mineral Generation System

## Summary
Implement a geologic mineral generation system compatible with the infinite scrolling world. This includes adding new mineral types (Iron, Copper, Magic Crystal, Staff Core, Magic Speed Stone), creating their visual assets (minimalist icons), and integrating a depth-based generation algorithm into the existing `WorldGenerator`.

## Motivation
The current world consists only of basic terrain (Dirt, Stone, Sand, etc.). To enable the planned "Manufacturing/Forging" and "Magic" gameplay loops, players need resource diversity. Implementing a depth-based mineral system encourages vertical exploration and adds value to the mining mechanic.

## Proposed Solution
1.  **Assets**: Extend the minimalist palette to include icons for new minerals.
2.  **Resources**: Create `BaseItem` resources (`.tres`) for each new mineral.
3.  **Algorithm**: Implement a stateless, noise-based generation system in `WorldGenerator` that:
    -   Uses `FastNoiseLite` to determine mineral placement (replacing generic 'stone' or 'dirt').
    -   Respects depth strata (Surface, Underground, Deep).
    -   Supports relative rarity (Common -> Very Rare).
4.  **Integration**: Hook into the chunk generation loop to populate blocks during `_generate_chunk`.

## Alternative Approaches
-   **Global Plate Simulation**: Rejected as it conflicts with the "Infinite World" architecture which requires stateless/local generation functions. We will simulate local geological features using Cellular Noise instead.
-   **Structure-based Veins (Worms)**: Complex to implement across infinite chunk boundaries without pre-generation. We will start with Noise-based blobs and clusters for Phase 1.
