# Proposal: Resource Gathering and Ecology

Implement tool-based resource harvesting and dynamic regrowth.

## Proposed Changes
1. Harvesting: Damage-to-drop logic for trees/rocks. (COMPLETE: Unified via LootItem)
2. Ecosystem: Cooldown-based regrowth of harvested entities.
3. Collection: Interworking with Inventory system via EventBus. (COMPLETE)

## Acceptance Criteria
- [x] Breaking a tree node or interacting with a bush drops a physics-based loot item.
- [x] Collecting the loot item updates the inventory UI.
- [x] Harvested resources regrow after a defined cooldown period.
