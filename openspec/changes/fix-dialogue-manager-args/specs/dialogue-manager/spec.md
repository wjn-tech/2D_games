# Spec Delta: DialogueManager Fix

## MODIFIED Requirements

### Requirement: Dialogue Window Initialization
The `DialogueManager` must correctly initialize the dialogue window using the `UIManager`.

#### Scenario: Starting a Dialogue
- **Given** the `DialogueManager.start_dialogue` is called.
- **When** it calls `UIManager.open_window`.
- **Then** it must provide both the window name "DialogueWindow" and the scene path "res://scenes/ui/DialogueWindow.tscn".
