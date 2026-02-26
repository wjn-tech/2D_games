# Beautify Main Menu Tasks

## Assets & Resources
[ ] Find/Download Lucide-style SVG icons (Sword, Scroll, Settings/Gear, Sound/Music).
[ ] Create/Import particle textures (Runes, Sparkles, Magic Rings).
[ ] Define `ui_menu_theme.tres`: Core theme definition for glass panels and buttons.

## Visual Components (FX)
[ ] Create `GradientLabel.gd`: Component for gradient text effects.
[ ] Create `GlassPanel.tscn`: A container with blur shader background.
[ ] Create `MagicParticleSystem.tscn`: A scene emitting floaty particles/runes.
[ ] Create `MenuEffects.tscn`: Combine particles, runes, and magic circle.

## Main Menu Refactor
[ ] Create new `StyledMainMenu.tscn`: Based on existing `MainMenu.tscn` but using new components.
[ ] Integrate `MenuEffects` into `StyledMainMenu`.
[ ] Apply `GradientLabel` to title "ARCANE CHRONICLES".
[ ] Replace standard `Button` nodes with styled `IconButtons` (using SVGs).
[ ] Implement hover animations (scale, glow) via `create_tween()`.

## Sub-Menu Standardization
[ ] Create reusable `MenuWindowBase.tscn`: A template for sub-windows (Settings, Load) with the glass theme.
[ ] Migrate `SettingsMenu` to use `MenuWindowBase` & `GlassTheme`.
[ ] Migrate `LoadGameMenu` to use `MenuWindowBase` & `GlassTheme`.

## Validation
[ ] Verify performance on low-end settings (toggle blur).
[ ] Check UI responsiveness and layout on different resolutions.
