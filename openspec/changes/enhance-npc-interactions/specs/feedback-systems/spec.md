# Contextual Interaction & Feedback Systems

## ADDED Requirements

#### Scenario: Context-Sensitive Action Prompt
Given the player is looking at an NPC
When the NPC is a Merchant
And the player is in Interaction Range
Then the prompt should display "E to Trade"
Given the NPC is a regular Villager
Then the prompt should display "E to Chat"
Given the NPC is Hostile
Then the prompt should display "E to Attack" (or no prompt if auto-aggro)

#### Scenario: Interaction Feedback - Shake
Given the player attempts an invalid interaction (e.g. trading with no money)
Then the UI panel or prompt itself should perform a quick "Shake" animation
And a sound effect "ui_error" should play

#### Scenario: Interaction Feedback - Particle Burst
Given a successful transaction or relationship upgrade
Then a small particle burst should emit from the UI element
And a sound effect "ui_success" should play

#### Scenario: Floating Feedback Text
Given a relationship change (gain/loss)
Or a money transaction (gain/loss)
Then a floating label should appear above the player or NPC
And it should drift upwards and fade out
- Format: "+10 Relationship" (Green), "-500 Gold" (Yellow)

## Architecture

### FeedbackManager (Autoload)
- `play_shake(node: Control)`
- `spawn_floating_text(position: Vector2, text: String, color: Color)`
- `spawn_particles(position: Vector2, type: String)`

