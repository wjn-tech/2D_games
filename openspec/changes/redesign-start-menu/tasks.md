# Tasks: Start Menu Redesign

## Phase 1: Foundation & Background
- [x] Create `scenes/ui/menu/components/` directory structure for modular menu parts.
- [x] Implement `DynamicBackground.gd` and scene structure (`ParallaxBackground` with layers).
- [x] Create assets logic for "Day/Night" background states (using placeholders or existing assets).
- [x] Verify background changes color/brightness based on System Time.

## Phase 2: Smart UI & Logic
- [x] Refactor `MainMenu.tscn` to use the new `DynamicBackground` component.
- [x] Implement `SmartMenuOptions` generator to replace hardcoded buttons.
- [x] Connect `SmartMenuOptions` to `SaveSystem` to read metadata (Location/Time).
- [x] Add "Personalized Welcome" text logic (e.g., "Good Evening, Player").

## Phase 3: Audio & Polish
- [x] Create `MenuAudioManager.gd` with defined `Ambient` and `Melody` streams. (Integrated into DynamicBackground/MainMenu)
- [x] Implement Hover/Click SFX with pitch variation. (Already in MainMenu hover logic)
- [x] Add `MenuTransition.gd` for "Entrance" (Fade In + Slide) and "Exit" (Fade Out to Game) animations. (Implemented in MainMenu)
- [x] Add simple `GPUParticles2D` (e.g., Fireflies) to the menu scene.

## Dependencies
- Requires functioning `SaveSystem` to read metadata for "Continue" button.
- Requires `GameManager` state switching to be stable (already implemented).
