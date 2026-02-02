# Proposal: Establish Unified Architecture

Formalize the overall project structure and system linkages to ensure a cohesive development path, especially with the integration of Noita-inspired mechanics.

## Why
As the project expands with complex systems like multi-layered parallax backgrounds, procedural villages, and upcoming elemental chemistry, a clear "Unified Architecture" is needed to prevent technical debt and ensure systems (World, NPC, Combat, UI) interact predictably.

## Proposed Changes
1.  **System Hierarchy**:
    - Define a formal hierarchy where `GameManager` acts as the root orchestrator.
    - Standardize the roles of `LayerManager` and `ChemistryManager` as world-context providers.
2.  **Standardized Inter-system Communication**:
    - Use `EventBus` for global signals (e.g., `building_shattered`, `spell_cast`).
    - Use `LayerManager` as the source of truth for physical space isolation.
3.  **Data-Driven Integration**:
    - Centralize item and building configurations in `data/` to be used by both `WorldGenerator` and `TradingSystem`.

## Impact
- **Maintenance**: Easier debugging of cross-system issues (e.g., NPCs falling through layers).
- **Extensibility**: Faster integration of Noita mechanics into the existing building/NPC framework.
- **Performance**: Optimized simulation window logic across all singleton managers.

## Acceptance Criteria
- [ ] A `design.md` document exists detailing the linkage between all major Autoloads.
- [ ] Cross-system triggers (e.g., Mining -> Drop -> Inventory) are documented and standardized in `EventBus`.
- [ ] All new systems (Chemistry, Shattering) follow the hierarchical layer rules defined by `LayerManager`.
