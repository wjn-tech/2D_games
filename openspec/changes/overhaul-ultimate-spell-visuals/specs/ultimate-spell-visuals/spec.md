# Ultimate Spell Visuals

## ADDED Requirements

### Requirement: True Dark Void Rendering for Black Hole
The Black Hole spell MUST visually suck in light and appear as a deep, suffocating void rather than a faint additive color.
#### Scenario: Firing Black Hole on a bright background
When the user fires a Black Hole spell across a brightly lit environment, the center of the spell MUST deduct light from the background using subtractive blending (`BLEND_MODE_SUB`), showing pure darkness. A screen distortion shader MUST bend surrounding pixels.

### Requirement: Procedural Branching Arcs for Spark Bolt
The Spark Bolt MUST feel like raw electricity, not just floating particles.
#### Scenario: Spark Bolt in flight
When a Spark Bolt travels, it MUST procedurally generate harsh, jagged `Line2D` segments that branch and vanish instantly to simulate high-voltage static discharge, surrounded by dense (high particle count) erratic blue/purple sparks.

### Requirement: Continuous Beam Tails for Magic Core Spells
Fast aerodynamic spells (Magic Bolt, Magic Arrow) MUST form unbroken beams of arcane matter.
#### Scenario: Magic Bolt flies at high speed
When Magic Bolt moves, it MUST not leave a "dotted line" of particle points. It MUST leverage Godot 4's `trail_enabled` rendering on `GPUParticles2D` to stretch particles into continuous luminous ribbons that taper off smoothly.

### Requirement: Viscous Opaque Liquids for Slime & Bouncing Burst
Liquid-based physical spells MUST look heavy and wet, avoiding the ghostly transparent look of additive light.
#### Scenario: Slime/Bouncing Burst travel and impact
The projectiles MUST use `BLEND_MODE_MIX` to draw opaque, solid-color green slime drops. Furthermore, collision sub-emitters or heavy particle physics MUST cause "splashes" or secondary droplet clustering upon touching surfaces.

### Requirement: Distinct Projectile Morphologies
Every spell MUST be physically unmistakable on screen at a glance.
#### Scenario: Firing every spell type
The Chainsaw MUST exhibit extreme forward-spray friction; the Black Hole MUST distort space; Fireballs MUST leave towering, expanding smoke trails; Spark Bolt MUST arc jagged lighting.

## MODIFIED Requirements
None against existing OpenSpec capabilities, though it supersedes the basic additive assumptions established in previous PRs.