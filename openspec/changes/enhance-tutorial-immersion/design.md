# Design: Tutorial Immersion Overhaul

## Overview
The goal is to increase emotional investment by framing the tutorial as a "desperate escape from a crashing ship" (as per the *Star Traveler* script) while teaching the core loop of *Wand Programming* (the game's unique selling point).

## Core Conflict Resolution
The script focuses on *Shield Crafting* to mitigate damage. However, the game is about *Wand Customization*. 
**Resolution**: We replace the shield crafting with **Wand Repair**. The player's survival depends on fixing a broken wand to defend against boarding enemies. This keeps the narrative stakes high but aligns with the core mechanic.

## Scene breakdown (Technical)

### 1. The Awakening (Scene 1)
- **State**: `Phase.WAKE_UP`
- **Visuals**: Black screen -> `AnimationPlayer` fade in -> Player sprite lying down (or specialized sprite) -> Stand up.
- **Input**: WASD to move.
- **Camera**: Locked to "Cryo Pod" initially, then pans to "Window" on interaction.

### 2. The First Magic (Scene 2)
- **State**: `Phase.COLLECT_STARDUST`
- **Mechanic**: `Area2D` triggers for "Stardust" nodes. Press 'E' to collect.
- **Feedback**: `Particles2D` flow to player.
- **Outcome**: Unlocks `Reveal` spell (simulated or real).

### 3. Wand Repair (Scene 3 - The Core Loop)
- **State**: `Phase.EDITOR` (Reusing existing logic)
- **Narrative**: "The defense grid is failing. We need firepower. Here's a stripped wand frame."
- **Action**: Open Editor (K/Tab). Drag `Generator` (Energy) and `Projectile` (Weapon).
- **Validation**: Existing `_check_step` logic ensures correct circuit completion.

### 4. Emergency Defense (Scene 4)
- **State**: `Phase.COMBAT`
- **Action**: Enemies spawn (simple `CharacterBody2D` AI). Player must shoot them using the wand they just built.
- **Climax**: "Overcharge" event - Player holds fire button to unleash a massive scripted beam (simulated by `Line2D` + `Area2D`) to clear the final blockade.

### 5. The Crash (Scene 5)
- **State**: `Phase.CRASH`
- **Visuals**: `Camera2D` shake intensity max. `ColorRect` flash white.
- **Audio**: Fade out all game audio, play "Heartbeat" sfx.
- **Transition**: To `MainGame` scene or `TitleScreen`.

## Architecture
- **TutorialSequenceManager**: Will orchestrate these phases.
- **DialogueManager**: Will handle the branching conversations.
- **OverlayManager**: Will point to objectives (Window, Stardust, Wand Editor).
