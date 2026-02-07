# Proposal: Inventory & Hotbar System

**Change ID**: `implement-inventory-system`

## Summary
Implement a complete Inventory and Hotbar system allowing players to manage items, equip weapons/tools via numeric keys (1-9), and select specific Wands for programming within the Wand Editor.

## Problem
- **No Item Management**: Currently, the player has no way to store, organize, or select different items (swords, wands, potions).
- **Single Wand Restriction**: The Wand Editor acts on a global or hardcoded context, preventing the player from carrying multiple wands with different programs.
- **Lack of Interface**: There is no visual representation of carried items or inputs to switch between them.

## Solution

### 1. Inventory Core
- **Item Resource**: Base class for all collectables (`ItemData`), with subclasses for `WandItem`, `WeaponItem`.
- **Containers**: Discrete inventory containers (`Backpack`, `Hotbar`) consisting of slots.
- **Drag & Drop**: Standard grid-based manipulation.

### 2. Hotbar & Equipment
- **Hotbar Inventory**: A 9-slot high-priority container always visible on screen.
- **Selection Logic**: Inputs `1`-`9` toggle the "Active Slot".
- **Equipping**: The item in the active slot is instantiated/attached to the Player hand.

### 3. Wand Editor Integration
- **Context Awareness**: The Wand Editor UI will now request an item reference.
- **Selector UI**: If multiple programmable items exist, opening the editor allows picking which one to modify from the inventory content.

## Risks
- **Wand Data Serialization**: Ensuring complex `WandData` (nodes/connections) saves/loads correctly when moved between slots.
- **Input Conflicts**: Key `1`-`9` might conflict with debug or other future systems if not unified.
