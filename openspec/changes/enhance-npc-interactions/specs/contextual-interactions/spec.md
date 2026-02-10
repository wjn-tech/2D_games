# Contextual Interaction Rules

## System Overview
The Contextual Interaction System determines which prompt and action is available to the player based on the NPC's state, data, and relation to the player.

## ADDED Rules

#### Rule: Priority of Actions
When determining the primary action (Key: 'E'), fallback order is:
1. **Hostile/Combat**: If `alignment == "Hostile"`, Primary Action is `Attack` (or none if auto-aggro).
2. **Quest**: If NPC has `quest_state == "ready_to_turn_in"`, Primary Action is `Complete Quest`. (Label: "Complete Quest")
3. **Quest**: If NPC has `quest_state == "available"`, Primary Action is `Accept Quest`. (Label: "Accept Quest")
4. **Role-Specific**:
   - `Merchant`: Primary Action is `Trade`. (Label: "Trade")
   - `Blacksmith`: Primary Action is `Forge`. (Label: "Forge")
   - `Healer`: Primary Action is `Heal`. (Label: "Heal")
5. **Default**: Primary Action is `Talk`. (Label: "Talk")

#### Rule: Secondary Actions
Secondary Actions (Key: 'F' or 'Q', configurable) are optional.
- If Primary is `Trade`, Secondary defaults to `Talk`.
- If Primary is `Quest`, Secondary defaults to `Talk`.

#### Rule: Relationship Gating
Given a `Merchant` NPC
When `relationship < 0` (Hostile/Disliked)
Then `Trade` action is disabled or replaced with `Talk` (scornful).

#### Rule: Time Gating
Given a `Shopkeeper`
When `world_time` is `Night` (sleeping hours)
Then `Trade` action is replaced with `Wake Up` (Annoy) or disabled.

## Data Structures

### InteractionAction
```gdscript
class InteractionAction:
    var label: String # "Trade", "Talk"
    var input_key: String # "interact", "secondary_interact"
    var method_name: String # "start_trade", "start_dialogue"
    var icon_hint: Texture # Optional key icon or action icon
```
