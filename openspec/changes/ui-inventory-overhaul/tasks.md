# Implementation Tasks

## 1. Visual Foundation (Precision Magitech)
- [ ] **Background Shader**: Create ui/shaders/inventory/starfield_flow.gdshader (Cyan/Deep Blue, slow hypnotic flow).
  - [ ] Apply to GlassPanel background.
- [ ] **Border & Grid**:
  - [ ] Implement "Magic Circuit" decorative lines (images or Line2D overlay).
  - [ ] Update Grid slots style: Thin cyan/silver borders, default modulate.a = 0.3.
  - [ ] Update inventory_theme.tres: Change fonts to Modern Sans-Serif (system default or bundled sans font).

## 2. Dynamic Interactions
- [ ] **Item Slot Script (ItemSlot.gd)**:
  - [ ] Hover: Item scale 1.1, modulate brighter. Grid Border modulate.a -> 0.8.
  - [ ] Rare Items: Add check for item.rarity >= RARE, instantiate GlowSprite or shader effect.
  - [ ] Click/Pickup: Inset shadow on background.
- [ ] **Tooltip**: Style to match Cyan/Silver Magitech theme (sharp corners, thin border).

## 3. Animation Overhaul (inventory_ui.gd)
- [ ] **Open Animation (Convergence)**:
  - [ ] Create ParticlesConvergence node (emit from screen edges towards center).
  - [ ] Script: Play particles -> Delay 0.2s -> Scale Window 0 to 1 (Elastic).
- [ ] **Close Animation (Shatter)**:
  - [ ] Create ParticleShatter node (one-shot explosive burst at window center).
  - [ ] Script: Hide Window -> Play Shatter -> Queue Free/Hide parent.
- [ ] **Drop Feedback**:
  - [ ] Tween scale (1.2 -> 1.0) on drop.

## 4. Special Features
- [ ] **Full Inventory**: Shake window + Flash Red overlay on fail.
- [ ] **Sorting**: Implement visual tween for sorting slots (move icon global_position).

## 5. Polish
- [ ] **Consistency**: Ensure Gold/Purple accents are replaced or harmonize with Cyan/Silver.
