# Proposal: Add New Spells and Modifiers V1

## Problem Statement
The current magic system has a solid foundation but lacks utility and strategic depth. Players need more diverse spell types (lifesteal, static utility) and trajectory-altering modifiers to enable creative "Noita-like" wand builds.

## Proposed Changes
1. **Lifesteal Projectile (投射物法术 - 吸血)**:
   - A projectile that grants +1 Max HP to the caster permanently upon killing an enemy.
   - Requires integration with the enemy death signal and player attribute system.
2. **Healing Circle (静态投射物法术 - 治疗环)**:
   - A static projectile that creates a temporary zone on the spot.
   - Provides percentage-based healing per second for a very short duration.
3. **Orbit Modifier (修正法术 - 真实环绕)**:
   - A trajectory modifier that makes the projectile rotate around the caster instead of flying straight.
   - Requires updating the `ProjectileBase` movement logic to handle orbital calculations.

## Goals
- Increase wand customization depth.
- Introduce permanent progression through gameplay (Lifesteal).
- Add support for static/AOE spell patterns.

## Non-Goals
- Overhauling the entire attribute system.
- Adding complex VFX shaders (focusing on functionality and basic particles first).
- Balancing for PVP (PVE focus only).

## Verification Plan
1. **Manual Testing**:
   - Use the Wand Editor to equip "Lifesteal" and verify Max HP increases after killing a dummy/enemy.
   - Cast "Healing Circle" and verify player HP restores proportionally while standing in the zone.
   - Apply "Orbit" to a Spark Bolt and verify it circles the player.
2. **Automated Validation**:
   - Verify all new spell IDs are correctly mapped in `translations.csv`.
