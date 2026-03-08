# Tasks: Add New Spells V1

## Milestone 1: Core Localization & Foundation
- [x] Add new spell keys to `translations.csv` (SPELL_VAMPIRE_BOLT, SPELL_HEALING_CIRCLE, SPELL_MODIFIER_ORBIT).
- [x] Add new logic items to `wand_editor.gd` library list (deep red, emerald green, and trail colors).
- [x] Add new variables to `ProjectileBase.gd` (`is_vampiric: bool`, `is_orbiting_caster: bool`, `orbit_radius: float`).

## Milestone 2: Lifesteal Projectile (Vampire Bolt)
- [x] Implement `is_vampiric` check in `ProjectileBase.gd`.
- [x] Update **Enemy** death logic to detect `damage_source.is_vampiric` and call `caster.add_max_hp(1)` (implement proper cap at 500).
- [x] Create `add_max_hp` method in `Player` or `GameState`.
- [x] Add "Blood Orb" VFX (Simple text feedback implemented).

## Milestone 3: Healing Circle (Static Area)
- [x] Create `projectile_healing_circle.tscn` (Area2D + CollisionShape + Timer).
- [x] Implement `_on_body_entered` logic to detect Player.
- [x] Implement non-stacking healing tick (5% max HP / 0.5s) for 1.5s duration.
- [x] Add expanding emerald ring visual (Line2D or Texture).

## Milestone 4: Orbit Modifier (True Orbit)
- [x] In `ProjectileBase._physics_process`: if `is_orbiting_caster`, update position to `caster.position + vector.rotated(angle)`.
- [x] Ensure orbit radius is consistent (start at ~80px).
- [x] Add Trail Renderer to projectile scene or script.

## Milestone 5: System Testing & Debug
- [x] Update `GameManager` or Debug script to include new IDs in F10 unlock.
- [x] Launch game -> Open Editor -> Equip new spells -> Verify mechanics.
- [x] Verify F10 unlocks all new nodes.
