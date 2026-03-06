# Proposal: Modernize Save System

## Problem Context
The current save system is functional but lacks professional features found in modern survival RPGs. It doesn't support automatic grouping by lineage/legacy, lacks visual previews (thumbnails), and doesn't explicitly handle "extra" world state like dropped pickups or fog-of-war. The encoding is inconsistent, and there is no safety net for corrupted save attempts.

## Proposed Solution
Introduce a robust, binary-driven save infrastructure that treats saves as "Lineage Campaigns" rather than just isolated slots.

### Key Features:
- **Binary Encoding**: Transition to `.res` or custom binary formats for core data to improve performance and prevent trivial tampering.
- **Visual Previews**: Capture a viewport screenshot during save to display in the UI.
- **Enhanced State Persistence**: Save dropped items (Pickups) and Fog-of-War exploration progress.
- **Lineage-Based Organization**: Group saves by family line/generation to align with the core game mechanic.
- **Auto-Save & Safety**: Background save timer and temporary ".bak" writing to prevent data loss during crashes.

## Performance & Security
- **Asynchronous Capture**: Screenshot capture will be deferred to the next frame to avoid micro-stutter.
- **Checksumming**: Basic checksum to verify save integrity upon loading.

## Architecture & Design
- **SaveManager Refactor**: Move from hardcoded data packing to a registration-based system where nodes in the `persist` group provide their own data.
- **Thumbnail Cache**: Store thumbnails as `.jpg` or `.png` alongside the binary data.
