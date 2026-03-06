# Tasks: Modernize Save System

## Task List

- [x] **Infrastructure: Binary Encoding & Safety**
	- [x] Update `SaveManager.gd` to use `FileAccess.store_buffer` or `store_var` with compression.
	- [x] Implement ".bak" (back-up) logic during save: write to temp file first, then rename to swap.
- [x] **Feature: Visual Previews (Thumbnails)**
	- [x] Add `_capture_screenshot(slot_id: int)` method using `get_viewport().get_texture()`.
	- [x] Save thumbnail as compact JPEG next to the data file.
- [x] **Feature: Expanded World Persistence**
	- [x] Implement saving for all nodes in the `pickups` group.
	- [x] Add Fog-of-War exploration tile-mask serialization.
	- [x] Save current weather and environment state (AlertLevel, etc.).
- [x] **Feature: Automatic & Lineage Saving**
	- [x] Implement a `SaveTimer` for background auto-saving (e.g., every 5-10 mins).
	- [x] Update metadata to include `lineage_id` and `generation_level` for better grouping in the UI.
- [x] **Feature: Register-based State Gathering**
	- [x] Refactor `SaveManager` to query all nodes in a `persist` group instead of hardcoding `_pack_player_data`.
	- [x] Standardize the `get_save_data()` and `load_save_data(data)` interface across components.
- [x] **Verification & Recovery**
	- [x] Test loading a corrupt save and falling back to the backup.
	- [x] Verify screenshot timing doesn't cause visible frame drops.
