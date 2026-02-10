# Enhance NPC Interactions

| Field       | Value                    |
| :---------- | :----------------------- |
| **Change**  | enhance-npc-interactions |
| **Status**  | DRAFT                    |
| **Author**  | Copilot                  |
| **Created** | 2026-02-08               |

## Summary

This proposal acts upon the user request to implement a comprehensive "Friendly NPC Interaction System". It focuses on making interactions "natural, self-explanatory, and context-aware" by implementing:
1.  **Visual Cues & Progressive Disclosure**: Multi-layer information display based on proximity (icons, nameplates, detailed tooltips).
2.  **Visual Feedback**: Appearance changes based on relationship/occupation and clear FX for interaction outcomes (hearts, coins, etc.).
3.  **Contextual Interactions**: Smart prompts that change based on context (Trading, Gifting, Questing).
4.  **Enhanced Trading UI**: A shopping-cart style trade interface with clear price/discount breakdowns.
5.  **Accessibility**: Options for visual aids and text settings.

## Motivation

Current NPC interactions are basic and opaque. Players must guess what an NPC offers or how they feel. The proposed system aims to significantly reduce cognitive load and frustration by adhering to the "What You See Is What You Get" and "Distance = Information" philosophies. This aligns with the long-term goal of an immersive "Living World".


## Proposed Changes

### Capabilities

#### 1. Visual Conveyance System
- **Layered Cues**: Implement distance-based LOD for NPC info (Name only -> Status Icon -> Interaction Prompt -> Full Info).
- **Minimalist Appearance**: Extend `MinimalistEntity` to support "accessories/badges" (e.g., a merchant's bag, a blacksmith's apron overlay) and "mood/relationship rings".
- **Interaction Prompts**: Context-aware key hints floating above NPCs.

#### 2. Interaction & Feedback Loop
- **Contextual Prompts**: An expandable prompt system showing Primary (E) and Secondary (F, G, etc.) actions.
- **Immediate Feedback**: On-screen effects for relationship changes (hearts/skulls), trading success (coins flying), and quests.
- **Speech Bubbles**: Dynamic "barking" or preview text above heads based on relationship/time.

#### 3. Enhanced Trading System
- **Cart-based UI**: A dedicated UI for selecting multiple items, seeing discounts applied, and selling player items.
- **Dynamic Pricing**: Discounts based on Affinity/Festivals.

#### 4. Progressive Information
- **Info Layers**: Reveal checking logic in `SocialManager` or `NPCInteractionSystem` to determine what data to send to the UI based on distance.

## Validation Strategy
- **Manual Testing**: Walk towards NPCs and verify cues appear in correct proximity order.
- **Scenario Verification**:
    - Trade with a merchant (verify discounts).
    - Gift an item (verify heart FX).
    - Ignore an NPC for a week (verify "Long time no see" bark).
