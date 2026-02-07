# Spec: Settings Menu Capabilities

## ADDED Requirements

### Tabbed Interaction
The Settings menu MUST be organized into distinct categories accessible via customized tab buttons.
*   **Categories**: General, Graphics, Audio, Input.
*   **Navigation**: Clicking a tab switches the visible content panel immediately.

### Graphics Configuration
The Graphics tab MUST allow configuring:
*   **Window Mode**: Fullscreen / Windowed / Borderless.
*   **Resolution**: Dropdown list of available resolutions (e.g., 1920x1080, 1280x720).
*   **VSync**: Toggle On/Off.
*   **Max FPS**: Slider (30 to 144) or "Unlimited".
*   **Visual Quality**:
    *   **Particles**: Slider controlling particle density.
    *   **Post-Processing**: Sliders for Brightness, Contrast, Gamma.

### Audio Configuration
The Audio tab MUST allow configuring volumes (0%-100%) for:
*   **Master Bus**
*   **Music Bus**
*   **SFX Bus**
*   **UI Bus**

### Input Persistence & Remapping
Keybindings MUST be remappable and persist across game restarts.
*   **Presentation**: A scrollable list of all actions (e.g., "Move Up", "Inventory", "Interact").
*   **Editing**: Clicking a key slot prompts "Press any key...".
*   **Conflict**: If a key is already bound, show a warning or swap them (design decision: Swap or Unbind old).
*   **Defaults**: A "Reset to Defaults" button restores the original `InputMap`.

### General Settings
*   **Language**: Selector for available locales.
*   **Game Options**:
    *   "Pause on Focus Lost" (Toggle).
    *   "Show Damage Numbers" (Toggle).
    *   "Screen Shake" (Slider).

### Visual Style
The UI MUST follow the "Noita-like" aesthetic:
*   **Palette**: Dark Background, Gold Borders (`#e0c060`).
*   **Feedback**: Hover effects on all interactive elements.

