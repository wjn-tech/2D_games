## Tasks for `add-mainmenu-visuals-2026-02-17`

### 1) Proposal & Spec (this change)
- [x] Create `proposal.md` describing goals, impact, risks and roll-out plan
- [x] Scaffold `tasks.md`, `design.md`, and spec delta under `specs/visuals/spec.md`

### 2) Implementation — Phase 1 (Compatibility & parameterization)
- [ ] Fix Godot 4 compatibility issues in `scenes/ui/main_menu.gd` (replace deprecated properties, ensure `clip_contents` for buttons)
- [ ] Expose shader parameters as `@export` on `DynamicBackground` or a dedicated `MenuBackground` node (star_density, ring_count, nebula_strength, use_noise)
- [ ] Add runtime config presets (low/medium/high) and `ProjectSettings` keys to control defaults
- [ ] Unit smoke test: load `MainMenu.tscn` and ensure no console errors within 5s

### 3) Implementation — Phase 2 (Visual polish)
- [ ] Tweak `ui/shaders/menu_bg.shader` parameters to match reference (soft ring edges, layered nebula, star parallax)
- [ ] Implement button inner-glow shader and multi-layer StyleBox setup; add hover/press tweens with defined curves and durations
- [ ] Apply `text_gradient.shader` to title, welcome label and button text; ensure `time` parameter animates
- [ ] Replace/confirm SVG icons and ensure each icon is a `TextureRect` child with `clip_contents` behavior
- [ ] Create short visual QA checklist and capture screenshots (3 target resolutions)

### 4) Implementation — Phase 3 (Performance & fallback)
- [ ] Add runtime toggles to disable noise/extra stars and instrument performance counters (simple frame time readout) in dev builds
- [ ] Provide fallback (static gradient / lower-density starfield) when shader compile fails

### 5) Validation & Review
- [ ] Run `openspec validate add-mainmenu-visuals-2026-02-17 --strict` and resolve any parsing/format issues
- [ ] Produce a review PR with screenshots and a short recording of hover/press interactions
- [ ] Address reviewer feedback and, on approval, move to `openspec/changes/archive/YYYY-MM-DD-add-mainmenu-visuals-2026-02-17/`

### Notes
- Tasks are small, verifiable, and ordered to reduce risk (compatibility first, visual polish second, performance last).
