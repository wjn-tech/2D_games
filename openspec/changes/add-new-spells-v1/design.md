# Design: New Spells V1 Architectural Reasoning

## Overview
This design covers the addition of three specialized magic components: a life-stealing projectile, a static healing area, and an orbital trajectory modifier.

## Architectural Components

### 1. Lifesteal Projectile (Vampirism Bolt)
- **Logic**: 
    - The `ProjectileBase` carries a `vampiric` flag.
    - Enemy `die()` function checks the damage source. If `source.is_vampiric`, trigger the effect.
    - **Effect**: Increases `Player.max_hp` by 1. Also increases `current_hp` by 1 to maintain ratio.
    - **Constraint**: Only triggers on **Enemies** (layer check), not props/crates.
    - **Cap**: Hard cap at 500 Max HP to prevent UI overflow/bugs.
- **Visuals**: 
    - Bullet: Deep red (#8B0000).
    - Feedback: A visual "Blood Orb" particle trails from the dead enemy back to the player.

### 2. Healing Circle (Static Area)
- **Logic**:
    - A stationary projectile (`speed=0`) that spawns at the cursor/muzzle.
    - Contains an `Area2D` that detects `Player`.
    - **Tick**: Every 0.5s, heals 5% Max HP.
    - **Duration**: 1.5s total (approx 3 ticks).
    - **Stacking**: Non-stacking. The player will have a `is_being_healed` flag or the healing buff will have a unique ID that doesn't stack intensities.
- **Visuals**:
    - Color: Emerald Green (#50C878).
    - Shape: A glowing runic ring on the ground that pulses.

### 3. Orbit Modifier (Orbit)
- **Logic**:
    - **Behavior**: Projectiles do not fly away. They lock to a fixed radius around the **Caster**.
    - **Movement**: `position = caster.global_position + Vector2(radius, 0).rotated(angle + time * speed)`.
    - **Follow**: Strictly follows player movement.
- **Visuals**:
    - Strong trail renderer to visualize the orbital path.

## System Integration
- **Wand Editor**: Update `wand_editor.gd` `_setup_libraries` to include these new items.
- **Debug**: Update `GameManager` or `DebugConsole` (F10) to ensure these new IDs are added to the unlocked list (`GameState.unlocked_spells`).
