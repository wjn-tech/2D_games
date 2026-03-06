# Design: Modernize Save System

## Architectural Reasoning
The goal is to provide a robust, commercial-grade save system that improves on the existing structure by adding **safety**, **transparency (visuals)**, and **state completeness**.

### System Components

#### 1. Binary Serialization (Compressed `var` storage)
- **Efficiency**: Standard `store_var` with compressed `FileAccess` is faster than complex JSON strings for large worlds with thousands of chunks or buildings.
- **Safety**: Atomic writing - save to `data.tmp`, then delete `data.dat`, then rename `data.tmp` to `data.dat`. This ensures that even a crash mid-save won't destroy the existing data.

#### 2. Visual Previews (Screenshotting)
- **Implementation**: Capturing the `ViewportTexture` and converting it to an `Image` for JPEG saving.
- **Optimization**: The screen capture is performed *before* the synchronous file-writing phase to ensure the UI is not visible in the shot if captured at the point of click.

#### 3. State Registration Pattern
- **Decoupling**: Instead of `SaveManager` knowing how to pack an `Inventory`, the `InventoryManager` registers itself to a `persist` group. The `SaveManager` calls `get_save_data()` on every group member.
- **Benefits**: Allows for easy addition of new systems (like `Weather`, `Quests`, or `Ecology`) without modifying the primary `SaveManager.gd`.

### Technical Implementation details
- **File Format**: `.dat` (Binary) and `.jpg` (Thumbnail) folders per slot.
- **Lineage Metadata**: `metadata.json` will be kept as JSON for quick indexing without loading large binary blobs for the save-select menu.

### Trade-off Discussion
- **Asynchronous IO**: While fully async file writing is possible in C++, in GDScript, standard `FileAccess` is synchronous. To mitigate this, we partition data by chunks (which is already happening for the InfiniteWorld system) to avoid one massive file freeze.
- **Binary vs Text**: Binary is preferred for large-scale maps (Pickups, Mask grids, Chunks) which may contain tens of thousands of data points.
- **Backup Strategy**: We keep the previous successful save as `data.bak` whenever a new save is performed.
