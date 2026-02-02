# Spec: LimboAI NPC Behaviors

## Overview
This specification defines the required logic blocks to be implemented using the LimboAI plugin.

## ADDED Requirements

### Requirement: Hostile Chase Logic
Values: `Zombie`, `Skeleton`
#### Scenario: Player Detection
*   **GIVEN** a Hostile NPC is in idle mode
*   **WHEN** a Player enters the defined `detection_range`
*   **THEN** the NPC must transition to a `Chase` state and move toward the player until within `attack_range`.

#### Scenario: Line of Sigh Check
*   **GIVEN** a Hostile NPC detects a player
*   **WHEN** a wall blocks the direct path
*   **THEN** the NPC should use pathfinding (NavigationAgent2D) to navigate around, OR give up if path is impossible.

### Requirement: Hostile Jump Attack
Values: `Slime`
#### Scenario: Jump Telegraphed Attack
*   **GIVEN** a Slime has a target
*   **WHEN** it decides to attack
*   **THEN** it must play a "charging" or "squish" animation for 0.5s (telegraph) before applying a physics impulse towards the player.

### Requirement: Friendly Day/Night Cycle
Values: `Merchant`, `Guide`
#### Scenario: Nighttime Retreat
*   **GIVEN** a Friendly NPC
*   **WHEN** the global time switches to Night
*   **THEN** the NPC must navigate to their assigned `home_position` (Housing).

#### Scenario: Fleeing Danger
*   **GIVEN** a Friendly NPC is attacked
*   **WHEN** their health drops below 100%
*   **THEN** they must move *away* from the damage source for a set duration.

## Technical Constraints
*   All tasks must assume 2D side-scrolling physics (`CharacterBody2D`).
*   Tasks must handle `NavigationAgent2D` setup gracefully (check `is_navigation_finished`).
*   Blackboard variables must match the `BaseNPC.gd` synchronization logic.
