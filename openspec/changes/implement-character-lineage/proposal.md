# Proposal: Character Lineage and Aging

Implement a persistent dynasty system where players age over time and continue their journey through descendants upon natural death.

## Why
To create long-term narrative stakes and a sense of world history. Death by aging prevents a single character from becoming an eternal god-king and encourages management of inheritance.

## Proposed Changes
1.  **WorldTimeManager**: Tracks minutes, days, and years.
2.  **Aging Engine**: Increments player age and triggers death within a threshold (60-80 years).
3.  **Succession UI**: Displays a selection of descendants with inherited traits/stats.

## Impact
- **Narrative**: The player builds a family legacy.
- **Progression**: Certain skills might pass down, while physical stats might reset.

## Acceptance Criteria
- [ ] Time progresses towards a "New Year" signal.
- [ ] Player dies when reaching their randomized lifespan.
- [ ] Succession menu allows choosing a child to restart play.
