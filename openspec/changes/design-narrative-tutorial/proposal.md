# Proposal: Narrative Tutorial

## Goal
Design an engaging narrative-driven tutorial that guides the player through the lore ("Kingdom of Magic robbed by monsters"), introduces core UI components (Wand Editor, Crafting), blocks skipping, and transitions dramatically into the main game via a crashing spaceship. The player must be rooted during the experience, successfully pass UI validation checks, and have the option to skip directly to the crash.

## Context
The game currently starts either in the main menu or dropping the player straight into the world. To bridge this gap, a "Court Mage" NPC will deliver exposition on a closed "Spaceship" scene, tying the player's descent into a cohesive mythical narrative.
1. **Lore (The Fall of Magic):** The player is escaping from a dying Kingdom of Magic situated in the Star Sea. The world below is overrun by monsters that have stolen the very concept of "Magic," scattering spells and runes across the wild. The player's grand mission is to reclaim these lost magics, physically rebuilding the dynasty from the dirt up.
2. **Dynamic Dispensation:** As the ship is attacked (represented by screen shakes), the Mage realizes they won't make a clean landing and dynamically gives the player the last salvageable base items mid-dialogue.
3. **Combat/Magic:** Wand Editor tutorial where the player is forced to compile the sole surviving spell (a basic attack) to defend themselves upon crash-landing.
4. **Crafting:** Inventory and Crafting UI tutorial so the player understands they must survive off the land once they plummet.
5. **Transition & Skip:** Screen shake escalates to a devastating crash, fading to black space transition, with an ESC-skip feature for veterans.

## Proposed Changes
1. Create a TutorialSpaceship scene that locks player movement via state machine locking or explicit disables, featuring deep cosmic/magical background visuals.
2. Enhance the existing dialogue system to support embedded signal emissions, injecting the "Stolen Magic" lore into the dialog tree.
3. Trigger the Wand Editor window explicitly, blocking dialogue continuation until the wand compiler validates a crafted defense spell.
4. Trigger the Inventory window explicitly for survival crafting.
5. Implement a skip listener (ui_cancel) to warp to the final crash sequence seamlessly.
