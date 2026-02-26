# Proposal: Magic Backpack Advanced Visuals

## Why
The visual polish of the inventory UI is disconnected from the high-fantasy / magitech theme. Players expect a deeply immersive, responsive, and unified visual experience that feels both magical and precise (combining arcane energy with HUD-like precision).

## What Changes
- **Opening/Closing:** 
  - **Open:** "Convergence" effect where particles fly from **screen edges** to center, forming the window.
  - **Close:** "Shatter" effect where the window breaks into particles and dissipates.
- **Visuals:**
  - **Background:** Hypnotic, slow-flowing shader (Deep Sea/Space vibe).
  - **Border/Grid:** visible but thick/low opacity grid lines that brighten on hover. Decorative "Magic Circuit" lines connecting slots/edges.
  - **Theme:** "Cyan/Blue + Silver" palette (Spirit/Tech feel).
  - **Typography:** Slender, modern sans-serif fonts (HUD style).
- **Interaction:**
  - **Hover:** Slots glow + Item scales up (1.1x).
  - **Hover Grid:** Grid lines brighten.
  - **Tooltip:** Dynamic, follows mouse, seamless appearance.
  - **Click/Drag:** Slot indents (shadow) when item removed. No trail.
  - **Drop:** Snappy "magnetic" placement animation (scale bounce).
- **Feedback:**
  - **Rarity:** Rare items have persistent extra glow/border effects.
  - **Full Inventory:** Shaking icon/GUI, Red flash warning.
  - **Sort:** Items fly individually to new positions (solitaire style).

## Impact
- **Specs:** UI Framework, Inventory System.
- **Files:** InventoryWindow.tscn, inventory_ui.gd, ItemSlot.tscn, Theme resources, specific Shaders.
