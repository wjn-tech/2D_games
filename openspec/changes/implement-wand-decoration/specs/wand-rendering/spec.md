# Spec: Wand Rendering & Handling

## ADDED Requirements

### Requirement: Texture Generation
The system SHALL generate an `ImageTexture` from `WandData.visual_grid` at runtime. Each pixel corresponds to the `wand_visual_color` of the item in that slot. Empty slots are transparent. The texture SHALL use `filter_mode = NEAREST`.

#### Scenario: Equipping Wand
Player equips a wand. The visual system reads the 16x16 dictionary. It creates a 16x16 texture from the data.

### Requirement: Weapon Attachment
The Wand SHALL be anchored at the "Tail Center" to the Player's body center. "Tail Center" is defined as the midpoint of the left-most column of the 16x16 grid (Pixel coordinate 0, 8).

#### Scenario: Visual Attachment
In the Player Scene, the Wand Sprite's origin is aligned such that relative coordinate (0, 8) matches the parent `Marker2D` position.

### Requirement: Weapon Orientation
The Wand SHALL point from the Tail to the Mouse Cursor. The "Head" is the midpoint of the right-most column (Pixel coordinate 16, 8).

#### Scenario: Aiming
Player moves mouse. The Wand rotates around the player's center so that the imaginary line from Tail(0,8) to Head(16,8) points exactly at the mouse cursor.

### Requirement: Projectile Emission
Spells SHALL trigger from the "Head" of the wand (Coordinate 16, 8 rotated into world space).

#### Scenario: Shooting
Player fires a spell. The projectile spawns at `PlayerPos + Vector2(16, 0).rotated(angle)`.
