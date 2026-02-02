# Proposal: Expand World Size and Implement Parallax Background

## Problem
The current world is limited to a small 200x100 area, which restricts exploration and sandbox gameplay. Additionally, the background is a solid grey color, lacking the atmosphere and depth expected in a 2D sandbox game like Terraria.

## Proposed Change
1.  **World Expansion**: Increase the default world size to 1000x500 tiles. Update the `WorldGenerator` to handle larger dimensions efficiently.
2.  **Parallax Background**: Implement a multi-layered background system that provides depth through parallax scrolling. This will include layers for the sky, distant mountains, and closer terrain features.
3.  **Atmospheric Visuals**: Configure the background to change based on the player's vertical position (e.g., showing underground backgrounds when deep enough).

## Impact
- **Gameplay**: Provides a much larger area for building, mining, and exploration.
- **Visuals**: Significantly improves the game's aesthetic and immersion.
- **Performance**: Larger tilemaps may increase initial generation time; optimizations like background generation or chunking might be considered in the future if needed.

## Verification Plan
- **Automated Tests**: None (visual/procedural).
- **Manual Verification**:
    - Run the game and verify the world size in the editor or by traveling to the edges.
    - Observe the background layers moving at different speeds while the camera moves.
    - Check that the background correctly covers the entire 1000x500 area.
