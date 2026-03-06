# Spec: UI Interaction Sound Effects

## Overview
Implement global SFX feedback for all User Interface elements.

## ADDED Requirements

### 1. Global UI Feedback System
The UI must provide audio feedback for all standard interactions (buttons, inventory, windows).
- **Requirement**: Button `hover` must trigger a subtle "Hover" SFX.
- **Requirement**: Button `pressed` must trigger a distinct "Click" SFX.
- **Requirement**: Inventory item actions must provide unique feedback sounds.

#### Scenario: Main Menu Navigation
- **Given** the `MainMenu` is currently open.
- **When** the cursor enters a button's area.
- **Then** `AudioManager` must play a "UIHover" sound.
- **And** when the button is clicked, `AudioManager` must play a "UIClick" sound.

#### Scenario: Window Lifecycle
- **Given** any window (e.g., `InventoryWindow`, `PauseMenu`).
- **When** the window is opened.
- **Then** `AudioManager` must play a "WindowOpen" SFX.
- **And** when the window is closed, `AudioManager` must play a "WindowClose" SFX.

### 2. Inventory Item Audio
Specific feedback for item manipulation.
- **Requirement**: Item drag-and-drop must have "Pickup" and "PutDown" sounds.
- **Requirement**: Item equipping must trigger a "MetalEquip" or "GearEquip" SFX.
- **Requirement**: Crafting completion must trigger a "SuccessCraft" jingle or SFX.

#### Scenario: Equipping Gear
- **Given** the `InventoryWindow` is open.
- **When** an item is dragged from a slot and dropped into an equipment slot.
- **Then** `AudioManager` must play an "ItemEquip" sound.
- **And** the sound should be appropriate for the item category (e.g. clang for sword, rustle for cloth).
