# Spec Delta: Quest System

## ADDED Requirements

### Requirement: Quest Tracking
The game must track active and completed quests.

#### Scenario: Accepting a Quest
- **Given** an NPC offers a quest.
- **When** the player accepts the quest.
- **Then** the quest must be added to the `QuestManager`'s active list.

### Requirement: Quest Rewards
Completing a quest must grant the player defined rewards.

#### Scenario: Completing a Quest
- **Given** the player has met all objectives of an active quest.
- **When** the player talks to the quest giver.
- **Then** the quest must be marked as completed, and rewards (money/items) must be added to the player's inventory/stats.
