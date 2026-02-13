# Proposal: Refine NPC Interaction Flow

## Problem Statement
The current NPC interaction is disconnected. While individual modules for Dialogue, Trading, and Quests exist, they are not integrated into the `BaseNPC` lifecycle. Interacting with an NPC currently only stops their movement and doesn't offer meaningful gameplay options based on their role or relationship with the player.

## Proposed Changes
1.  **Unified Interaction Dispatcher**:
    - Update `BaseNPC.interact()` to open the `DialogueWindow` with role-specific options.
    - Options will dynamically include: "Chat", "Trade" (Merchants), "Hire" (Guards), "Services" (Wizards), "Gift", and "Quest" (Quest Givers).
2.  **Role-Specific Integration**:
    - **Merchants**: Connect "Trade" option to `TradeManager.start_session()`.
    - **Guards/Followers**: Implement a hiring mechanism. Once hired, the NPC enters a "Follower" state, following the player and defending them.
    - **Wizards**: Offer "Spell Identification" or "Spell Unlocking" (linked to the new Spell Progression proposal).
3.  **Relationship & Gifting System**:
    - Implement a "Gift" option in the dialogue. Giving items increases `relationship`.
    - High `relationship` reduces prices at Merchants and unlocks rare "Services" or "Quests".
4.  **Dialogue Breadcrumbs**:
    - Implement dynamic dialogue lines that reflect the world state or NPC occupation (e.g., Slime-aware guards).

## Expected Outcome
A rich, systemic interaction layer where every NPC visit feels like a gameplay decision. Players can manage relationships, build a party of followers, and access specialized economic/magical services.
