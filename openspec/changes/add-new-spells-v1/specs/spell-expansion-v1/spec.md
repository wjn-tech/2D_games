# Spec: Spell Expansion V1 (New Abilities)

## MODIFIED Requirements

### Requirement: Spell ID for Lifesteal Projectile
#### Scenario: Define `vampire_bolt` (吸血)
- `projectile_id`: `vampire_bolt`
- `mana_cost`: 50
- `damage`: 5.0
- `speed`: 600.0
- **Effect**: On killing an enemy (not props), `caster.max_hp += 1` and `caster.current_hp += 1`.
- **Constraint**: Max HP Cap = 500.
- **Key**: `SPELL_VAMPIRE_BOLT` (zh: "吸血投射物")

### Requirement: Static Healing Area Projectile
#### Scenario: Define `healing_circle` (治疗环)
- `projectile_id`: `healing_circle`
- `type`: `action_projectile` (but with `speed = 0` forced by script)
- `mana_cost`: 100
- `lifetime`: 1.5s
- **Effect**: Heals the player inside the circle by 5% of Max HP every 0.5s.
- **Visual**: Emerald green ring.
- **Key**: `SPELL_HEALING_CIRCLE` (zh: "治疗环")

### Requirement: Trajectory Multiplier for Orbit
#### Scenario: Define `modifier_orbit` (真实环绕)
- `type`: `modifier_orbit`
- `mana_cost`: 30
- **Effect**: Projectile orbits the **Caster** at a fixed radius (initially 80px).
- **Movement**: The orbit center follows the `caster.global_position`.
- **Visual**: Leaves a trail.
- **Key**: `SPELL_MODIFIER_ORBIT` (zh: "真实环绕")

## ADDED Requirements

### Requirement: Projectile Killer Callback
#### Scenario: Identify the killer in the Enemy script
- When an enemy dies, check `damage_source`.
- If `damage_source.get("is_vampiric") == true`, increase caster's HP.
- Emit a "Blood Orb" particle traveling from enemy corpse to player.

### Requirement: Non-Stacking Healing Logic
#### Scenario: Multiple Circles
- If Player enters multiple healing circles, the healing effect does not stack (1 tick per interval max).
- Use `has_meta("healing_cooldown")` or similar to throttle.

### Requirement: Debug Unlock (F10)
#### Scenario: Unlock All Spells
- Pressing F10 must add `vampire_bolt`, `healing_circle`, and `modifier_orbit` to the unlocked list in `GameState`.
