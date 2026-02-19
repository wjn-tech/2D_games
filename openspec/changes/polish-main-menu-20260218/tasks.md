# Tasks

1. Scaffold openspec change folder and docs (proposal, tasks, design). (this file)
2. VisualHierarchy: adjust layout spacing, promote primary CTA, reduce redundant greeting, add subtle vignette. (spec + small scene patch)
3. Background Visuals: tune `MenuDynamicBackground` params; ensure stars, rings, sun/halo 和 云层 在 4 个时段表现良好；导出并 record recommended values and shader presets. (spec + shader param presets)
4. InteractionFeedback: implement button hover/pressed states, glow layers, subtle scale on press, accessible contrast. (spec + theme tweak)
5. Theming & Palette: convert `assets/ui/palette.json` → `assets/ui/palette.tres` (Godot Theme resource), replace remaining purple with blue tokens, wire Theme to MainMenu.
	- Deliver `palette.tres` suggested tokens with hex values below.
6. Typography: add `Poppins` as game title font and button font fallbacks; update sizes/weights for hierarchy. (spec + assets list)
7. Shader Presets: commit `presets/dawn.tres|day.tres|dusk.tres|night.tres` small resources or JSON used by `MenuDynamicBackground` to apply and preview settings.
8. QA / Validation: provide editor preview steps, required screenshots for each time-of-day, accessibility contrast checks, and hover/pressed animation recordings.
9. Cleanup: remove debug fallbacks (`HardFallbackSky`) and debug prints after verification.

Order (recommended): 2 → 5 → 3 → 7 → 4 → 6 → 8 → 9.

Suggested palette tokens (for `palette.tres`):
- bg_deep: #041528
- bg_mid: #0b2b45
- grad_top: #2b6fa8
- grad_bottom: #092433
- accent: #6fc3ff
- accent_dark: #2a84c7
- glow: #86c7ff
- ui_panel: #071a2b
- subtle: #7fbbe8

