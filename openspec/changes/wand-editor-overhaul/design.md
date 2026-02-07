# Design: Wand Editor Overhaul

## 1. GraphEdit Modernization
The current implementation artificially locks the `GraphEdit` to a fixed grid and disables scrolling, causing coordinate mapping issues (stacking nodes).

**Change:**
- Enable `minimap`, `scroll_offset`, `zoom`.
- Remove manual `board_offset` calculation. Let `GraphNode.position_offset` be the source of truth.
- Coordinates saved in `WandData` will be standard GraphEdit vector space.

## 2. Visuals & Projectiles
The user requests "Pure Color Rectangles".
- **Implementation:** Replace the `Icon` sprite in `ProjectileStandard` with a `Polygon2D` or `ColorRect` (or a simple white texture modulated by color).
- **Elements:**
    - Fire: Red/Orange.
    - Ice: Cyan/Blue.
    - Default: White/Yellow.
- **Multiple Projectiles:** Ensure `SpellProcessor` allows simultaneous spawning. If multiple action nodes exist, they execute in sequence but effectively same frame. We may add slight spread or ensure the user sees them.

## 3. Simulation Sandbox
A new `SubViewport` will be added to the Editor UI (replacing or adjacent to the "Visual" tab, or in a persistent side panel).
- **Execution:** When "Simulate" is clicked, we:
    1. Compile the current graph.
    2. Spawn a specialized `SimulationArena` scene in the viewport.
    3. Spawn a dummy source and cast the spell.

## 4. Connection Improvements
To fix "clicking node instead of wire":
- Ensure `GraphNode` has distinct hit areas.
- We might increase `port` radius or visuals.
- "Hover Scale" effect: Connect `mouse_entered` signal on `GraphNode` to a tween that scales it up slightly (e.g., 1.05x).

## 5. Missing Components
Update `wand_editor.gd` palette to include:
- `Trigger (Timer)`: Activates after N seconds | On Dissipate.
- `Trigger (Collision)`: Activates on hit.
- `Trigger (Periodic)`: Activates every N seconds.
