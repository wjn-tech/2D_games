# Tasks: Refine NPC Interaction

- [ ] **Core Integration**
    - [ ] Update `BaseNPC.interact()` to fetch role-specific dialogue and options.
    - [ ] Link `DialogueManager` to `BaseNPC` triggers.
- [ ] **Role Features**
    - [ ] **Merchant**: Link "Trade" dialogue option to `TradeManager`.
    - [ ] **Guard**: Implement "Hire" logic (deduct money -> enable Follower behavior).
    - [ ] **Wizard**: Implement "Spell Unlock" menu within dialogue.
- [ ] **Social & Relationship**
    - [ ] Implement `give_gift(item)` logic in `BaseNPC`.
    - [ ] Add relationship-based pricing in `TradeManager`.
- [ ] **Behavioral Updates**
    - [ ] Create `FollowerState` in `LimboAI` or simple steering logic for followers.
    - [ ] Implement "Recruit" vs "Permanent resident" flag for NPCs.
- [ ] **UI Refinement**
    - [ ] Add specific icons to dialogue options (e.g., Coin icon for Trade).
    - [ ] Implement a simple "Notification" pop-up for relationship changes.
