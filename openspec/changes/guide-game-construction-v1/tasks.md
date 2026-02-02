# Tasks: Game Assembly Roadmap

## Phase 1: Foundation (The "Skeleton")
- [x] **Task 1.1**: Configure Project Settings (Input Map, Autoloads).
- [ ] **Task 1.2**: Set up the `Main` scene and `GameManager`.
- [ ] **Task 1.3**: Initialize the `UIManager` and `HUD`.

## Phase 2: The World (The "Skin")
- [ ] **Task 2.1**: Create the `World` scene with `TileMapLayer` (Layer 0, 1, 2).
- [ ] **Task 2.2**: Configure `LayerManager` to handle physics switching.
- [ ] **Task 2.3**: Implement the `WorldGenerator` to spawn terrain and resources.

## Phase 3: Entities (The "Muscle")
- [ ] **Task 3.1**: Assemble the `Player` scene (Sprite, Collision, Camera).
- [ ] **Task 3.2**: Assemble the `BaseNPC` scene and AI states.
- [ ] **Task 3.3**: Connect `LifespanManager` to entities for aging/death.

## Phase 4: Systems (The "Organs")
- [ ] **Task 4.1**: Set up the `PowerGridManager` and industrial machines.
- [ ] **Task 4.2**: Set up the `SettlementManager` and recruitment UI.
- [ ] **Task 4.3**: Set up the `WeatherManager` and environmental effects.

## Phase 5: Final Polish (The "Soul")
- [ ] **Task 5.1**: Implement the `Reincarnation` flow.
- [ ] **Task 5.2**: Add sound effects and particle placeholders.
- [ ] **Task 5.3**: Final bug hunt and performance optimization.
