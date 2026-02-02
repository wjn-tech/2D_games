# Tasks: Implement Quest System and Fog of War

- [x] Create `QuestResource.gd` and `QuestManager.gd`. <!-- id: 1 -->
- [x] Register `QuestManager` as an autoload in `project.godot`. <!-- id: 2 -->
- [x] Update `BaseNPC.gd` to support quest giving. <!-- id: 3 -->
- [x] Add quest generation logic to `QuestManager.gd` and assign to NPCs in `WorldGenerator.gd`.
- [x] Implement role-based NPC templates and unique animations.
- [x] Refine NPC spawning logic for settlements (Max 7 NPCs, one of each role guaranteed).
- [x] Optimize NPC density and prevent accumulation on world regeneration.
- [x] Enable free passage between all character models (Player and NPCs).
- [x] Integrate `FogOfWar.gd` into `Main.tscn` and ensure it covers the map. <!-- id: 4 -->
- [x] Implement POI discovery logic in `WorldGenerator.gd` or a new `DiscoveryManager.gd`. <!-- id: 5 -->
- [x] Add quest notifications to `HUD.gd`. <!-- id: 8 -->
- [x] Integrate `QuestManager` with `EventBus` for automatic progress tracking. <!-- id: 9 -->
- [x] Verify quest completion and reward distribution. <!-- id: 6 -->
- [x] Verify Fog of War correctly reveals tiles around the player. <!-- id: 7 -->

## Future: Complete Quest System
- [ ] Design and implement a Quest Journal UI. <!-- id: 10 -->
- [ ] Add quest markers to the world and map. <!-- id: 11 -->
- [ ] Implement quest persistence (save/load). <!-- id: 12 -->
- [ ] Support for branching quest lines and multiple objectives. <!-- id: 13 -->
- [ ] Fix HUD quest display bug (currently accepted quests not showing). <!-- id: 14 -->
