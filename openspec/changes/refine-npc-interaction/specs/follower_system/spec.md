# Spec: Follower System

## ADDED Requirements

### Req: Hiring Protection
Players can hire certain NPCs to act as bodyguards or followers.

#### Scenario: Hiring a Guard
- **Given** The player has 100 gold.
- **When** The player selects the "Hire" option on a Guard NPC.
- **Then** 100 gold is deducted from the player's inventory.
- **And** The Guard starts following the player.
- **And** the Guard attacks any entity that damages the player.

#### Scenario: Follower Termination
- **Given** An NPC is currently a follower.
- **When** the follower's health reaches 0.
- **Then** the follower relationship is terminated.
- **And** the NPC is removed from the world.
