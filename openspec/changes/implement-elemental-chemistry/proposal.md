# Proposal: Noita-style Elemental Chemistry

Implement cellular-automata-based fluid dynamics and fire spreading to create an emergent, reactive world.

## Why
To replicate the interactive environment of Noita, where every tile reacts logically to its surroundings.

## Proposed Changes
1.  **ChemistryManager**: Handles cellular automata for Liquids (Water, Lava) and Fire.
2.  **Material Metadata**: Tag TileSet tiles with properties like `flammable`, `liquid`, `conductive`.
3.  **Simulation Window**: Optimized 128x128 update area around the player.

## Impact
- **Emergent Gameplay**: Flooding a pit to kill enemies, burning down a wooden bridge.
- **Visuals**: Alive, shifting environments.

## Acceptance Criteria
- [ ] Liquids fall into empty gaps and level out.
- [ ] Fire spreads horizontally and vertically through flammable tiles.
