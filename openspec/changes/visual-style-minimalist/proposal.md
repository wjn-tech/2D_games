# Minimalist Visual Style Overhaul

## Summary
Switch the game visual style from pixel-art sprites to a minimalist, procedural solid-color aesthetic. This includes flattening the background, replacing tile textures with solid blocks, and simplifying entities.

## Goals
- **Minimalist Aesthetic**: Pure white background fading to black underground.
- **Solid Color Tiles**: Clear visual distinction for materials (Dirt=Brown, Mud=Black, Grass=Green, etc.).
- **Editable Models**: Characters and trees represented by simple block patterns that can be easily edited.
- **Consistent Brightness**: Adjust surface brightness to be "appropriate" (not blinding), maintaining the dark underground atmosphere.

## Key Changes
1. **Background**: Reset `ParallaxBackground` to a simple solid color gradient system.
2. **Tileset**: Create a new dynamic/solid-color `TileSet` resource and update `WorldGenerator`.
3. **Trees**: Procedurally generate blocky trees (Green/Brown blocks) matching the new specification.
4. **Entities**: Replace Character sprites with 1x2 solid block representations.
