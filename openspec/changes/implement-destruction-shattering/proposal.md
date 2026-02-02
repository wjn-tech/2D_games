# Proposal: Building Shatter Physics

Convert destroyed buildings into physical RigidBody2D debris to create satisfying high-impact destruction.

## Why
Static building removal is unsatisfying. Physics-based shattering makes combat and environmental destruction feel impactful.

## Proposed Changes
1.  **Debris Scrapper**: Upon building destruction, the system "scrapes" the tile layout.
2.  **Fragment Spawner**: Spawns multiple `RigidBody2D` nodes representing chunks of the building.
3.  **Explosive Force**: Applies outward vectors to fragments.

## Impact
- **Visceral Feel**: Destruction is messy and physical.
- **Environment**: Debris can pile up or be cleared.

## Acceptance Criteria
- [ ] A destroyed house spawns at least 8 physical fragments.
- [ ] Fragments bounce and slide on the ground.
