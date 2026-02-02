# Spec Delta: NPC Interaction Fix

## REMOVED Requirements

### Requirement: Redundant Interaction Placeholder
The redundant placeholder `interact()` function in `BaseNPC` is removed to avoid naming conflicts.

#### Scenario: Script Compilation
- **Given** the `BaseNPC` script is being compiled.
- **When** it contains only one `interact()` function.
- **Then** it must compile without "duplicate function" errors.
