# Tasks: NPC Mobility Refinement

- [ ] **Physics Layer Setup**
    - [ ] Assign Layer 3 to "Entities_NPC".
    - [ ] Update NPC prefab `CollisionLayer` to Layer 3.
    - [ ] Update NPC prefab `CollisionMask` to Layer 1 (Ground) but UNCHECK Layer 3.
- [ ] **Verification**
    - [ ] Create a "Tunnel" test scene in `test.tscn`.
    - [ ] Spawn two NPCs at opposite ends and verify they pass through each other.
