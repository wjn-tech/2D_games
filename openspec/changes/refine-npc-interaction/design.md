# Design: Refine NPC Interaction

## Architecture

### 1. The Interaction Flow
1. **Trigger**: Player presses 'F' (using the new execution/interact key) near NPC.
2. **Context Check**: `BaseNPC.gd` gathers available options:
    - Default: "Chat" (Flavor text), "Gift" (Relationship), "Goodbye".
    - Role-specific: "Trade" (if merchant), "Hire" (if guard), "Request Spell" (if wizard).
3. **UI Dispatch**: Calls `DialogueManager.start_dialogue()` with these options.

### 2. Follower System (`follower_component.gd`)
A new component for `BaseNPC` that handles:
- **Following**: Uses `nav_agent` to stay within a buffer zone of the player.
- **Aggro Sharing**: If the player attacks or is attacked, the follower targets that enemy.
- **Contract Management**: Expiry after time or death.

### 3. Trading & Relationship
- **Discount Logic**: Store prices as `base_price * relation_modifier(relationship)`.
- **Gifting**: An item-selection UI (dialogue option) that checks the item's `value` and increases `relationship`.

### 4. Quest & Service Integration
- If `quest_template` is present, `BaseNPC` adds a "Quest" option to the dialogue.
- Selecting it opens the `QuestWindow` (to be implemented or integrated).

### 5. Dialogue Data Struct
```gdscript
var dialogue_tables = {
    "Guard": {
        "greeting": ["Stay safe, adventurer.", "I'm watching for slimes."],
        "hire_success": ["Reporting for duty!", "Lead the way."]
    },
    ...
}
```
This table will be queried in `BaseNPC._handle_neutral_interaction`.
