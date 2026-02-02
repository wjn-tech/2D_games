# Proposal: Fix TradeWindow open_window arguments in BaseNPC

## 1. Problem Statement
In `src/systems/npc/base_npc.gd`, the `_open_trade()` function calls `UIManager.open_window("TradeWindow")` with only one argument, but `UIManager` requires at least two (name and scene path). This causes a runtime error.

## 2. Proposed Solution
Update the `_open_trade()` function to provide the correct scene path: `"res://scenes/ui/TradeWindow.tscn"`.

## 3. Scope
- `src/systems/npc/base_npc.gd`: Update the `open_window` call.

## 4. Dependencies
- `UIManager` autoload.
- `res://scenes/ui/TradeWindow.tscn`.
