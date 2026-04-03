# Hostile Drop Localization Guide

## Purpose

This guide defines how hostile-drop item IDs map to localization keys and bilingual names.

Source of truth:

- `res://data/npcs/hostile_drop_localization.json`
- `res://assets/translations.csv`

## Key Contract

- Signature drop key format: `ITEM_HOSTILE_<MONSTER>_<TOKEN>`
- Common material key format: `ITEM_HOSTILE_MAT_<TOKEN>`

Examples:

- `slime_essence` -> `ITEM_HOSTILE_SLIME_ESSENCE`
- `arcane_dust` -> `ITEM_HOSTILE_MAT_ARCANE_DUST`

## Naming Style Guide

Tone and readability rules:

1. Chinese name should be concise, combat-fantasy flavored, and naturally readable.
2. English name should match Chinese meaning and avoid literal machine-translation artifacts.
3. Avoid duplicate Chinese names across hostile drops.
4. Avoid ambiguous terms that collide with terrain/resource block naming.
5. Keep names generally within 2-6 Chinese characters where possible.

Forbidden patterns:

- Generic placeholders like "材料A", "掉落物1".
- Mixed language in one display name unless required by lore.
- Reusing block-resource names as hostile material names.

## Integration Rules

1. Every hostile drop `item_id` must exist in `hostile_drop_localization.json`.
2. Every `translation_key` in the map must have a row in `translations.csv`.
3. Drop table review fails when any referenced `item_id` has no localization mapping.
4. Mapping updates and translation row updates must be submitted together.

## Runtime Fallback Strategy

Until all UI item paths are fully `tr()`-driven:

1. Preferred: render by translation key using `tr(key)`.
2. Fallback: if translation key is missing or unresolved, use readable `display_name` from item resource.
3. Never show raw `item_id` to player-facing UI unless in debug mode.

## Validation Checklist

Run before review/merge:

```powershell
powershell -ExecutionPolicy Bypass -File tools/validate_hostile_drop_localization.ps1
```

Required checks:

1. Key format validity for signature/common entries.
2. 100% coverage of map rows in `translations.csv`.
3. No duplicate translation keys.
4. No duplicate Chinese names in hostile-drop set.
5. Chinese and English values match the map exactly.
