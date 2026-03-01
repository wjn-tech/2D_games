# Proposal: Complete Legacy VFX Reconstruction

[Metadata]
- Author: Agent
- Status: Draft
- Created: 2026-02-28
- Type: Refactor
- Scope: ProjectileBase, MagicProjectileVisualizer

## Summary
The current implementation of `MagicProjectileVisualizer` is an "add-on" that layers new Noita-style particles *on top* of the old generic visual system, failing to fully capture the bespoke identity of the original spells. This proposal mandates a total visual reconstruction: we will extract the exact *artistic intent* (colors, pulse rhythms, shapes, unique logic) from the legacy `projectile_base.gd` code and re-implement it using the new `MagicProjectileVisualizer` architecture. The legacy visual functions will then be formally deprecated and removed, leaving a clean, unified visual system.

## Problem Statement
The user correctly identifies that the current solution "feels like a template applied over the old code".
1.  **Redundant Systems**: `projectile_base.gd` still contains `_add_spark_trail`, `_add_heavy_trail`, `_add_ring_pulsate`, etc.
2.  **Partial Identity**: The new visualizer uses generic `plasma` or `spark` archetypes, missing specific tweaks (e.g., `magic_bolt`'s specific heavy trail color, `bouncing_burst`'s ring pulse logic).
3.  **Visual Conflict**: The old `body_line` (Line2D) often fights with the new sprite visuals.

## Proposed Solution
We will systematically migrate each spell's *unique* visual logic from `ProjectileBase` to `MagicProjectileVisualizer`:

1.  **Magic Bolt**:
    -   *Old*: `core_color = Color(20, 1, 50)`, `_add_heavy_trail`.
    -   *New*: Dense plasma stream uses EXACT color `Color(20, 1, 50)`. Pulse animation matches the "heavy" feel.
    -   *Action*: Remove `_add_heavy_trail` from Base.

2.  **Spark Bolt**:
    -   *Old*: `core_color = Color(1, 5, 50)`, `_add_spark_trail`.
    -   *New*: High-velocity bouncing sparks (Physics Material). Main sprite is a jagged 1px line that rotates.
    -   *Action*: Remove `_add_spark_trail` from Base.

3.  **Bouncing Burst**:
    -   *Old*: `Color(40, 40, 2)`, `_add_ring_pulsate`.
    -   *New*: Slime/Radioactive material (Green/Yellow HDR). Sprite squashes/stretches on bounce. Trail drips.
    -   *Action*: Remove `_add_ring_pulsate` from Base.

4.  **Chainsaw**:
    -   *Old*: `Color(100, 100, 100)`, `_add_explosion_on_spawn`.
    -   *New*: Spinning sawblade sprite (12px). Shower of white-hot metallic sparks (Bounce enabled). Muzzle flash is an *actual* explosion sprite.
    -   *Action*: Remove `_add_explosion_on_spawn` from Base.

## Risks & Mitigation
-   **Risk**: Losing the "feel" of specific spells if migration is generic.
-   **Mitigation**: The new visualizer must have bespoke `_process` logic for each spell to mimic the old behavioral quirks (e.g. `bouncing_burst`'s ring expansion).

## Staffing
-   Agent
