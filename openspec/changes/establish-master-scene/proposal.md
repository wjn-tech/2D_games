# Proposal: Establish Master Scene for Collaborative Assembly

## 1. Problem Statement
The project currently uses `test.tscn` as its main entry point, which is a flat testing scene. While individual systems (14 core systems, UI, World Gen) have been implemented as scripts or isolated scenes, there is no unified "Master Scene" that orchestrates them into a complete game. To build the game collaboratively, we need a stable, structured hierarchy where we can "plug in" resources and systems one by one.

## 2. Proposed Solution
We will establish `Main.tscn` as the definitive Master Scene. This scene will serve as the root container for all game components, organized into logical layers. We will then set this scene as the project's startup scene.

## 3. Scope
- **In-Scope**:
    - Refactoring `Main.tscn` to have a standardized hierarchy: `Systems`, `World`, `Entities`, `UI`.
    - Updating `project.godot` to set `Main.tscn` as the main scene.
    - Ensuring `GameManager` and `UIManager` correctly initialize the game flow (Menu -> Play) within this scene.
- **Out-of-Scope**:
    - Implementing the full logic for all 14 systems (this will be done in subsequent small steps).
    - Finalizing art or level design.

## 4. Impact
- **Architecture**: Moves from a "flat test scene" to a "structured master scene" pattern.
- **Workflow**: Allows us to add systems and entities to specific containers in `Main.tscn` without breaking other parts of the game.
