# Spec: Player Actions Sound Effects

## Overview
Implement SFX feedback for core player movement and interaction states.

## ADDED Requirements

### 1. Movement-Based Audio Feedback
The `Player` script (`player.gd`) must trigger SFX for jump, landing, and footsteps.
- **Requirement**: `player.gd` must signal or call `AudioManager` when jumping.
- **Requirement**: `player.gd` must signal or call `AudioManager` when landing from a fall.
- **Requirement**: `player.gd` must implement footstep intervals based on animation frames.

#### Scenario: Jumping SFX
- **Given** the player is on solid ground.
- **When** the `jump` action is pressed and the jump logic executes.
- **Then** `AudioManager` must play one out of multiple "JumpRise" sounds.
- **And** the sound must have a slight pitch variation (e.g., +/- 10%).

#### Scenario: Landing SFX
- **Given** the player's `is_on_floor()` state transitions from `false` to `true`.
- **When** falling velocity was greater than a threshold (e.g., 200).
- **Then** `AudioManager` must play a "LandImpact" sound.

#### Scenario: Footsteps SFX
- **Given** the player is in the `Walking` animation state.
- **When** the animation reaches a specific foot-plant frame (or based on distance/time).
- **Then** `AudioManager` must play a "Step" sound.

### 2. Combat Interaction Audio
Feedback for attacking or being attacked.
- **Requirement**: Attacking must trigger a "Swing" or "Attack" sound.
- **Requirement**: Dealing damage must trigger a "HitSuccess" sound.
- **Requirement**: Taking damage must trigger a "PlayerHurt" sound.

#### Scenario: Success Strike
- **Given** the player performs an attack.
- **When** the attack collider overlaps with a destructible or hostile.
- **Then** `AudioManager` must play an "Impact" SFX.
- **And** the hit should be synchronized with the visual flash/particles.
