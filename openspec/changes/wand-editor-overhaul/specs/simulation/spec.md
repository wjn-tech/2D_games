# Spec: Simulation

## ADDED Requirements

### Requirement: In-Editor Preview
Users MUST be able to test spells without closing the editor.

#### Scenario: Run Simulation
- **Given** a valid spell graph in the editor
- **When** the user clicks "Simulate" (or "Test Cast")
- **Then** a preview pane (SubViewport) displays a dummy character casting the spell.
- **And** the projectile behaves exactly as it would in the game world (movement, bounce, modifiers).

#### Scenario: Visual Verification
- **Given** the simulation runs
- **Then** the user SHALL see the "Pure Color" projectiles and elemental effects immediately in the preview window.
